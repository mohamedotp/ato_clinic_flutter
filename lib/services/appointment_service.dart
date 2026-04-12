import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';

class AppointmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Appointment>> getAppointments(String clinicId) async {
    final response = await _supabase
        .from('appointments')
        .select('*, patients(*), profiles:doctor_id(full_name)')
        .eq('clinic_id', clinicId)
        .order('appointment_date', ascending: true);

    return (response as List).map((json) => Appointment.fromJson(json)).toList();
  }

  Future<void> addAppointment(Map<String, dynamic> data) async {
    await _supabase.from('appointments').insert(data);
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    await _supabase.from('appointments').update(data).eq('id', id);
  }

  Future<void> deleteAppointment(String id) async {
    await _supabase.from('appointments').delete().eq('id', id);
  }
  
  Future<void> updateStatus(String id, String status) async {
    await _supabase.from('appointments').update({'status': status}).eq('id', id);
  }
}
