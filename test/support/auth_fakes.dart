import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User storeUser(
        {String id = '10000000-0000-4000-8000-000000000001',
        Object? role,
        Object? userRole,
        bool confirmed = true}) =>
    User(
      id: id,
      aud: 'authenticated',
      email: 'synthetic@example.test',
      createdAt: '2026-01-01T00:00:00Z',
      emailConfirmedAt: confirmed ? '2026-01-01T00:00:00Z' : null,
      appMetadata: {if (role != null) 'role': role},
      userMetadata: {if (userRole != null) 'role': userRole},
    );

Session storeSession(User user,
    {Duration lifetime = const Duration(hours: 1)}) {
  String part(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return Session(
    accessToken: '${part({'alg': 'none'})}.${part({
          'sub': user.id,
          'exp': DateTime.now().add(lifetime).millisecondsSinceEpoch ~/ 1000,
          'app_metadata': user.appMetadata,
        })}.',
    tokenType: 'bearer',
    user: user,
  );
}

/// No real SDK client or socket is constructed. Unimplemented calls fail tests.
class StoreAuthFake extends Fake implements GoTrueClient {
  Session? activeSession;
  User? verifiedUser;
  Object? verifyError;
  Object? loginError;
  Future<UserResponse> Function()? onVerify;
  int verifyCalls = 0;
  String? submittedEmail;
  String? submittedPassword;
  final events = StreamController<AuthState>.broadcast(sync: true);

  @override
  Session? get currentSession => activeSession;
  @override
  Stream<AuthState> get onAuthStateChange => events.stream;
  @override
  Future<UserResponse> getUser([String? jwt]) async {
    verifyCalls++;
    if (verifyError != null) throw verifyError!;
    if (onVerify != null) return onVerify!();
    return UserResponse.fromJson(verifiedUser?.toJson() ?? {});
  }

  @override
  Future<AuthResponse> signInWithPassword(
      {String? email,
      String? phone,
      required String password,
      String? captchaToken}) async {
    submittedEmail = email;
    submittedPassword = password;
    if (loginError != null) throw loginError!;
    return AuthResponse(user: verifiedUser, session: activeSession);
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    activeSession = null;
    events.add(AuthState(AuthChangeEvent.signedOut, null));
  }
}

class StoreClientFake extends Fake implements SupabaseClient {
  StoreClientFake(this.auth);
  @override
  final StoreAuthFake auth;
  final rows = <String, List<Map<String, dynamic>>>{};
  final counts = <String, int>{};
  final reads = <String>[];
  final rpcCalls = <Map<String, dynamic>>[];
  FutureOr<Map<String, dynamic>> Function(String, Map<String, dynamic>)? onRpc;
  bool failReads = false;

  @override
  SupabaseQueryBuilder from(String table) => _Query(this, table);

  @override
  PostgrestFilterBuilder<T> rpc<T>(String fn,
      {Map<String, dynamic>? params, get = false}) {
    final values = params ?? <String, dynamic>{};
    rpcCalls.add({'name': fn, 'params': values});
    return _Result(() async => (await onRpc!(fn, values)) as T);
  }
}

class _Query extends Fake implements SupabaseQueryBuilder {
  _Query(this.client, this.table);
  final StoreClientFake client;
  final String table;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    client.reads.add('$table:select');
    return _Result(() {
      if (client.failReads) throw const PostgrestException(message: 'denied');
      return client.rows[table] ?? [];
    });
  }

  @override
  PostgrestFilterBuilder<int> count([CountOption option = CountOption.exact]) {
    client.reads.add('$table:count');
    return _Result(() {
      if (client.failReads) throw const PostgrestException(message: 'denied');
      return client.counts[table] ?? 0;
    });
  }
}

class _Result<T> extends Fake implements PostgrestFilterBuilder<T> {
  _Result(this.value);
  final FutureOr<T> Function() value;
  @override
  PostgrestTransformBuilder<T> order(String column,
          {bool ascending = false,
          bool nullsFirst = false,
          String? referencedTable}) =>
      this;

  @override
  PostgrestTransformBuilder<T> range(int from, int to,
          {String? referencedTable}) =>
      _Result(() async {
        final items = await value() as List;
        return items
            .skip(from)
            .take(to - from + 1)
            .toList()
            .cast<Map<String, dynamic>>() as T;
      });
  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) =>
      Future<T>.sync(value).then(onValue, onError: onError);
}
