import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic.dart';

class ClinicService {
  final _client = Supabase.instance.client;

  Future<Clinic?> getClinic(String clinicId) async {
    final response = await _client
        .from('clinics')
        .select()
        .eq('id', clinicId)
        .single();
    return Clinic.fromJson(response);
  }

  Future<void> updateClinic(String clinicId, Map<String, dynamic> data) async {
    await _client.from('clinics').update(data).eq('id', clinicId);
  }

  Future<List<Map<String, dynamic>>> getClinicDoctors(String clinicId) async {
    return await _client
        .from('profiles')
        .select('id, full_name, is_available')
        .eq('clinic_id', clinicId)
        .eq('role', 'doctor');
  }

  Future<void> updateDoctorAvailability(String doctorId, bool isAvailable) async {
    await _client
        .from('profiles')
        .update({'is_available': isAvailable})
        .eq('id', doctorId);
  }
}
