// Tests for post-splash session restoration.
//
// Before this, the splash always routed to Login after a fixed delay, so a
// signed-in user was silently logged out on every cold start. These tests pin
// the corrected behaviour: the destination comes from the session, not a timer.
//
// Fully offline — no Supabase client is constructed. Sessions are built by hand
// so expiry can be controlled exactly.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kidz_store/session_routing.dart';
import 'support/auth_fakes.dart';

/// Builds an unsigned JWT carrying only `exp`.
///
/// `Session.isExpired` reads the `exp` claim out of the access token, so this
/// is enough to drive the expiry logic without any network or crypto.
String _tokenExpiringAt(DateTime expiry) {
  String segment(Map<String, dynamic> claims) =>
      base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');

  final String header = segment(<String, dynamic>{'alg': 'none', 'typ': 'JWT'});
  final String payload = segment(<String, dynamic>{
    'exp': expiry.millisecondsSinceEpoch ~/ 1000,
  });
  return '$header.$payload.';
}

Session _sessionExpiringAt(DateTime expiry) {
  return Session(
    accessToken: _tokenExpiringAt(expiry),
    tokenType: 'bearer',
    refreshToken: 'synthetic-refresh-token',
    user: User(
      id: '00000000-0000-4000-8000-000000000001',
      appMetadata: const <String, dynamic>{},
      userMetadata: const <String, dynamic>{},
      aud: 'authenticated',
      email: 'kidz.demo.session@kidz-demo.com',
      createdAt: DateTime.utc(2026, 1, 1).toIso8601String(),
    ),
  );
}

void main() {
  group('startupDestinationFor', () {
    test('restored Admin needs server verification before privileged routing',
        () {
      final admin = storeUser(role: 'admin');
      final session = storeSession(admin);
      expect(startupDestinationFor(session), StartupDestination.login);
      expect(startupDestinationFor(session, verifiedUser: admin),
          StartupDestination.admin);
      expect(startupDestinationFor(session, verifiedUser: storeUser()),
          StartupDestination.home);
    });

    test('server-verified identity must match the restored session', () {
      expect(
          startupDestinationFor(storeSession(storeUser()),
              verifiedUser: storeUser(id: 'different-user', role: 'admin')),
          StartupDestination.login);
    });

    test('user metadata cannot change Buyer or Seller startup routing', () {
      final user = storeUser(userRole: 'admin');
      expect(startupDestinationFor(storeSession(user), verifiedUser: user),
          StartupDestination.home);
    });
    test('no session goes to login', () {
      expect(startupDestinationFor(null), StartupDestination.login);
    });

    test('a valid session goes to the authenticated home', () {
      final Session session =
          _sessionExpiringAt(DateTime.now().add(const Duration(hours: 1)));

      expect(session.isExpired, isFalse, reason: 'fixture must not be expired');
      expect(startupDestinationFor(session), StartupDestination.home);
    });

    test('an expired session goes to login, not a dead home screen', () {
      final Session session =
          _sessionExpiringAt(DateTime.now().subtract(const Duration(hours: 1)));

      expect(session.isExpired, isTrue, reason: 'fixture must be expired');
      expect(startupDestinationFor(session), StartupDestination.login);
    });

    test('a session expiring within the refresh margin goes to login', () {
      // gotrue treats anything inside a short margin as already expired.
      final Session session =
          _sessionExpiringAt(DateTime.now().add(const Duration(seconds: 1)));

      expect(startupDestinationFor(session), StartupDestination.login);
    });

    test('signing out clears the session, so startup returns to login', () {
      // signOut() leaves currentSession == null; that null is what the splash
      // reads on the next launch. Asserting the contract, not the SDK call.
      const Session? afterSignOut = null;

      expect(startupDestinationFor(afterSignOut), StartupDestination.login);
    });

    test('the decision is driven by the session, never by elapsed time', () {
      final Session valid =
          _sessionExpiringAt(DateTime.now().add(const Duration(days: 7)));

      // Repeated calls must agree — no timer, no ordering dependence.
      for (int i = 0; i < 3; i++) {
        expect(startupDestinationFor(valid), StartupDestination.home);
        expect(startupDestinationFor(null), StartupDestination.login);
      }
    });
  });
}
