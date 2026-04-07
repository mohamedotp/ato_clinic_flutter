import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

final appointmentService = Provider((ref) => AppointmentService());

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  return ref.watch(appointmentService).getTodayAppointments();
});

final appointmentStatusUpdater = Provider((ref) {
  final service = ref.watch(appointmentService);
  return (String id, AppointmentStatus status) async {
    await service.updateAppointmentStatus(id, status.name);
    ref.invalidate(appointmentsProvider);
  };
});
