class LabOrder {
  final String id;
  final String clinicId;
  final String patientId;
  final String? visitId;
  final String? doctorId;
  final DateTime orderDate;
  final String status;
  final String? notes;
  final double totalCost;
  final DateTime createdAt;

  // Joined
  final String? patientName;
  final String? doctorName;
  final List<LabOrderItem> items;

  LabOrder({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.visitId,
    this.doctorId,
    required this.orderDate,
    this.status = 'pending',
    this.notes,
    this.totalCost = 0,
    required this.createdAt,
    this.patientName,
    this.doctorName,
    this.items = const [],
  });

  factory LabOrder.fromJson(Map<String, dynamic> json) {
    return LabOrder(
      id: json['id'],
      clinicId: json['clinic_id'],
      patientId: json['patient_id'],
      visitId: json['visit_id'],
      doctorId: json['doctor_id'],
      orderDate: DateTime.parse(json['order_date']),
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      patientName: json['patients']?['full_name'],
      doctorName: json['profiles']?['full_name'],
      items: json['lab_order_items'] != null
          ? (json['lab_order_items'] as List).map((e) => LabOrderItem.fromJson(e)).toList()
          : [],
    );
  }

  String get statusLabel {
    switch (status) {
      case 'in_progress': return 'قيد التنفيذ';
      case 'completed': return 'مكتملة';
      case 'cancelled': return 'ملغاة';
      default: return 'في الانتظار';
    }
  }

  int get completedCount => items.where((i) => i.status == 'completed').length;
}

class LabOrderItem {
  final String id;
  final String orderId;
  final String? testId;
  final String testName;
  final double testPrice;
  final String? result;
  final String? resultValue;
  final String? normalRange;
  final String? unit;
  final String status;
  final DateTime? resultDate;
  final String? notes;

  LabOrderItem({
    required this.id,
    required this.orderId,
    this.testId,
    required this.testName,
    this.testPrice = 0,
    this.result,
    this.resultValue,
    this.normalRange,
    this.unit,
    this.status = 'pending',
    this.resultDate,
    this.notes,
  });

  factory LabOrderItem.fromJson(Map<String, dynamic> json) {
    return LabOrderItem(
      id: json['id'],
      orderId: json['order_id'],
      testId: json['test_id'],
      testName: json['test_name'],
      testPrice: (json['test_price'] as num?)?.toDouble() ?? 0,
      result: json['result'],
      resultValue: json['result_value'],
      normalRange: json['normal_range'],
      unit: json['unit'],
      status: json['status'] ?? 'pending',
      resultDate: json['result_date'] != null ? DateTime.parse(json['result_date']) : null,
      notes: json['notes'],
    );
  }
}

class LabTest {
  final String id;
  final String clinicId;
  final String name;
  final String? code;
  final String category;
  final String? normalRange;
  final String? unit;
  final double price;
  final int turnaroundHours;
  final bool isActive;

  LabTest({
    required this.id,
    required this.clinicId,
    required this.name,
    this.code,
    this.category = 'general',
    this.normalRange,
    this.unit,
    this.price = 0,
    this.turnaroundHours = 24,
    this.isActive = true,
  });

  factory LabTest.fromJson(Map<String, dynamic> json) {
    return LabTest(
      id: json['id'],
      clinicId: json['clinic_id'],
      name: json['name'],
      code: json['code'],
      category: json['category'] ?? 'general',
      normalRange: json['normal_range'],
      unit: json['unit'],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      turnaroundHours: json['turnaround_hours'] ?? 24,
      isActive: json['is_active'] ?? true,
    );
  }
}
