import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Only Auth's server-controlled application metadata grants Admin access.
bool hasAdminRole(User? user) => user?.appMetadata['role'] == 'admin';

/// The Auth boundary. Database authorization is independently enforced by RLS.
class AdminAccess {
  AdminAccess(this.client);
  final SupabaseClient client;
  Session? get session => client.auth.currentSession;
  Stream<void> get changes => client.auth.onAuthStateChange.map((_) {});

  Future<User?> verifyCurrentUser() async {
    final before = session;
    if (before == null || before.expiresAt == null || before.isExpired) {
      return null;
    }
    final user = (await client.auth
            .getUser(before.accessToken)
            .timeout(const Duration(seconds: 15)))
        .user;
    final after = session;
    // Never authorize a different session using an earlier request's response.
    if (user == null ||
        after == null ||
        after.isExpired ||
        after.accessToken != before.accessToken ||
        user.id != after.user.id) {
      return null;
    }
    return user;
  }

  Future<bool> verifyAdmin() async {
    final user = await verifyCurrentUser();
    return hasAdminRole(user) && user?.emailConfirmedAt != null;
  }

  Future<void> signIn({required String email, required String password}) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => client.auth.signOut();
}

/// The protected subtree is built only after server verification. All public
/// Admin screens use this gate, including directly navigated screens.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key, this.access, required this.builder});
  final AdminAccess? access;
  final Widget Function(AdminAccess access) builder;
  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> with WidgetsBindingObserver {
  late AdminAccess _access;
  StreamSubscription<void>? _subscription;
  Timer? _expiry;
  int _generation = 0;
  bool _checking = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bind();
  }

  void _bind() {
    _access = widget.access ?? AdminAccess(Supabase.instance.client);
    _subscription =
        _access.changes.listen((_) => _check(), onError: (_) => _deny());
    _check();
  }

  @override
  void didUpdateWidget(AdminGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.access != widget.access) {
      _subscription?.cancel();
      _bind();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  void _deny() {
    _generation++;
    _expiry?.cancel();
    if (mounted) {
      setState(() {
        _checking = false;
        _allowed = false;
      });
    }
  }

  Future<void> _check() async {
    final generation = ++_generation;
    _expiry?.cancel();
    if (!mounted) return;
    setState(() {
      _checking = true;
      _allowed = false;
    });
    bool allowed;
    try {
      // Leave the Auth callback before calling another Auth operation.
      allowed = await Future<bool>.microtask(_access.verifyAdmin);
    } catch (_) {
      allowed = false;
    }
    if (!mounted || generation != _generation) return;
    final current = _access.session;
    allowed = allowed && current != null && !current.isExpired;
    setState(() {
      _checking = false;
      _allowed = allowed;
    });
    final expiresAt = current?.expiresAt;
    if (allowed && expiresAt != null) {
      final remaining = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
          .difference(DateTime.now());
      _expiry = Timer(remaining.isNegative ? Duration.zero : remaining, _deny);
    }
  }

  @override
  void dispose() {
    _generation++;
    _expiry?.cancel();
    _subscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_allowed) return widget.builder(_access);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin access')),
      body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Admin access could not be verified.'),
        const Text('Sign in with an Admin account or try again.'),
        TextButton(onPressed: _check, child: const Text('Try again')),
      ])),
    );
  }
}

/// Distinguishes empty results from pending or failed reads.
class AdminReadState extends StatelessWidget {
  const AdminReadState(
      {super.key,
      required this.loading,
      required this.failed,
      required this.empty,
      required this.onRetry,
      required this.child});
  final bool loading;
  final bool failed;
  final bool empty;
  final VoidCallback onRetry;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (failed) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Unable to load Admin data.'),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ]));
    }
    if (empty) return const Center(child: Text('No records found.'));
    return child;
  }
}
