class ClinicMaterial {
  final String id;
  final String clinicId;
  final String name;
  final String? description;
  final String unit;
  final double stockQuantity;
  final double? minStockAlert;
  final double costPerUnit;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClinicMaterial({
    required this.id,
    required this.clinicId,
    required this.name,
    this.description,
    required this.unit,
    required this.stockQuantity,
    this.minStockAlert,
    required this.costPerUnit,
    required this.category,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock =>
      minStockAlert != null && stockQuantity <= minStockAlert!;

  factory ClinicMaterial.fromJson(Map<String, dynamic> json) {
    return ClinicMaterial(
      id: json['id'],
      clinicId: json['clinic_id'],
      name: json['name'],
      description: json['description'],
      unit: json['unit'] ?? 'قطعة',
      stockQuantity: (json['stock_quantity'] as num?)?.toDouble() ?? 0.0,
      minStockAlert: (json['min_stock_alert'] as num?)?.toDouble(),
      costPerUnit: (json['cost_per_unit'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'عام',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinic_id': clinicId,
      'name': name,
      'description': description,
      'unit': unit,
      'stock_quantity': stockQuantity,
      'min_stock_alert': minStockAlert,
      'cost_per_unit': costPerUnit,
      'category': category,
      'is_active': isActive,
    };
  }

  ClinicMaterial copyWith({
    String? name,
    String? description,
    String? unit,
    double? stockQuantity,
    double? minStockAlert,
    double? costPerUnit,
    String? category,
    bool? isActive,
  }) {
    return ClinicMaterial(
      id: id,
      clinicId: clinicId,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class MaterialUsage {
  final String id;
  final String clinicId;
  final String? patientId;
  final String materialId;
  final double quantityUsed;
  final String? notes;
  final String? usedBy;
  final DateTime usedAt;
  final String usageType;

  // Joined
  final String? materialName;
  final String? materialUnit;
  final String? usedByName;
  final String? patientName;
  final String? patientPhone;

  MaterialUsage({
    required this.id,
    required this.clinicId,
    this.patientId,
    required this.materialId,
    required this.quantityUsed,
    this.notes,
    this.usedBy,
    required this.usedAt,
    this.usageType = 'patient_use',
    this.materialName,
    this.materialUnit,
    this.usedByName,
    this.patientName,
    this.patientPhone,
  });

  factory MaterialUsage.fromJson(Map<String, dynamic> json) {
    return MaterialUsage(
      id: json['id'],
      clinicId: json['clinic_id'],
      patientId: json['patient_id'],
      materialId: json['material_id'],
      quantityUsed: (json['quantity_used'] as num?)?.toDouble() ?? 1.0,
      notes: json['notes'],
      usedBy: json['used_by'],
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'])
          : DateTime.now(),
      usageType: json['usage_type'] ?? 'patient_use',
      materialName: json['clinic_materials'] != null
          ? json['clinic_materials']['name']
          : null,
      materialUnit: json['clinic_materials'] != null
          ? json['clinic_materials']['unit']
          : null,
      usedByName: json['profiles'] != null
          ? json['profiles']['full_name']
          : null,
      patientName: json['patients'] != null
          ? json['patients']['full_name']
          : null,
      patientPhone: json['patients'] != null
          ? json['patients']['phone']
          : null,
    );
  }
}
