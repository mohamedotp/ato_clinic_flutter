import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clinic.dart';
import '../services/clinic_service.dart';
import 'auth_provider.dart';

final clinicServiceProvider = Provider((ref) => ClinicService());

final clinicProvider = FutureProvider<Clinic?>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    final clinicId = authState.profile?.clinicId;
    if (clinicId != null) {
      return ref.read(clinicServiceProvider).getClinic(clinicId);
    }
  }
  return null;
});
