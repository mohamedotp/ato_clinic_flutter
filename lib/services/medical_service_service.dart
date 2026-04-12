import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medical_service.dart';

class MedicalServiceService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MedicalService>> getServices() async {
    final response = await _client
        .from('services')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => MedicalService.fromJson(json)).toList();
  }

  Future<void> addService(Map<String, dynamic> serviceData) async {
    await _client.from('services').insert(serviceData);
  }

  Future<void> updateService(String id, Map<String, dynamic> serviceData) async {
    await _client.from('services').update(serviceData).eq('id', id);
  }

  Future<void> deleteService(String id) async {
    await _client.from('services').delete().eq('id', id);
  }
}
