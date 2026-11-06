import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kidz_store/login.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Import Supabase SDK
import 'home.dart';
import 'session_routing.dart';
import 'admin_access.dart';
import 'admin_dashboard.dart';
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Ensure Flutter is initialized

  // Connection settings come from --dart-define so no credential is committed.
  // Fail loudly and immediately rather than letting every screen die with an
  // opaque network error.
  if (!SupabaseConfig.isConfigured) {
    runApp(const MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.publishableKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider()..fetchUserData(),
      child: const MyApp(),
    ),
  );
}

/// Shown instead of the app when the build-time Supabase settings are absent.
///
/// Names the missing --dart-define keys; never displays a value.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF3E0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings_outlined,
                    size: 56, color: Color(0xFFFF7B00)),
                const SizedBox(height: 16),
                const Text(
                  "Configuration required",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  SupabaseConfig.missingConfigMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// ✅ Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SupabaseClient supabase =
      Supabase.instance.client; // ✅ Get Supabase Client

  @override
  void initState() {
    super.initState();
    _checkDatabaseConnection(); // ✅ Connectivity diagnostic only
    _routeFromSession();
  }

  /// Diagnostic only — deliberately does NOT gate navigation, so a slow or
  /// unreachable backend can never strand the user on the splash screen.
  Future<void> _checkDatabaseConnection() async {
    try {
      final response = await supabase
          .from('products')
          .select()
          .limit(1); // ✅ Change to an existing table
      if (response.isNotEmpty) {
        print("✅ Connected to Supabase!");
      } else {
        print("⚠️ No data found in products table.");
      }
    } catch (e) {
      print("❌ Failed to connect to Supabase: $e");
    }
  }

  /// Restores the signed-in user instead of always dropping them at login.
  ///
  /// `Supabase.initialize` has already rehydrated any persisted session by the
  /// time this runs, so the destination is decided by the session itself. The
  /// short delay only holds the splash artwork long enough to be seen — it is
  /// not what decides the route.
  Future<void> _routeFromSession() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final StartupDestination destination =
        await verifiedDestinationFor(AdminAccess(supabase));

    // The splash can be popped or replaced while the delay is pending; without
    // this guard we would navigate with a dead BuildContext.
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => switch (destination) {
          StartupDestination.home => const HomePage(),
          StartupDestination.admin => const AdminDashboard(),
          StartupDestination.login => const LoginRegisterScreen(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.asset(
          "assets/img/splashscreen.png", // ✅ Replace with actual splash image path
          fit: BoxFit.cover, // ✅ Ensures full-screen coverage
        ),
      ),
    );
  }
}
