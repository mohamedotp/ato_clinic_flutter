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
  final String? patientCode;
  final String? status;
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
    this.patientCode,
    this.status,
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
      patientCode: json['patient_code'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'clinic_id': clinicId,
      'full_name': fullName,
      'phone': phone,
      'patient_code': patientCode,
      'status': status,
      'email': email,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'national_id': nationalId,
      'address': address,
    };
  }
}
