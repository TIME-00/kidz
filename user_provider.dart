import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData => _userData;

  Future<void> fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('users')
        .select('first_name, last_name, email, mobile_number, gender')
        .eq('id', user.id)
        .maybeSingle();

    if (response != null) {
      _userData = response;
      notifyListeners(); // ✅ Notify the app of the change
    }
  }

  Future<void> updateUserData(Map<String, dynamic> updatedData) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('users').update(updatedData).eq('id', user.id);

    await fetchUserData(); // ✅ Fetch latest data after update
  }
}