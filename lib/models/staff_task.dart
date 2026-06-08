class StaffTask {
  final String id;
  final String clinicId;
  final String assignedTo;
  final String createdBy;
  final String title;
  final String? description;
  final String status; // pending, in_progress, completed
  final DateTime? dueDate;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final DateTime createdAt;
  
  // Joins
  final String? assignedToName;
  final String? createdByName;

  StaffTask({
    required this.id,
    required this.clinicId,
    required this.assignedTo,
    required this.createdBy,
    required this.title,
    this.description,
    required this.status,
    this.dueDate,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.createdAt,
    this.assignedToName,
    this.createdByName,
  });

  factory StaffTask.fromJson(Map<String, dynamic> json) {
    return StaffTask(
      id: json['id'],
      clinicId: json['clinic_id'],
      assignedTo: json['assigned_to'],
      createdBy: json['created_by'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      relatedEntityType: json['related_entity_type'],
      relatedEntityId: json['related_entity_id'],
      createdAt: DateTime.parse(json['created_at']),
      assignedToName: json['assigned_to_profile']?['full_name'],
      createdByName: json['created_by_profile']?['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'related_entity_type': relatedEntityType,
      'related_entity_id': relatedEntityId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
