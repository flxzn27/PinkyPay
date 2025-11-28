class UserModel {
  final String id;
  final String name;
  final String email;
  final double balance;
  final String avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.balance,
    this.avatarUrl = '',
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    double? balance,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'balance': balance,
      'avatarUrl': avatarUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      balance: json['balance'].toDouble(),
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }
}