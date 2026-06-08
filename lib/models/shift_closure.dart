class ShiftClosure {
  final String id;
  final String clinicId;
  final String staffId;
  final DateTime closedAt;
  final double expectedCash;
  final double actualCash;
  final double difference;
  final String? notes;
  final DateTime createdAt;
  
  // Joins user profile name
  final String? staffFullName;

  ShiftClosure({
    required this.id,
    required this.clinicId,
    required this.staffId,
    required this.closedAt,
    required this.expectedCash,
    required this.actualCash,
    required this.difference,
    this.notes,
    required this.createdAt,
    this.staffFullName,
  });

  factory ShiftClosure.fromJson(Map<String, dynamic> json) {
    return ShiftClosure(
      id: json['id'],
      clinicId: json['clinic_id'],
      staffId: json['staff_id'],
      closedAt: DateTime.parse(json['closed_at']),
      expectedCash: (json['expected_cash'] as num).toDouble(),
      actualCash: (json['actual_cash'] as num).toDouble(),
      difference: (json['difference'] as num).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      staffFullName: json['profiles'] != null ? json['profiles']['full_name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clinic_id': clinicId,
    'staff_id': staffId,
    'closed_at': closedAt.toIso8601String(),
    'expected_cash': expectedCash,
    'actual_cash': actualCash,
    'difference': difference,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };
}
