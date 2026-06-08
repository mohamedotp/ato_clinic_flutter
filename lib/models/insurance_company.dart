class InsuranceCompany {
  final String id;
  final String clinicId;
  final String name;
  final double coveragePercentage;
  final String? contactPhone;
  final String? contactEmail;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  InsuranceCompany({
    required this.id,
    required this.clinicId,
    required this.name,
    this.coveragePercentage = 80,
    this.contactPhone,
    this.contactEmail,
    this.notes,
    this.isActive = true,
    required this.createdAt,
  });

  factory InsuranceCompany.fromJson(Map<String, dynamic> json) {
    return InsuranceCompany(
      id: json['id'],
      clinicId: json['clinic_id'],
      name: json['name'],
      coveragePercentage: (json['coverage_percentage'] as num?)?.toDouble() ?? 80,
      contactPhone: json['contact_phone'],
      contactEmail: json['contact_email'],
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'clinic_id': clinicId,
    'name': name,
    'coverage_percentage': coveragePercentage,
    'contact_phone': contactPhone,
    'contact_email': contactEmail,
    'notes': notes,
    'is_active': isActive,
  };
}
