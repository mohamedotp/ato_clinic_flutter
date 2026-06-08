import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/insurance_company.dart';

class InsuranceService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<InsuranceCompany>> getCompanies(String clinicId) async {
    final data = await _client
        .from('insurance_companies')
        .select()
        .eq('clinic_id', clinicId)
        .order('name');
    return (data as List).map((e) => InsuranceCompany.fromJson(e)).toList();
  }

  Future<InsuranceCompany> createCompany(Map<String, dynamic> data) async {
    final res = await _client.from('insurance_companies').insert(data).select().single();
    return InsuranceCompany.fromJson(res);
  }

  Future<void> updateCompany(String id, Map<String, dynamic> data) async {
    await _client.from('insurance_companies').update({...data, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  Future<void> deleteCompany(String id) async {
    await _client.from('insurance_companies').delete().eq('id', id);
  }

  Future<Map<String, dynamic>?> getDoctorPercentage(String clinicId, String doctorId) async {
    final data = await _client
        .from('doctor_percentages')
        .select()
        .eq('clinic_id', clinicId)
        .eq('doctor_id', doctorId)
        .eq('is_active', true)
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> getAllDoctorPercentages(String clinicId) async {
    final data = await _client
        .from('doctor_percentages')
        .select('*, profiles!doctor_id(full_name, avatar_url)')
        .eq('clinic_id', clinicId)
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> setDoctorPercentage(String clinicId, String doctorId, double percentage, String base) async {
    await _client.from('doctor_percentages').upsert({
      'clinic_id': clinicId,
      'doctor_id': doctorId,
      'percentage': percentage,
      'calculation_base': base,
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'clinic_id,doctor_id');
  }
}
