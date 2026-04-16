import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient.dart';

class PatientService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Patient>> getPatients([String? clinicId]) async {
    var query = _client.from('patients').select();
    
    if (clinicId != null) {
      query = query.eq('clinic_id', clinicId);
    }
    
    final response = await query.order('full_name', ascending: true);
    
    return (response as List).map((json) => Patient.fromJson(json)).toList();
  }

  Future<List<Patient>> searchPatients(String query, [String? clinicId]) async {
    var q = _client.from('patients').select();
    
    if (clinicId != null) {
      q = q.eq('clinic_id', clinicId);
    }
    
    final response = await q
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
