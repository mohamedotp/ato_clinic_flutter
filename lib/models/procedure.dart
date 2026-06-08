class ProcedureTemplate {
  final String id;
  final String clinicId;
  final String? serviceId;
  final String name;
  final String? description;
  final int totalSessions;
  final bool isActive;
  final List<ProcedureStep> steps;

  ProcedureTemplate({
    required this.id,
    required this.clinicId,
    this.serviceId,
    required this.name,
    this.description,
    this.totalSessions = 1,
    this.isActive = true,
    this.steps = const [],
  });

  factory ProcedureTemplate.fromJson(Map<String, dynamic> json) {
    return ProcedureTemplate(
      id: json['id'],
      clinicId: json['clinic_id'],
      serviceId: json['service_id'],
      name: json['name'],
      description: json['description'],
      totalSessions: json['total_sessions'] ?? 1,
      isActive: json['is_active'] ?? true,
      steps: json['procedure_steps'] != null
          ? (json['procedure_steps'] as List).map((e) => ProcedureStep.fromJson(e)).toList()
          : [],
    );
  }
}

class ProcedureStep {
  final String id;
  final String templateId;
  final String clinicId;
  final int stepNumber;
  final String title;
  final String? description;
  final int estimatedDurationMinutes;
  final double cost;
  final String? notes;

  ProcedureStep({
    required this.id,
    required this.templateId,
    required this.clinicId,
    required this.stepNumber,
    required this.title,
    this.description,
    this.estimatedDurationMinutes = 30,
    this.cost = 0,
    this.notes,
  });

  factory ProcedureStep.fromJson(Map<String, dynamic> json) {
    return ProcedureStep(
      id: json['id'],
      templateId: json['template_id'],
      clinicId: json['clinic_id'],
      stepNumber: json['step_number'],
      title: json['title'],
      description: json['description'],
      estimatedDurationMinutes: json['estimated_duration_minutes'] ?? 30,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      notes: json['notes'],
    );
  }
}

class PatientProcedure {
  final String id;
  final String clinicId;
  final String patientId;
  final String? templateId;
  final String? treatmentPlanId;
  final String title;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? patientName;
  final List<PatientProcedureStep> steps;

  PatientProcedure({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.templateId,
    this.treatmentPlanId,
    required this.title,
    this.status = 'in_progress',
    required this.startedAt,
    this.completedAt,
    this.patientName,
    this.steps = const [],
  });

  factory PatientProcedure.fromJson(Map<String, dynamic> json) {
    return PatientProcedure(
      id: json['id'],
      clinicId: json['clinic_id'],
      patientId: json['patient_id'],
      templateId: json['template_id'],
      treatmentPlanId: json['treatment_plan_id'],
      title: json['title'],
      status: json['status'] ?? 'in_progress',
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      patientName: json['patients']?['full_name'],
      steps: json['patient_procedure_steps'] != null
          ? (json['patient_procedure_steps'] as List).map((e) => PatientProcedureStep.fromJson(e)).toList()
          : [],
    );
  }

  int get completedSteps => steps.where((s) => s.status == 'completed').length;
  double get progressPercentage => steps.isEmpty ? 0 : completedSteps / steps.length;
}

class PatientProcedureStep {
  final String id;
  final String procedureId;
  final int stepNumber;
  final String title;
  final String? description;
  final String status;
  final DateTime? completedAt;
  final String? visitId;
  final String? notes;
  final double cost;

  PatientProcedureStep({
    required this.id,
    required this.procedureId,
    required this.stepNumber,
    required this.title,
    this.description,
    this.status = 'pending',
    this.completedAt,
    this.visitId,
    this.notes,
    this.cost = 0,
  });

  factory PatientProcedureStep.fromJson(Map<String, dynamic> json) {
    return PatientProcedureStep(
      id: json['id'],
      procedureId: json['procedure_id'],
      stepNumber: json['step_number'],
      title: json['title'],
      description: json['description'],
      status: json['status'] ?? 'pending',
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      visitId: json['visit_id'],
      notes: json['notes'],
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
    );
  }
}
