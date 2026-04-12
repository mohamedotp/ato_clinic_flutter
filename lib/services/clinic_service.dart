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
}
