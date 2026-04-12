import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient.dart';

class PatientService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Patient>> getPatients(String clinicId) async {
    final response = await _client
        .from('patients')
        .select()
        .eq('clinic_id', clinicId)
        .order('full_name', ascending: true);
    
    return (response as List).map((json) => Patient.fromJson(json)).toList();
  }

  Future<List<Patient>> searchPatients(String clinicId, String query) async {
    final response = await _client
        .from('patients')
        .select()
        .eq('clinic_id', clinicId)
        .ilike('full_name', '%$query%')
        .order('full_name', ascending: true);
    
    return (response as List).map((json) => Patient.fromJson(json)).toList();
  }

  Future<void> addPatient(Map<String, dynamic> patientData) async {
    await _client.from('patients').insert(patientData);
  }

  Future<void> updatePatient(String id, Map<String, dynamic> patientData) async {
    await _client.from('patients').update(patientData).eq('id', id);
  }

  Future<void> deletePatient(String id) async {
    await _client.from('patients').delete().eq('id', id);
  }
}
