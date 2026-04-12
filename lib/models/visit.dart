import 'patient.dart';

enum VisitStatus {
  scheduled,
  in_progress,
  completed,
  cancelled
}

class Visit {
  final String id;
  final String clinicId;
  final String patientId;
  final String? appointmentId;
  final String? doctorId;
  final String? diagnosis;
  final String? treatment;
  final double cost;
  final VisitStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? visitDate;

  // Joined Data
  final Patient? patient;
  final String? doctorName;
  final List<String>? services;

  Visit({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.appointmentId,
    this.doctorId,
    this.diagnosis,
    this.treatment,
    required this.cost,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.visitDate,
    this.patient,
    this.doctorName,
    this.services,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'],
      clinicId: json['clinic_id'],
      patientId: json['patient_id'],
      appointmentId: json['appointment_id'],
      doctorId: json['doctor_id'],
      diagnosis: json['diagnosis'],
      treatment: json['treatment'],
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      visitDate: json['visit_date'] != null ? DateTime.parse(json['visit_date']) : null,
      patient: json['patients'] != null ? Patient.fromJson(json['patients']) : null,
      doctorName: json['profiles'] != null ? json['profiles']['full_name'] : null,
      services: json['visit_services'] != null 
        ? (json['visit_services'] as List).map((s) => s['service_name'] as String).toList()
        : null,
    );
  }

  static VisitStatus _parseStatus(String? status) {
    switch (status) {
      case 'in_progress': return VisitStatus.in_progress;
      case 'completed': return VisitStatus.completed;
      case 'cancelled': return VisitStatus.cancelled;
      default: return VisitStatus.scheduled;
    }
  }

  String get statusLabel {
    switch (status) {
      case VisitStatus.in_progress: return 'قيد التنفيذ';
      case VisitStatus.completed: return 'مكتملة';
      case VisitStatus.cancelled: return 'ملغاة';
      case VisitStatus.scheduled: return 'مجدولة';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'clinic_id': clinicId,
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'doctor_id': doctorId,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'cost': cost,
      'status': status.name,
      'visit_date': visitDate?.toIso8601String(),
    };
  }
}
