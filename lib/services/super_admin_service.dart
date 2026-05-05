import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic.dart';
import '../models/profile.dart';

final superAdminServiceProvider = Provider((ref) => SuperAdminService());

final allClinicsProvider = FutureProvider<List<Clinic>>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.getAllClinics();
});

final allAdminsProvider = FutureProvider<List<Profile>>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.getAllSystemAdmins();
});

final allStoresProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.getAllStores();
});

final allTicketsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.getAllSupportTickets();
});

final smartServicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.getSmartServices();
});

final globalSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.getGlobalSettings();
});

class SuperAdminService {
  final _supabase = Supabase.instance.client;

  // --- Clinics ---
  Future<List<Clinic>> getAllClinics() async {
    final response = await _supabase
        .from('clinics')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Clinic.fromJson(json)).toList();
  }

  Future<void> createClinic(Map<String, dynamic> data) async {
    await _supabase.from('clinics').insert(data);
  }

  Future<void> updateClinic(String id, Map<String, dynamic> data) async {
    await _supabase.from('clinics').update(data).eq('id', id);
  }

  Future<void> deleteClinic(String id) async {
    await _supabase.from('clinics').delete().eq('id', id);
  }

  // --- System Admins ---
  Future<List<Profile>> getAllSystemAdmins() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .or('role.eq.super_admin,role.eq.admin,role.eq.support');
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  Future<void> updateAdminRole(String id, String role) async {
    await _supabase.from('profiles').update({'role': role}).eq('id', id);
  }

  // --- Stores ---
  Future<List<Map<String, dynamic>>> getAllStores() async {
    final res = await _supabase.from('stores').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> createStore(Map<String, dynamic> data) async {
    await _supabase.from('stores').insert(data);
  }

  // --- Support Tickets ---
  Future<List<Map<String, dynamic>>> getAllSupportTickets() async {
    final res = await _supabase.from('support_tickets').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // --- Smart Services ---
  Future<List<Map<String, dynamic>>> getSmartServices() async {
    final res = await _supabase.from('smart_services').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> toggleSmartService(String id, bool status) async {
    await _supabase.from('smart_services').update({'status': status}).eq('id', id);
  }

  // --- Global Settings ---
  Future<Map<String, dynamic>> getGlobalSettings() async {
    final res = await _supabase.from('global_settings').select();
    final map = <String, dynamic>{};
    for (var item in res) {
      map[item['key_name']] = item['value'];
    }
    return map;
  }

  Future<void> saveGlobalSettings(String keyName, Map<String, dynamic> value) async {
    // Implement upsert based on key_name
    final res = await _supabase.from('global_settings').select('id').eq('key_name', keyName).maybeSingle();
    if (res != null) {
      await _supabase.from('global_settings').update({'value': value}).eq('id', res['id']!);
    } else {
      await _supabase.from('global_settings').insert({'key_name': keyName, 'value': value});
    }
  }
}
