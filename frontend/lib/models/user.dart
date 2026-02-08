class User {
  final int id;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final String? name;
  final String? avatar;
  
  User({
    required this.id,
    required this.email,
    required this.isActive,
    required this.createdAt,
    this.name,
    this.avatar,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      name: json['name'],
      avatar: json['avatar'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
    };
  }
}
