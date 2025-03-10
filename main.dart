import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kidz/login.dart'; 
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Import Supabase SDK

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Ensure Flutter is initialized

  // ✅ Initialize Supabase with API credentials
  await Supabase.initialize(
    url: "https://jdgxbtkdoaizowhnwxkl.supabase.co", // Replace with your Supabase URL
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpkZ3hidGtkb2Fpem93aG53eGtsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk3OTQ5NjgsImV4cCI6MjA1NTM3MDk2OH0.0yCPmja-YjkrDX89vLQhXtxJ38X9AYw6HVFoqVK3YqY" // Replace with your Supabase API Key
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider()..fetchUserData(),
      child: const MyApp(),
    ),
  );
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
  final SupabaseClient supabase = Supabase.instance.client; // ✅ Get Supabase Client

  @override
  void initState() {
    super.initState();
    _checkDatabaseConnection(); // ✅ Check DB before navigating
  }

  Future<void> _checkDatabaseConnection() async {
    try {
      final response = await supabase.from('products').select().limit(1); // ✅ Change to an existing table
      if (response.isNotEmpty) {
        print("✅ Connected to Supabase!");
      } else {
        print("⚠️ No data found in products table.");
      }
    } catch (e) {
      print("❌ Failed to connect to Supabase: $e");
    }

    // ✅ Navigate to Login Page after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
      );
    });
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