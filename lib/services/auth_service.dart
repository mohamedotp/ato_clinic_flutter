import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Profile?> getProfile(String id) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle(); // Better than .single() to avoid exception if missing
      return data != null ? Profile.fromJson(data) : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isClinicActive(String clinicId) async {
    try {
      final data = await _client
          .from('clinics')
          .select('is_active')
          .eq('id', clinicId)
          .single();
      return data['is_active'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateProfile(String id, Map<String, dynamic> updates) async {
    await _client.from('profiles').update(updates).eq('id', id);
  }
}
