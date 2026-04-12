import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/visit.dart';

class VisitService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Visit>> getVisits(String clinicId) async {
    final response = await _supabase
        .from('visits')
        .select('*, patients(*), profiles:doctor_id(full_name), visit_services(service_name)')
        .eq('clinic_id', clinicId)
        .order('visit_date', ascending: false);

    return (response as List).map((json) => Visit.fromJson(json)).toList();
  }

  Future<void> addVisit(Map<String, dynamic> data, List<String> serviceIds) async {
    final response = await _supabase.from('visits').insert(data).select().single();
    final visitId = response['id'];

    if (serviceIds.isNotEmpty) {
      // Fetch service details for logs
      final servicesRes = await _supabase.from('services').select('id, name, price').inFilter('id', serviceIds);
      final servicesToInsert = (servicesRes as List).map((s) => {
        'visit_id': visitId,
        'service_id': s['id'],
        'service_name': s['name'],
        'service_price': s['price']
      }).toList();
      
      await _supabase.from('visit_services').insert(servicesToInsert);
    }
  }

  Future<void> updateVisit(String id, Map<String, dynamic> data, List<String> serviceIds) async {
    await _supabase.from('visits').update(data).eq('id', id);
    
    // Update services - simplest is delete and re-insert
    await _supabase.from('visit_services').delete().eq('visit_id', id);
    if (serviceIds.isNotEmpty) {
      final servicesRes = await _supabase.from('services').select('id, name, price').inFilter('id', serviceIds);
      final servicesToInsert = (servicesRes as List).map((s) => {
        'visit_id': id,
        'service_id': s['id'],
        'service_name': s['name'],
        'service_price': s['price']
      }).toList();
      
      await _supabase.from('visit_services').insert(servicesToInsert);
    }
  }

  Future<void> deleteVisit(String id) async {
    await _supabase.from('visits').delete().eq('id', id);
  }
}
