class TreatmentPlan {
  final String id;
  final String clinicId;
  final String patientId;
  final String? doctorId;
  final String title;
  final String? description;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalCost;
  final double paidAmount;
  final DateTime createdAt;

  // Joined
  final String? patientName;
  final String? doctorName;
  final List<TreatmentPlanSession> sessions;

  TreatmentPlan({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.doctorId,
    required this.title,
    this.description,
    this.status = 'active',
    this.startDate,
    this.endDate,
    this.totalCost = 0,
    this.paidAmount = 0,
    required this.createdAt,
    this.patientName,
    this.doctorName,
    this.sessions = const [],
  });

  factory TreatmentPlan.fromJson(Map<String, dynamic> json) {
    return TreatmentPlan(
      id: json['id'],
      clinicId: json['clinic_id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'] ?? 'active',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      patientName: json['patients']?['full_name'],
      doctorName: json['profiles']?['full_name'],
      sessions: json['treatment_plan_sessions'] != null
          ? (json['treatment_plan_sessions'] as List).map((e) => TreatmentPlanSession.fromJson(e)).toList()
          : [],
    );
  }

  double get remainingAmount => totalCost - paidAmount;
  int get completedSessions => sessions.where((s) => s.status == 'completed').length;
  double get progressPercentage => sessions.isEmpty ? 0 : completedSessions / sessions.length;

  String get statusLabel {
    switch (status) {
      case 'completed': return 'مكتملة';
      case 'cancelled': return 'ملغاة';
      case 'on_hold': return 'معلقة';
      default: return 'نشطة';
    }
  }
}

class TreatmentPlanSession {
  final String id;
  final String planId;
  final String clinicId;
  final int sessionNumber;
  final String title;
  final String? description;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? visitId;
  final double cost;
  final String? notes;

  TreatmentPlanSession({
    required this.id,
    required this.planId,
    required this.clinicId,
    required this.sessionNumber,
    required this.title,
    this.description,
    this.status = 'pending',
    this.scheduledAt,
    this.completedAt,
    this.visitId,
    this.cost = 0,
    this.notes,
  });

  factory TreatmentPlanSession.fromJson(Map<String, dynamic> json) {
    return TreatmentPlanSession(
      id: json['id'],
      planId: json['plan_id'],
      clinicId: json['clinic_id'],
      sessionNumber: json['session_number'],
      title: json['title'],
      description: json['description'],
      status: json['status'] ?? 'pending',
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      visitId: json['visit_id'],
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      notes: json['notes'],
    );
  }

  String get statusLabel {
    switch (status) {
      case 'completed': return 'مكتملة';
      case 'cancelled': return 'ملغاة';
      default: return 'قادمة';
    }
  }
}
