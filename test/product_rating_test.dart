// Regression tests for the product star rating.
//
// `products.rating` is a numeric column, so PostgREST sends `3.0`, not `3`.
// The old code called `.clamp()` on the dynamic map value and assigned the
// resulting double to an `int`, which threw
// "type 'double' is not a subtype of type 'int'" at runtime — every product
// card on the Android home screen rendered as a red error box.

import 'package:flutter_test/flutter_test.dart';

import 'package:kidz_store/product_rating.dart';

void main() {
  group('productStarCount', () {
    test('accepts the double a numeric column actually returns', () {
      // The exact value that crashed the Android home screen.
      expect(productStarCount(3.0), 3);
      expect(productStarCount(4.0), 4);
    });

    test('accepts plain ints', () {
      expect(productStarCount(1), 1);
      expect(productStarCount(5), 5);
    });

    test('rounds fractional ratings to the nearest star', () {
      expect(productStarCount(4.4), 4);
      expect(productStarCount(4.5), 5);
      expect(productStarCount(3.7), 4);
    });

    test('clamps out-of-range values into 1..5', () {
      expect(productStarCount(0), 1);
      expect(productStarCount(-2.5), 1);
      expect(productStarCount(9.9), 5);
    });

    test('falls back to 3 for null and unusable values', () {
      expect(productStarCount(null), 3);
      expect(productStarCount('not a number'), 3);
      expect(productStarCount(<String>[]), 3);
      expect(productStarCount(double.nan), 3);
    });

    test('parses a numeric string', () {
      expect(productStarCount('4'), 4);
      expect(productStarCount('4.6'), 5);
    });

    test('always returns an int, never a double', () {
      for (final Object? input in <Object?>[3.0, 4.5, 1, null, '2']) {
        // ignore: unnecessary_type_check
        expect(productStarCount(input), isA<int>(),
            reason: 'a double here is exactly what crashed the card');
      }
    });
  });
}
