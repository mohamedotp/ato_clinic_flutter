class Patient {
  final String id;
  final String clinicId;
  final String fullName;
  final String? phone;
  final String? email;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? nationalId;
  final String? address;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.clinicId,
    required this.fullName,
    this.phone,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.nationalId,
    this.address,
    required this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      clinicId: json['clinic_id'],
      fullName: json['full_name'],
      phone: json['phone'],
      email: json['email'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      gender: json['gender'],
      nationalId: json['national_id'],
      address: json['address'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
