import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class StaffService {
  final _client = Supabase.instance.client;

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

      // Handle successful creation
      if (response.status == 200) {
        return;
      }

      // Handle non-200 responses
      final errorData = response.data;
      String errorMessage = 'حدث خطأ غير معروف';

      if (errorData is Map) {
        errorMessage = errorData['error'] ?? errorMessage;
      }

      throw Exception(errorMessage);
    } on FunctionException catch (e) {
      // Handle Supabase function specific exceptions
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
