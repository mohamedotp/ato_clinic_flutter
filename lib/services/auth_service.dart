import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../core/services/local_storage_service.dart';

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
          
      if (data != null) {
        await LocalStorageService.saveProfile(data);
        _lastProfileFromCache = false;
        return Profile.fromJson(data);
      }
      return null;
    } catch (e) {
      final cachedProfile = LocalStorageService.getProfile();
      if (cachedProfile != null && cachedProfile['id'] == id) {
        _lastProfileFromCache = true;
        return Profile.fromJson(cachedProfile);
      }
      return null;
    }
  }

  bool _lastProfileFromCache = false;

  /// Returns true if the last getProfile call used the cache (offline)
  bool isProfileFromCache(String id) => _lastProfileFromCache;

  /// Returns a Profile object from cache for a given user ID
  Profile? getCachedProfileForUser(String id) {
    final cachedProfile = LocalStorageService.getProfile();
    if (cachedProfile != null && cachedProfile['id'] == id) {
      return Profile.fromJson(cachedProfile);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getClinicStatus(String clinicId) async {
    try {
      final data = await _client
          .from('clinics')
          .select('is_active, subscription_ends_at')
          .eq('id', clinicId)
          .single();
      await LocalStorageService.saveClinicStatus(data);
      return data;
    } catch (e) {
      return LocalStorageService.getClinicStatus();
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
