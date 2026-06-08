import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/visit.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/sync_service.dart';

class VisitService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Visit>> getVisits(String clinicId) async {
    try {
      final response = await _supabase
          .from('visits')
          .select('*, patients(*), profiles:doctor_id(full_name), visit_services(service_name)')
          .eq('clinic_id', clinicId)
          .order('visit_date', ascending: false);

      final jsonList = response as List;
      // Cache (basic - all visits for clinic, by saving per-patient inside getPatientVisits)
      return jsonList.map((json) => Visit.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addVisit(Map<String, dynamic> data, List<String> serviceIds) async {
    try {
      final response = await _supabase.from('visits').insert(data).select().single();
      final visitId = response['id'];

      if (serviceIds.isNotEmpty) {
        final servicesRes = await _supabase.from('services').select('id, name, price').inFilter('id', serviceIds);
        final servicesToInsert = (servicesRes as List).map((s) => {
          'visit_id': visitId,
          'service_id': s['id'],
          'service_name': s['name'],
          'service_price': s['price']
        }).toList();
        await _supabase.from('visit_services').insert(servicesToInsert);
      }
    } catch (e) {
      // Offline: create a temporary visit ID and queue it
      final tempId = const Uuid().v4();
      data['id'] = tempId;
      await SyncService.enqueueMutation('visits', 'INSERT', data);
      // Queue services if any
      for (final sid in serviceIds) {
        await SyncService.enqueueMutation('visit_services', 'INSERT', {
          'visit_id': tempId,
          'service_id': sid,
        });
      }
    }
  }

  Future<void> updateVisit(String id, Map<String, dynamic> data, List<String> serviceIds) async {
    try {
      await _supabase.from('visits').update(data).eq('id', id);
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
    } catch (e) {
      await SyncService.enqueueMutation('visits', 'UPDATE', data, matchField: 'id', matchValue: id);
    }
  }

  Future<void> deleteVisit(String id) async {
    try {
      await _supabase.from('visits').delete().eq('id', id);
    } catch (e) {
      await SyncService.enqueueMutation('visits', 'DELETE', {}, matchField: 'id', matchValue: id);
    }
  }

  Future<List<Visit>> getPatientVisits(String patientId) async {
    try {
      final response = await _supabase
          .from('visits')
          .select('*')
          .eq('patient_id', patientId)
          .order('visit_date', ascending: false);
      final jsonList = response as List;
      // Cache patient visits locally
      await LocalStorageService.savePatientVisits(patientId, jsonList);
      return jsonList.map((json) => Visit.fromJson(json)).toList();
    } catch (e) {
      // Offline fallback
      final cachedJson = LocalStorageService.getPatientVisits(patientId);
      if (cachedJson != null) {
        return cachedJson.map((json) => Visit.fromJson(json)).toList();
      }
      return [];
    }
  }
}
