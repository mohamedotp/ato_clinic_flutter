class TreasuryTransaction {
  final String id;
  final String clinicId;
  final String type; // 'income' | 'expense'
  final double amount;
  final String category;
  final String? description;
  final String? referenceId;
  final String? referenceType;
  final String paymentMethod;
  final String? createdBy;
  final DateTime transactionDate;
  final DateTime createdAt;

  TreasuryTransaction({
    required this.id,
    required this.clinicId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    this.referenceId,
    this.referenceType,
    this.paymentMethod = 'cash',
    this.createdBy,
    required this.transactionDate,
    required this.createdAt,
  });

  factory TreasuryTransaction.fromJson(Map<String, dynamic> json) {
    return TreasuryTransaction(
      id: json['id'],
      clinicId: json['clinic_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] ?? 'other',
      description: json['description'],
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      paymentMethod: json['payment_method'] ?? 'cash',
      createdBy: json['created_by'],
      transactionDate: DateTime.parse(json['transaction_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'clinic_id': clinicId,
    'type': type,
    'amount': amount,
    'category': category,
    'description': description,
    'reference_id': referenceId,
    'reference_type': referenceType,
    'payment_method': paymentMethod,
    'transaction_date': transactionDate.toIso8601String(),
  };

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'card': return 'بطاقة';
      case 'transfer': return 'تحويل';
      case 'insurance': return 'تأمين';
      default: return 'نقدي';
    }
  }
}
