import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import 'auth_provider.dart';
import '../models/profile.dart';

final patientService = Provider((ref) => PatientService());

final patientsProvider = FutureProvider<List<Patient>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    print('=== patientsProvider: User not authenticated ===');
    return [];
  }
  
  final profile = authState.profile;
  final clinicId = profile?.clinicId;
  final isSuperAdmin = profile?.role == UserRole.super_admin;

  print('=== patientsProvider: Role=${profile?.role}, clinicId=$clinicId ===');

  if (clinicId == null && !isSuperAdmin) {
    print('=== patientsProvider: No clinicId and not super_admin, returning empty ===');
    return [];
  }

  print('=== patientsProvider: Fetching patients... ===');
  try {
    final list = await ref.watch(patientService).getPatients(clinicId);
    print('=== patientsProvider: Successfully fetched ${list.length} patients ===');
    return list;
  } catch (e) {
    print('=== ERROR FETCHING PATIENTS ===');
    print(e);
    return [];
  }
});

final patientSearchProvider = StateProvider<String>((ref) => '');

final searchedPatientsProvider = FutureProvider<List<Patient>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  
  final profile = authState.profile;
  final clinicId = profile?.clinicId;
  final query = ref.watch(patientSearchProvider);

  if (query.isEmpty) {
    return ref.watch(patientsProvider.future);
  }

  return ref.watch(patientService).searchPatients(query, clinicId);
});
