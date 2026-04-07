import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient.dart';

class PatientService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Patient>> getPatients() async {
    final response = await _client
        .from('patients')
        .select()
        .order('full_name', ascending: true);
    
    return (response as List).map((json) => Patient.fromJson(json)).toList();
  }

  Future<List<Patient>> searchPatients(String query) async {
    final response = await _client
        .from('patients')
        .select()
        .ilike('full_name', '%$query%')
        .order('full_name', ascending: true);
    
    return (response as List).map((json) => Patient.fromJson(json)).toList();
  }

  Future<void> addPatient(Map<String, dynamic> patientData) async {
    await _client.from('patients').insert(patientData);
  }
}
