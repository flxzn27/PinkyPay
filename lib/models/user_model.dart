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
    DateTime? createdAt,
    this.pin,
  }) : createdAt = createdAt ?? DateTime.now();

  // CopyWith untuk update state
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    double? balance,
    String? avatarUrl,
    DateTime? createdAt,
    String? pin, 
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      pin: pin ?? this.pin, 
    );
  }

  // ToJson untuk kirim ke Database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name, // Pastikan di DB kolomnya 'full_name' atau 'name' sesuai setup
      'email': email,
      'balance': balance,
      'avatar_url': avatarUrl, 
      'created_at': createdAt.toIso8601String(),
      'pin': pin, 
    };
  }

  // FromJson untuk ambil dari Database
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '', // Tambah fallback biar ga crash kalau null
      name: json['full_name'] ?? json['name'] ?? 'No Name', 
      email: json['email'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),     
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'] ?? '', 
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      pin: json['pin'], 
    );
  }
}