import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/sync_service.dart';

class PatientService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Patient>> getPatients([String? clinicId]) async {
    try {
      var query = _client.from('patients').select();
      
      if (clinicId != null) {
        query = query.eq('clinic_id', clinicId);
      }
      
      final response = await query.order('full_name', ascending: true);
      final jsonList = response as List;
      
      // Save to cache
      await LocalStorageService.savePatients(jsonList);
      
      return jsonList.map((json) => Patient.fromJson(json)).toList();
    } catch (e) {
      // Fallback to cache if offline
      final cachedJson = LocalStorageService.getPatients();
      if (cachedJson != null) {
        var cachedList = cachedJson.map((json) => Patient.fromJson(json)).toList();
        if (clinicId != null) {
          cachedList = cachedList.where((p) => p.clinicId == clinicId).toList();
        }
        return cachedList;
      }
      return [];
    }
  }

  Future<List<Patient>> searchPatients(String query, [String? clinicId]) async {
    try {
      var q = _client.from('patients').select();
      
      if (clinicId != null) {
        q = q.eq('clinic_id', clinicId);
      }
      
      final response = await q
          .ilike('full_name', '%$query%')
          .order('full_name', ascending: true);
      
      return (response as List).map((json) => Patient.fromJson(json)).toList();
    } catch (e) {
      // Offline search
      final cachedJson = LocalStorageService.getPatients();
      if (cachedJson != null) {
        var cachedList = cachedJson.map((json) => Patient.fromJson(json)).toList();
        if (clinicId != null) {
          cachedList = cachedList.where((p) => p.clinicId == clinicId).toList();
        }
        return cachedList.where((p) => p.fullName.toLowerCase().contains(query.toLowerCase())).toList();
      }
      return [];
    }
  }

  Future<void> addPatient(Map<String, dynamic> patientData) async {
    try {
      await _client.from('patients').insert(patientData);
    } catch (e) {
      // If offline, add to sync queue
      await SyncService.enqueueMutation('patients', 'INSERT', patientData);
    }
  }

  Future<void> updatePatient(String id, Map<String, dynamic> patientData) async {
    try {
      await _client.from('patients').update(patientData).eq('id', id);
    } catch (e) {
      await SyncService.enqueueMutation('patients', 'UPDATE', patientData, matchField: 'id', matchValue: id);
    }
  }

  Future<void> deletePatient(String id) async {
    try {
      await _client.from('patients').delete().eq('id', id);
    } catch (e) {
      await SyncService.enqueueMutation('patients', 'DELETE', {}, matchField: 'id', matchValue: id);
    }
  }
}
