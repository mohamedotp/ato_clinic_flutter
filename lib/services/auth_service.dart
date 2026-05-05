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

  Future<Map<String, dynamic>?> getClinicStatus(String clinicId) async {
    try {
      final data = await _client
          .from('clinics')
          .select('is_active, subscription_ends_at')
          .eq('id', clinicId)
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isClinicActive(String clinicId) async {
    final status = await getClinicStatus(clinicId);
    if (status == null) return false;
    
    final bool isActive = status['is_active'] ?? false;
    final String? subEndsAtStr = status['subscription_ends_at'];
    
    if (!isActive) return false;
    
    if (subEndsAtStr != null) {
      final subEndsAt = DateTime.parse(subEndsAtStr);
      if (subEndsAt.isBefore(DateTime.now())) {
        return false;
      }
    }
    
    return true;
  }

  Future<void> updateProfile(String id, Map<String, dynamic> updates) async {
    await _client.from('profiles').update(updates).eq('id', id);
  }
}
