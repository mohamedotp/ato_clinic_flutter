import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';

final patientService = Provider((ref) => PatientService());

final patientsProvider = FutureProvider<List<Patient>>((ref) async {
  return ref.watch(patientService).getPatients();
});

final patientSearchProvider = StateProvider<String>((ref) => '');

final searchedPatientsProvider = FutureProvider<List<Patient>>((ref) async {
  final query = ref.watch(patientSearchProvider);
  if (query.isEmpty) {
    return ref.watch(patientsProvider.future);
  }
  return ref.watch(patientService).searchPatients(query);
});
