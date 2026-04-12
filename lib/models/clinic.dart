class Clinic {
  final String id;
  final String name;
  final String openTime;
  final String closeTime;
  final List<String> holidays;

  Clinic({
    required this.id,
    required this.name,
    required this.openTime,
    required this.closeTime,
    required this.holidays,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'],
      name: json['name'] ?? '',
      openTime: json['open_time'] ?? '09:00',
      closeTime: json['close_time'] ?? '21:00',
      holidays: List<String>.from(json['holidays'] ?? ['الجمعة']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'open_time': openTime,
      'close_time': closeTime,
      'holidays': holidays,
    };
  }

  Clinic copyWith({
    String? name,
    String? openTime,
    String? closeTime,
    List<String>? holidays,
  }) {
    return Clinic(
      id: id,
      name: name ?? this.name,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      holidays: holidays ?? this.holidays,
    );
  }
}
