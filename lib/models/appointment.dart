enum AppointmentStatus {
  scheduled,
  confirmed,
  cancelled,
  completed,
  no_show,
}

class Appointment {
  final String id;
  final String clinicId;
  final String patientId;
  final String doctorId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      clinicId: json['clinic_id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      appointmentTime: json['appointment_time'],
      status: AppointmentStatus.values.byName(json['status']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
