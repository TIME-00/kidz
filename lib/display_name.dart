/// Fallback shown when a profile has no usable name.
const String kFallbackDisplayName = 'User';

/// Builds a person's display name from the raw profile fields.
///
/// `users.first_name` and `users.last_name` are nullable, and accounts created
/// outside the signup form have neither. Interpolating them straight into a
/// string rendered the literal text "null null" on the profile screen, so both
/// parts are validated before use and a neutral [kFallbackDisplayName] is
/// returned when nothing usable remains.
String displayName(Object? firstName, Object? lastName) {
  final String first = _clean(firstName);
  final String last = _clean(lastName);

  final String full = <String>[
    if (first.isNotEmpty) first,
    if (last.isNotEmpty) last,
  ].join(' ');

  return full.isEmpty ? kFallbackDisplayName : full;
}

/// Normalises one name part: anything that is not real text becomes empty.
///
/// Guards against the literal strings "null"/"undefined" too, which is what a
/// backend or an earlier interpolation bug can leave behind in the column.
String _clean(Object? value) {
  if (value is! String) return '';
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final String lowered = trimmed.toLowerCase();
  if (lowered == 'null' || lowered == 'undefined') return '';
  return trimmed;
}
