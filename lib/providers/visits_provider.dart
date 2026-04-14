import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visit.dart';
import '../services/visit_service.dart';
import 'auth_provider.dart';

final visitService = Provider((ref) => VisitService());

final visitsProvider = FutureProvider<List<Visit>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  
  final clinicId = authState.profile?.clinicId;
  if (clinicId == null) return [];

  return ref.watch(visitService).getVisits(clinicId);
});

final patientVisitsProvider = FutureProvider.family<List<Visit>, String>((ref, patientId) async {
  return ref.watch(visitService).getPatientVisits(patientId);
});
