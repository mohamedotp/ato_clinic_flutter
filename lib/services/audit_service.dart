import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/audit_log.dart';

class AuditService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> logEvent({
    required String clinicId,
    required String userId,
    required String action,
    required String tableName,
    String? recordId,
    required String description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    try {
      await _client.from('audit_logs').insert({
        'clinic_id': clinicId,
        'user_id': userId,
        'action': action,
        'table_name': tableName,
        'record_id': recordId,
        'description': description,
        'old_values': oldValues,
        'new_values': newValues,
      });
    } catch (e) {
      // Fail silently for security logging so as not to interrupt user transaction
      print('=== Audit Log Error: $e ===');
    }
  }

  Future<List<AuditLog>> getLogs(String clinicId) async {
    try {
      final response = await _client
          .from('audit_logs')
          .select('*, profiles(full_name)')
          .eq('clinic_id', clinicId)
          .order('created_at', ascending: false)
          .limit(200);

      final jsonList = response as List;
      return jsonList.map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      print('=== Error fetching audit logs: $e ===');
      return [];
    }
  }
}
