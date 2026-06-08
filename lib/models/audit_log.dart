class AuditLog {
  final String id;
  final String clinicId;
  final String userId;
  final String action;
  final String tableName;
  final String? recordId;
  final String description;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime createdAt;
  
  // Optional field populated when fetching logs with profile joins
  final String? userFullName;

  AuditLog({
    required this.id,
    required this.clinicId,
    required this.userId,
    required this.action,
    required this.tableName,
    this.recordId,
    required this.description,
    this.oldValues,
    this.newValues,
    required this.createdAt,
    this.userFullName,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      clinicId: json['clinic_id'],
      userId: json['user_id'],
      action: json['action'],
      tableName: json['table_name'],
      recordId: json['record_id'],
      description: json['description'] ?? '',
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
      userFullName: json['profiles'] != null ? json['profiles']['full_name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clinic_id': clinicId,
    'user_id': userId,
    'action': action,
    'table_name': tableName,
    'record_id': recordId,
    'description': description,
    'old_values': oldValues,
    'new_values': newValues,
    'created_at': createdAt.toIso8601String(),
  };
}
