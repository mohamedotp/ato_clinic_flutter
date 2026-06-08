import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic_material.dart';

class MaterialService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Materials CRUD ───────────────────────────────────────────────────────

  Future<List<ClinicMaterial>> getMaterials(String clinicId) async {
    final response = await _supabase
        .from('clinic_materials')
        .select()
        .eq('clinic_id', clinicId)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => ClinicMaterial.fromJson(json))
        .toList();
  }

  Future<ClinicMaterial> addMaterial(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('clinic_materials')
        .insert(data)
        .select()
        .single();
    return ClinicMaterial.fromJson(response);
  }

  Future<void> updateMaterial(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await _supabase.from('clinic_materials').update(data).eq('id', id);
  }

  Future<void> deleteMaterial(String id) async {
    await _supabase.from('clinic_materials').delete().eq('id', id);
  }

  Future<void> restockMaterial(String clinicId, String id, double addQty, String? userId) async {
    await addUsage({
      'clinic_id': clinicId,
      'material_id': id,
      'quantity_used': addQty,
      'usage_type': 'restock',
      'used_by': userId,
      'notes': 'إضافة مخزون',
    });
  }

  Future<void> issueMaterial(String clinicId, String id, double qty, String? userId, String notes) async {
    await addUsage({
      'clinic_id': clinicId,
      'material_id': id,
      'quantity_used': qty,
      'usage_type': 'transfer_out',
      'used_by': userId,
      'notes': notes,
    });
  }

  // ─── Usage CRUD ───────────────────────────────────────────────────────────

  /// Fetch all movement history for a specific material (any usage type)
  Future<List<MaterialUsage>> getMaterialHistory(String materialId) async {
    final response = await _supabase
        .from('patient_material_usage')
        .select(
            '*, clinic_materials(name, unit), profiles:used_by(full_name), patients:patient_id(full_name, phone)')
        .eq('material_id', materialId)
        .order('used_at', ascending: false);

    return (response as List)
        .map((json) => MaterialUsage.fromJson(json))
        .toList();
  }

  Future<List<MaterialUsage>> getPatientUsage(String patientId) async {
    final response = await _supabase
        .from('patient_material_usage')
        .select(
            '*, clinic_materials(name, unit), profiles:used_by(full_name)')
        .eq('patient_id', patientId)
        .order('used_at', ascending: false);

    return (response as List)
        .map((json) => MaterialUsage.fromJson(json))
        .toList();
  }

  Future<List<MaterialUsage>> getClinicUsage(String clinicId,
      {DateTime? from, DateTime? to}) async {
    var query = _supabase
        .from('patient_material_usage')
        .select(
            '*, clinic_materials(name, unit), profiles:used_by(full_name), patients:patient_id(full_name, phone)')
        .eq('clinic_id', clinicId);

    if (from != null) {
      query = query.gte('used_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('used_at', to.toIso8601String());
    }

    final response = await query.order('used_at', ascending: false);
    return (response as List)
        .map((json) => MaterialUsage.fromJson(json))
        .toList();
  }

  Future<MaterialUsage> addUsage(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('patient_material_usage')
        .insert(data)
        .select('*, clinic_materials(name, unit), profiles:used_by(full_name)')
        .single();
    return MaterialUsage.fromJson(response);
  }

  Future<void> deleteUsage(String usageId) async {
    await _supabase
        .from('patient_material_usage')
        .delete()
        .eq('id', usageId);
  }
}
