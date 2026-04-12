enum UserRole {
  admin,
  doctor,
  receptionist,
  super_admin,
}

class Profile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final UserRole? role;
  final String? clinicId;

  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.role,
    this.clinicId,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'],
      role: json['role'] != null 
          ? UserRole.values.where((e) => e.name == json['role']).firstOrNull 
          : null,
      clinicId: json['clinic_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role?.name,
      'clinic_id': clinicId,
    };
  }
}
