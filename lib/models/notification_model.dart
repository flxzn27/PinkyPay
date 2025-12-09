enum NotificationType { transaction, promo, info, security }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    required this.isRead,
  });

  // Factory untuk convert dari Supabase (JSON) ke Dart Object
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] ?? 'No Title',
      message: json['message'] ?? '',
      date: DateTime.parse(json['created_at']).toLocal(),
      isRead: json['is_read'] ?? false,
      type: _parseType(json['type']),
    );
  }

  // Helper convert String db ke Enum
  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'transaction': return NotificationType.transaction;
      case 'promo': return NotificationType.promo;
      case 'security': return NotificationType.security;
      case 'info':
      default: return NotificationType.info;
    }
  }
}