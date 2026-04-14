class Clinic {
  final String id;
  final String name;
  final String openTime;
  final String closeTime;
  final List<String> holidays;
  final String plan;
  final bool isActive;
  final DateTime? subscriptionEndsAt;
  final String whatsappNumber;
  final String evolutionInstance;

  Clinic({
    required this.id,
    required this.name,
    required this.openTime,
    required this.closeTime,
    required this.holidays,
    this.plan = 'starter',
    this.isActive = true,
    this.subscriptionEndsAt,
    this.whatsappNumber = '',
    this.evolutionInstance = '',
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      openTime: json['open_time'] ?? '09:00',
      closeTime: json['close_time'] ?? '21:00',
      holidays: List<String>.from(json['holidays'] ?? ['الجمعة']),
      plan: json['plan'] ?? 'starter',
      isActive: json['is_active'] ?? true,
      subscriptionEndsAt: json['subscription_ends_at'] != null 
          ? DateTime.parse(json['subscription_ends_at']) 
          : null,
      whatsappNumber: json['whatsapp_number'] ?? '',
      evolutionInstance: json['evolution_instance'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'open_time': openTime,
      'close_time': closeTime,
      'holidays': holidays,
      'plan': plan,
      'is_active': isActive,
      if (subscriptionEndsAt != null) 
        'subscription_ends_at': subscriptionEndsAt!.toIso8601String(),
      'whatsapp_number': whatsappNumber,
      'evolution_instance': evolutionInstance,
    };
  }

  Clinic copyWith({
    String? name,
    String? openTime,
    String? closeTime,
    List<String>? holidays,
    String? plan,
    bool? isActive,
    DateTime? subscriptionEndsAt,
    String? whatsappNumber,
    String? evolutionInstance,
  }) {
    return Clinic(
      id: id,
      name: name ?? this.name,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      holidays: holidays ?? this.holidays,
      plan: plan ?? this.plan,
      isActive: isActive ?? this.isActive,
      subscriptionEndsAt: subscriptionEndsAt ?? this.subscriptionEndsAt,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      evolutionInstance: evolutionInstance ?? this.evolutionInstance,
    );
  }
}
