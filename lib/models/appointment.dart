import 'patient.dart';

enum AppointmentStatus {
  scheduled,
  confirmed,
  cancelled,
  completed,
  no_show
}

class Appointment {
  final String id;
  final String clinicId;
  final String patientId;
  final String? doctorId;
  final DateTime? scheduledAt;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? appointmentDate;
  final int? queueNumber;
  final String type;
  final List<String> serviceIds;
  final double totalPrice;
  
  // Joined Data
  final Patient? patient;
  final String? doctorName;

  Appointment({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.doctorId,
    this.scheduledAt,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.appointmentDate,
    this.queueNumber,
    this.type = 'appointment',
    this.serviceIds = const [],
    this.totalPrice = 0.0,
    this.patient,
    this.doctorName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      clinicId: json['clinic_id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : null,
      status: _parseStatus(json['status']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      appointmentDate: json['appointment_date'] != null ? DateTime.parse(json['appointment_date']) : null,
      queueNumber: json['queue_number'],
      type: json['type'] ?? 'appointment',
      serviceIds: json['service_ids'] != null ? List<String>.from(json['service_ids']) : [],
      totalPrice: json['total_price'] != null ? double.parse(json['total_price'].toString()) : 0.0,
      patient: json['patients'] != null ? Patient.fromJson(json['patients']) : null,
      doctorName: json['profiles'] != null ? json['profiles']['full_name'] : null,
    );
  }

  static AppointmentStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed': return AppointmentStatus.confirmed;
      case 'cancelled': return AppointmentStatus.cancelled;
      case 'completed': return AppointmentStatus.completed;
      case 'no_show': return AppointmentStatus.no_show;
      default: return AppointmentStatus.scheduled;
    }
  }

  String get statusLabel {
    switch (status) {
      case AppointmentStatus.confirmed: return 'مؤكد';
      case AppointmentStatus.cancelled: return 'ملغي';
      case AppointmentStatus.completed: return 'مكتمل';
      case AppointmentStatus.no_show: return 'لم يحضر';
      case AppointmentStatus.scheduled: return 'مجدول';
    }
  }

  String get typeLabel {
    switch (type) {
      case 'examination': return 'كشف عادي';
      case 'consultation': return 'استشارة';
      case 'session': return 'جلسة';
      case 'appointment':
      default: return 'موعد عام';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'clinic_id': clinicId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'status': status.name,
      'notes': notes,
      'appointment_date': appointmentDate?.toIso8601String(),
      'queue_number': queueNumber,
      'type': type,
      'service_ids': serviceIds,
      'total_price': totalPrice,
    };
  }
}
