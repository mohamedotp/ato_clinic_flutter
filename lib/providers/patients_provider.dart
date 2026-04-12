import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import 'auth_provider.dart';

final patientService = Provider((ref) => PatientService());

final patientsProvider = FutureProvider<List<Patient>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  
  final clinicId = authState.profile?.clinicId;
  if (clinicId == null) return [];

  return ref.watch(patientService).getPatients(clinicId);
});

final patientSearchProvider = StateProvider<String>((ref) => '');

final searchedPatientsProvider = FutureProvider<List<Patient>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  
  final clinicId = authState.profile?.clinicId;
  if (clinicId == null) return [];

  final query = ref.watch(patientSearchProvider);
  if (query.isEmpty) {
    return ref.watch(patientsProvider.future);
  }
  return ref.watch(patientService).searchPatients(clinicId, query);
});
