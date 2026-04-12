import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class StaffService {
  final _client = Supabase.instance.client;

  Future<List<Profile>> getStaffMembers(String clinicId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('clinic_id', clinicId);
    
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  Future<void> removeStaffMember(String profileId) async {
    // Usually we don't delete the profile, just clear the clinic_id
    await _client.from('profiles').update({'clinic_id': null}).eq('id', profileId);
  }
}
