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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['full_name'] ?? json['name'] ?? 'No Name',
      email: json['email'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      avatarUrl: json['avatar_url'] ?? '',
    );
  }
}