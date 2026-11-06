import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_access.dart';

enum StartupDestination { home, admin, login }

/// Cached metadata alone must never grant entry to an Admin screen.
StartupDestination startupDestinationFor(Session? session,
    {User? verifiedUser}) {
  if (session == null || session.expiresAt == null || session.isExpired) {
    return StartupDestination.login;
  }
  if (verifiedUser != null && verifiedUser.id != session.user.id) {
    return StartupDestination.login;
  }
  if (hasAdminRole(verifiedUser)) return StartupDestination.admin;
  if (verifiedUser == null && hasAdminRole(session.user)) {
    return StartupDestination.login;
  }
  // Buyers and sellers retain their shared home and profile-based seller entry.
  return StartupDestination.home;
}

Future<StartupDestination> verifiedDestinationFor(AdminAccess access) async {
  final session = access.session;
  // Preserve existing Buyer/Seller restoration, including offline entry to
  // HomePage. Only an Admin candidate needs the extra server verification.
  if (!hasAdminRole(session?.user)) return startupDestinationFor(session);
  try {
    final user = await access.verifyCurrentUser();
    if (user == null || user.emailConfirmedAt == null) {
      return StartupDestination.login;
    }
    return startupDestinationFor(access.session, verifiedUser: user);
  } catch (_) {
    return StartupDestination.login;
  }
}
