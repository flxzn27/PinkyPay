class UserModel {
  final String id;
  final String name;
  final String email;
  final double balance;
  final String avatarUrl;
  final DateTime createdAt;
  final String? pin; 

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.balance,
    this.avatarUrl = '',
    DateTime? createdAt, // ← TAMBAHKAN INI
  }) : createdAt = createdAt ?? DateTime.now(); // ← TAMBAHKAN INI

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    double? balance,
    String? avatarUrl,
    DateTime? createdAt, // ← TAMBAHKAN INI
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt, // ← TAMBAHKAN INI
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'balance': balance,
      'avatarUrl': avatarUrl,
      'created_at': createdAt.toIso8601String(), // ← TAMBAHKAN INI
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['full_name'] ?? json['name'] ?? 'No Name', // ← PERBAIKI INI (sesuaikan dengan DB column)
      email: json['email'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      avatarUrl: json['avatar_url'] ?? '', // ← PERBAIKI INI (sesuaikan dengan DB column)
      createdAt: json['created_at'] != null  // ← TAMBAHKAN INI
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}