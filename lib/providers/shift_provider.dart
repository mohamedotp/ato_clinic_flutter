import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/shift_service.dart';
import '../models/shift_closure.dart';
import 'auth_provider.dart';

final shiftServiceProvider = Provider((ref) => ShiftService());

final expectedCashProvider = FutureProvider.autoDispose<double>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return 0.0;

  final profile = authState.profile;
  final clinicId = profile?.clinicId;
  final staffId = profile?.id;

  if (clinicId == null || staffId == null) return 0.0;

  return ref.read(shiftServiceProvider).getExpectedCash(clinicId, staffId);
});

final shiftClosuresProvider = FutureProvider.autoDispose<List<ShiftClosure>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];

  final clinicId = authState.profile?.clinicId;
  if (clinicId == null) return [];

  return ref.read(shiftServiceProvider).getClosures(clinicId);
});
