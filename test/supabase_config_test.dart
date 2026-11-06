// Tests for the build-time Supabase configuration gate.
//
// These run without any --dart-define, which is exactly the "misconfigured"
// case: String.fromEnvironment returns '' for both keys. That keeps the suite
// deterministic and means no credential is ever needed to run the tests.

import 'package:flutter_test/flutter_test.dart';

import 'package:kidz_store/main.dart';
import 'package:kidz_store/supabase_config.dart';

void main() {
  group('SupabaseConfig without --dart-define', () {
    test('reports itself as not configured', () {
      expect(SupabaseConfig.isConfigured, isFalse);
    });

    test('names both missing keys', () {
      expect(
        SupabaseConfig.missingKeys,
        containsAll(<String>['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY']),
      );
    });

    test('the developer message names the keys but leaks no value', () {
      final String message = SupabaseConfig.missingConfigMessage;

      expect(message, contains('SUPABASE_URL'));
      expect(message, contains('SUPABASE_PUBLISHABLE_KEY'));
      expect(message, contains('--dart-define'));

      // Placeholders only — a real ref or key must never be baked in here.
      expect(message, contains('YOUR_PROJECT_REF'));
      expect(message, isNot(contains('.supabase.co/rest')));
      expect(message, isNot(contains('sb_publishable_ey')));
    });

    test('no real credential is compiled into the defaults', () {
      // Absent a --dart-define both must be empty, never a committed fallback.
      expect(SupabaseConfig.url, isEmpty);
      expect(SupabaseConfig.publishableKey, isEmpty);
    });
  });

  testWidgets('MissingConfigApp renders the developer-facing error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MissingConfigApp());
    await tester.pumpAndSettle();

    expect(find.text('Configuration required'), findsOneWidget);
    expect(
      find.textContaining('SUPABASE_URL'),
      findsOneWidget,
      reason: 'the screen must say which key is missing',
    );
  });
}
