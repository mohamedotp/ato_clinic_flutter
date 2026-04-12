import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/staff_service.dart';
import 'auth_provider.dart';

final staffServiceProvider = Provider((ref) => StaffService());

final staffMembersProvider = FutureProvider<List<Profile>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    final clinicId = authState.profile?.clinicId;
    if (clinicId != null) {
      return ref.read(staffServiceProvider).getStaffMembers(clinicId);
    }
  }
  return [];
});
