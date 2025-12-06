import 'user_model.dart';

class FriendModel {
  final String id; // ID Friendship
  final String status; // 'pending', 'accepted'
  final String requestDate;
  
  // Data profil teman (bisa jadi pengirim atau penerima)
  final UserModel? sender;
  final UserModel? receiver;

  FriendModel({
    required this.id,
    required this.status,
    required this.requestDate,
    this.sender,
    this.receiver,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] ?? '',
      status: json['status'] ?? 'pending',
      requestDate: json['created_at'] ?? '',
      
      // Mengambil data nested profile jika tersedia
      sender: json['sender'] != null 
          ? UserModel.fromJson(json['sender']) 
          : null,
      receiver: json['receiver'] != null 
          ? UserModel.fromJson(json['receiver']) 
          : null,
    );
  }
}