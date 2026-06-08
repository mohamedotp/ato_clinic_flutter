class StaffAttendance {
  final String id;
  final String clinicId;
  final String profileId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String status;
  final String? notes;
  final DateTime createdAt;

  StaffAttendance({
    required this.id,
    required this.clinicId,
    required this.profileId,
    required this.checkIn,
    this.checkOut,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory StaffAttendance.fromJson(Map<String, dynamic> json) {
    return StaffAttendance(
      id: json['id'],
      clinicId: json['clinic_id'],
      profileId: json['profile_id'],
      checkIn: DateTime.parse(json['check_in']),
      checkOut: json['check_out'] != null ? DateTime.parse(json['check_out']) : null,
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'profile_id': profileId,
      'check_in': checkIn.toIso8601String(),
      'check_out': checkOut?.toIso8601String(),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
