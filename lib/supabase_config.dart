/// Supabase connection settings, supplied at build time.
///
/// Nothing here is a secret in the sense of a server key: the publishable key
/// is meant to reach the client, and the database is protected by Row Level
/// Security, not by hiding this value. It is still kept out of the repository
/// so the project can be re-pointed without editing Dart, and so no credential
/// is ever committed.
///
/// Pass both values with --dart-define:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
///
/// A service_role or secret key must never be passed to this application.
library;

class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');

  static const String publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Whether both values were supplied at build time.
  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  /// The names that were left empty, for a developer-facing error message.
  static List<String> get missingKeys => <String>[
        if (url.isEmpty) 'SUPABASE_URL',
        if (publishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
      ];

  /// Explains what is missing and how to supply it. Names only — never values.
  static String get missingConfigMessage =>
      'Supabase is not configured. Missing --dart-define: '
      '${missingKeys.join(', ')}.\n'
      'Run with:\n'
      '  flutter run \\\n'
      '    --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \\\n'
      '    --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY';
}
