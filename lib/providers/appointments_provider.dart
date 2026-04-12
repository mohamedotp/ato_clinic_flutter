import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import 'auth_provider.dart';

final appointmentService = Provider((ref) => AppointmentService());

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  
  final clinicId = authState.profile?.clinicId;
  if (clinicId == null) return [];

  return ref.watch(appointmentService).getAppointments(clinicId);
});
