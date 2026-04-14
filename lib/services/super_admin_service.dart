import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic.dart';

final superAdminServiceProvider = Provider((ref) => SuperAdminService());

final allClinicsProvider = FutureProvider<List<Clinic>>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.getAllClinics();
});

class SuperAdminService {
  final _supabase = Supabase.instance.client;

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
    await _supabase
        .from('clinics')
        .update(data)
        .eq('id', id);
  }

  Future<void> deleteClinic(String id) async {
    await _supabase
        .from('clinics')
        .delete()
        .eq('id', id);
  }
}
