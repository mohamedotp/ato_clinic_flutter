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
  final String? insuranceCompanyId;
  final String? insuranceNumber;
  final DateTime? insuranceExpiry;
  final String? referralSource;
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
    this.insuranceCompanyId,
    this.insuranceNumber,
    this.insuranceExpiry,
    this.referralSource,
    required this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id']?.toString() ?? '',
      clinicId: json['clinic_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth']) : null,
      gender: json['gender'],
      nationalId: json['national_id'],
      address: json['address'],
      patientCode: json['patient_code'],
      status: json['status'],
      insuranceCompanyId: json['insurance_company_id'] as String?,
      insuranceNumber: json['insurance_number'] as String?,
      insuranceExpiry: json['insurance_expiry'] != null
          ? DateTime.parse(json['insurance_expiry'] as String)
          : null,
      referralSource: json['referral_source'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'national_id': nationalId,
      'address': address,
      'patient_code': patientCode,
      'status': status,
      'insurance_company_id': insuranceCompanyId,
      'insurance_number': insuranceNumber,
      'insurance_expiry': insuranceExpiry?.toIso8601String(),
      'referral_source': referralSource,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
