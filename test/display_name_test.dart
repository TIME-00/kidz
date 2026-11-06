// Tests for the profile display name.
//
// Accounts created outside the signup form have no first/last name, and the
// old code interpolated the nullable columns straight into a string — the
// profile screen showed the literal text "null null".

import 'package:flutter_test/flutter_test.dart';

import 'package:kidz_store/display_name.dart';

void main() {
  group('displayName', () {
    test('joins a full name', () {
      expect(displayName('Kidz', 'AndroidBuyer'), 'Kidz AndroidBuyer');
    });

    test('uses whichever part is present', () {
      expect(displayName('Kidz', null), 'Kidz');
      expect(displayName(null, 'AndroidBuyer'), 'AndroidBuyer');
    });

    test('falls back to a neutral name when both are missing', () {
      expect(displayName(null, null), kFallbackDisplayName);
      expect(kFallbackDisplayName, 'User');
    });

    test('never renders the literal "null null"', () {
      // The exact regression: nulls, and the string "null" already persisted
      // into the column by the earlier interpolation bug.
      expect(displayName(null, null), isNot(contains('null')));
      expect(displayName('null', 'null'), kFallbackDisplayName);
      expect(displayName('NULL', null), kFallbackDisplayName);
    });

    test('treats empty and whitespace-only values as missing', () {
      expect(displayName('', ''), kFallbackDisplayName);
      expect(displayName('   ', '\t'), kFallbackDisplayName);
      expect(displayName('  Kidz  ', '   '), 'Kidz');
    });

    test('ignores non-string values', () {
      expect(displayName(42, <String>[]), kFallbackDisplayName);
    });

    test('trims each part and uses a single separating space', () {
      expect(displayName('  Kidz ', ' AndroidBuyer  '), 'Kidz AndroidBuyer');
    });
  });
}
