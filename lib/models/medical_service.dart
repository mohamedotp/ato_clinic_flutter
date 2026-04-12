class MedicalService {
  final String id;
  final String clinicId;
  final String name;
  final String? description;
  final double price;
  final String? duration;
  final String? image;
  final String category;
  final bool isActive;
  final DateTime createdAt;

  MedicalService({
    required this.id,
    required this.clinicId,
    required this.name,
    this.description,
    required this.price,
    this.duration,
    this.image,
    required this.category,
    required this.isActive,
    required this.createdAt,
  });

  factory MedicalService.fromJson(Map<String, dynamic> json) {
    return MedicalService(
      id: json['id'],
      clinicId: json['clinic_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      duration: json['duration'],
      image: json['image'],
      category: json['category'] ?? 'الكل',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinic_id': clinicId,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'image': image,
      'category': category,
      'is_active': isActive,
    };
  }
}
