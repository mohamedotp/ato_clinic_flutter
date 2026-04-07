import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';

class AppointmentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Appointment>> getTodayAppointments() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final response = await _client
        .from('appointments')
        .select()
        .eq('appointment_date', today)
        .order('appointment_time', ascending: true);
    
    return (response as List).map((json) => Appointment.fromJson(json)).toList();
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    await _client
        .from('appointments')
        .update({'status': status})
        .eq('id', id);
  }
}
