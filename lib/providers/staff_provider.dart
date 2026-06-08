import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/staff_service.dart';
import '../models/staff_attendance.dart';
import '../models/staff_task.dart';
import '../models/profile.dart';
import 'auth_provider.dart';

final staffServiceProvider = Provider((ref) => StaffService());

final todayAttendanceProvider = FutureProvider.family<StaffAttendance?, ({String clinicId, String profileId})>((ref, args) {
  return ref.read(staffServiceProvider).getTodayAttendance(args.clinicId, args.profileId);
});

final attendanceHistoryProvider = FutureProvider.family<List<StaffAttendance>, ({String clinicId, String? profileId})>((ref, args) {
  return ref.read(staffServiceProvider).getAttendanceHistory(args.clinicId, profileId: args.profileId);
});

final staffTasksProvider = FutureProvider.family<List<StaffTask>, ({String clinicId, String? assignedTo, String? status})>((ref, args) {
  return ref.read(staffServiceProvider).getTasks(args.clinicId, assignedTo: args.assignedTo, status: args.status);
});

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
