class UserModel {
  final String id;
  final String name;
  final String email;
  final double balance;
  final String avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt; // [BARU] Tambahkan ini
  final String? pin; 

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.balance,
    this.avatarUrl = '',
    DateTime? createdAt,
    this.updatedAt, // [BARU]
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
    DateTime? updatedAt, // [BARU]
    String? pin, 
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, // [BARU]
      pin: pin ?? this.pin, 
    );
  }

  // ToJson untuk kirim ke Database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name, // Ingat, Supabase mungkin pakai 'full_name' di DB, tapi model ini internal app
      'email': email,
      'balance': balance,
      'avatar_url': avatarUrl, 
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(), // [BARU]
      'pin': pin, 
    };
  }

  // FromJson untuk ambil dari Database
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '', 
      // Prioritas baca 'full_name', fallback ke 'name'
      name: json['full_name'] ?? json['name'] ?? 'No Name', 
      email: json['email'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),     
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'] ?? '', 
      
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      
      // [BARU] Parsing updated_at
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
          
      pin: json['pin'], 
    );
  }
}