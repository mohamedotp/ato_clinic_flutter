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

  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.role,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      role: json['role'] != null 
          ? UserRole.values.byName(json['role']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role?.name,
    };
  }
}
