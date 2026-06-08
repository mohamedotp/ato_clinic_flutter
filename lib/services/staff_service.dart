import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/staff_attendance.dart';
import '../models/staff_task.dart';
import '../models/profile.dart';

class StaffService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- ATTENDANCE ---

  Future<StaffAttendance?> getTodayAttendance(String clinicId, String profileId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    
    final res = await _client
        .from('staff_attendance')
        .select()
        .eq('clinic_id', clinicId)
        .eq('profile_id', profileId)
        .gte('check_in', startOfDay)
        .order('check_in', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res == null) return null;
    return StaffAttendance.fromJson(res);
  }

  Future<StaffAttendance> checkIn(String clinicId, String profileId, {String? notes}) async {
    final res = await _client.from('staff_attendance').insert({
      'clinic_id': clinicId,
      'profile_id': profileId,
      'check_in': DateTime.now().toIso8601String(),
      'status': 'present',
      'notes': notes,
    }).select().single();
    return StaffAttendance.fromJson(res);
  }

  Future<void> checkOut(String id) async {
    await _client.from('staff_attendance').update({
      'check_out': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<List<StaffAttendance>> getAttendanceHistory(String clinicId, {String? profileId}) async {
    var query = _client.from('staff_attendance').select().eq('clinic_id', clinicId);
    if (profileId != null) {
      query = query.eq('profile_id', profileId);
    }
    final data = await query.order('check_in', ascending: false);
    return (data as List).map((e) => StaffAttendance.fromJson(e)).toList();
  }

  // --- TASKS ---

  Future<List<StaffTask>> getTasks(String clinicId, {String? assignedTo, String? status}) async {
    var query = _client.from('staff_tasks').select('''
      *,
      assigned_to_profile:profiles!assigned_to(full_name),
      created_by_profile:profiles!created_by(full_name)
    ''').eq('clinic_id', clinicId);

    if (assignedTo != null) query = query.eq('assigned_to', assignedTo);
    if (status != null) query = query.eq('status', status);

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => StaffTask.fromJson(e)).toList();
  }

  Future<StaffTask> createTask(Map<String, dynamic> data) async {
    final res = await _client.from('staff_tasks').insert(data).select('''
      *,
      assigned_to_profile:profiles!assigned_to(full_name),
      created_by_profile:profiles!created_by(full_name)
    ''').single();
    return StaffTask.fromJson(res);
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _client.from('staff_tasks').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('staff_tasks').delete().eq('id', taskId);
  }

  // --- USER MANAGEMENT ---

  Future<List<Profile>> getStaffMembers(String clinicId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('clinic_id', clinicId);
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Profile.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في جلب أعضاء الطاقم: ${e.toString()}');
    }
  }

  Future<void> removeStaffMember(String profileId) async {
    try {
      await _client.from('profiles').update({'clinic_id': null}).eq('id', profileId);
    } catch (e) {
      throw Exception('فشل في إزالة العضو: ${e.toString()}');
    }
  }

  Future<void> addStaffMember(Map<String, dynamic> data) async {
    try {
      final response = await _client.functions.invoke(
        'create-user',
        body: data,
      );

      if (response.status == 200) {
        return;
      }

      final errorData = response.data;
      String errorMessage = 'حدث خطأ غير معروف';

      if (errorData is Map) {
        errorMessage = errorData['error'] ?? errorMessage;
      }

      throw Exception(errorMessage);
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] != null) {
        throw Exception(details['error']);
      }
      throw Exception('فشل في استدعاء الخدمة: ${e.toString()}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء إضافة العضو: ${e.toString()}');
    }
  }

  Future<void> updateStaffMember(String profileId, Map<String, dynamic> data) async {
    try {
      await _client.from('profiles').update(data).eq('id', profileId);
    } catch (e) {
      throw Exception('فشل في تعديل بيانات العضو: ${e.toString()}');
    }
  }
}
