import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/procedure.dart';

class ProcedureService {
  final SupabaseClient _client = Supabase.instance.client;

  // Templates
  Future<List<ProcedureTemplate>> getTemplates(String clinicId) async {
    final data = await _client
        .from('procedure_templates')
        .select('*, procedure_steps(*)')
        .eq('clinic_id', clinicId)
        .eq('is_active', true)
        .order('name');
    return (data as List).map((e) => ProcedureTemplate.fromJson(e)).toList();
  }

  Future<ProcedureTemplate> createTemplate(Map<String, dynamic> templateData, List<Map<String, dynamic>> steps) async {
    final template = await _client.from('procedure_templates').insert(templateData).select().single();
    if (steps.isNotEmpty) {
      final stepsWithIds = steps.map((s) => {...s, 'template_id': template['id'], 'clinic_id': templateData['clinic_id']}).toList();
      await _client.from('procedure_steps').insert(stepsWithIds);
    }
    final data = await _client.from('procedure_templates').select('*, procedure_steps(*)').eq('id', template['id']).single();
    return ProcedureTemplate.fromJson(data);
  }

  // Patient Procedures
  Future<List<PatientProcedure>> getPatientProcedures(String clinicId, {String? patientId}) async {
    var query = _client
        .from('patient_procedures')
        .select('*, patients(full_name), patient_procedure_steps(*)')
        .eq('clinic_id', clinicId);
    if (patientId != null) query = query.eq('patient_id', patientId);
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => PatientProcedure.fromJson(e)).toList();
  }

  Future<PatientProcedure> startProcedure(Map<String, dynamic> procedureData, List<Map<String, dynamic>> steps) async {
    final proc = await _client.from('patient_procedures').insert(procedureData).select().single();
    if (steps.isNotEmpty) {
      final stepsWithId = steps.map((s) => {...s, 'procedure_id': proc['id']}).toList();
      await _client.from('patient_procedure_steps').insert(stepsWithId);
    }
    final data = await _client.from('patient_procedures').select('*, patients(full_name), patient_procedure_steps(*)').eq('id', proc['id']).single();
    return PatientProcedure.fromJson(data);
  }

  Future<void> completeStep(String stepId, {String? visitId, String? notes}) async {
    await _client.from('patient_procedure_steps').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
      if (visitId != null) 'visit_id': visitId,
      if (notes != null) 'notes': notes,
    }).eq('id', stepId);
  }

  Future<void> completeProcedure(String procedureId) async {
    await _client.from('patient_procedures').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', procedureId);
  }
}
