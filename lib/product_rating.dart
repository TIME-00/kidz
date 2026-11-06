/// Number of filled stars to draw for a product rating.
///
/// `products.rating` is a `numeric` column, so PostgREST delivers it as a
/// double (`3.0`) even when the value looks like a whole number. The star row
/// needs an `int`, and calling `.clamp()` directly on the dynamic map value
/// returned a double — which threw
/// `type 'double' is not a subtype of type 'int'` and replaced every product
/// card with a red error box on Android.
///
/// Accepts anything the backend might realistically send — int, double, a
/// numeric string, null — and always returns a value in 1..5.
int productStarCount(Object? rating) {
  final num value = switch (rating) {
    final num n => n,
    final String s => num.tryParse(s) ?? 3,
    _ => 3,
  };
  if (value.isNaN) return 3;
  return value.round().clamp(1, 5).toInt();
}
