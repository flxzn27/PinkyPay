import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart'; 

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService(); // Panggil Service

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkPurple),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
               _service.markAllAsRead();
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua ditandai sudah dibaca")));
            },
            icon: const Icon(Icons.done_all_rounded, color: AppColors.primaryPink),
            tooltip: "Mark all as read",
          ),
        ],
      ),
      // MENGGUNAKAN STREAM BUILDER (REALTIME)
      body: StreamBuilder<List<NotificationModel>>(
        stream: _service.getNotificationsStream(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. Empty State
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          // 4. Data Ada -> Tampilkan List
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              
              // Helper Group Header Tanggal
              bool showHeader = true;
              if (index > 0) {
                final prevItem = notifications[index - 1];
                if (_getDateHeader(item.date) == _getDateHeader(prevItem.date)) {
                  showHeader = false;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                      child: Text(
                        _getDateHeader(item.date),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  
                  Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _service.deleteNotification(item.id), // Hapus Realtime
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5E5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 28),
                    ),
                    child: _buildNotificationItem(item),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel item) {
    return GestureDetector(
      onTap: () {
        if (!item.isRead) {
          _service.markAsRead(item.id); // Update Realtime jadi Read
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFFFF0F5), // Pink muda jika belum dibaca
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: item.isRead 
              ? Border.all(color: Colors.transparent)
              : Border.all(color: AppColors.primaryPink.withOpacity(0.3), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getIconColor(item.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(item.type), color: _getIconColor(item.type), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: item.isRead ? AppColors.darkPurple : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(item.date),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500),
                      ),
                      if (!item.isRead)
                         Container(margin: const EdgeInsets.only(left: 8), width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryPink, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: AppColors.primaryPink.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_off_rounded, size: 60, color: AppColors.primaryPink),
          ),
          const SizedBox(height: 24),
          const Text("Belum ada notifikasi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
          const SizedBox(height: 8),
          const Text("Tenang, nanti kalau ada kabar\npasti dikabarin kok!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) return 'Today';
    if (notificationDate == yesterday) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(date);
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.transaction: return Icons.account_balance_wallet_rounded;
      case NotificationType.promo: return Icons.local_offer_rounded;
      case NotificationType.security: return Icons.security_rounded;
      case NotificationType.info: return Icons.info_rounded;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.transaction: return Colors.green;
      case NotificationType.promo: return Colors.orange;
      case NotificationType.security: return Colors.red;
      case NotificationType.info: return Colors.blue;
    }
  }
}