import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/treatment_plan.dart';

class TreatmentPlanService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TreatmentPlan>> getPlans(String clinicId) async {
    final data = await _client
        .from('treatment_plans')
        .select('*, patients(full_name), profiles!doctor_id(full_name), treatment_plan_sessions(*)')
        .eq('clinic_id', clinicId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => TreatmentPlan.fromJson(e)).toList();
  }

  Future<TreatmentPlan> getPlanById(String id) async {
    final data = await _client
        .from('treatment_plans')
        .select('*, patients(full_name), profiles!doctor_id(full_name), treatment_plan_sessions(*)')
        .eq('id', id)
        .single();
    return TreatmentPlan.fromJson(data);
  }

  Future<TreatmentPlan> createPlan(Map<String, dynamic> planData, List<Map<String, dynamic>> sessions) async {
    final plan = await _client.from('treatment_plans').insert(planData).select().single();
    if (sessions.isNotEmpty) {
      final sessionsWithPlanId = sessions.map((s) => {...s, 'plan_id': plan['id'], 'clinic_id': planData['clinic_id']}).toList();
      await _client.from('treatment_plan_sessions').insert(sessionsWithPlanId);
    }
    return getPlanById(plan['id']);
  }

  Future<void> updatePlan(String id, Map<String, dynamic> data) async {
    await _client.from('treatment_plans').update({...data, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  Future<void> completeSession(String sessionId) async {
    await _client.from('treatment_plan_sessions').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);
  }

  Future<void> deletePlan(String id) async {
    await _client.from('treatment_plans').delete().eq('id', id);
  }
}
