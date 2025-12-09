import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // [1] Import Plugin Notif
import 'package:permission_handler/permission_handler.dart'; // [2] Import Izin
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Singleton Pattern (Agar instance-nya konsisten di seluruh app)
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ==============================================================================
  // BAGIAN 1: INISIALISASI & SYSTEM NOTIFICATION (POP UP ANDROID)
  // ==============================================================================

  /// Panggil fungsi ini di main.dart sebelum runApp()
  Future<void> init() async {
    // 1. Setting Icon Android (Pastikan file ic_launcher ada di res/mipmap)
    // '@mipmap/ic_launcher' adalah icon bawaan flutter
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // 2. Setting iOS
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    // 3. Initialize Plugin
    await _localNotifications.initialize(settings);
    
    // 4. Minta Izin Notifikasi (Wajib untuk Android 13+)
    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    // Menggunakan package permission_handler
    await Permission.notification.request();
  }

  /// Fungsi Public untuk memunculkan notifikasi sistem (Tring! 🔔)
  /// Dipanggil dari main.dart saat ada data masuk dari Supabase Realtime
  Future<void> showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'pinkypay_channel_id',   // ID Channel (Harus unik)
      'Pinky Pay Notifications', // Nama Channel yang muncul di setting HP
      channelDescription: 'Notifikasi transaksi dan promo aplikasi Pinky Pay',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFFF00B7), // Warna Pink di icon kecil notifikasi
      styleInformation: BigTextStyleInformation(''), // Agar teks panjang bisa dibaca full
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Tampilkan Notifikasi
    await _localNotifications.show(
      DateTime.now().millisecond, // ID unik berdasarkan waktu
      title,
      body,
      details,
    );
  }

  // ==============================================================================
  // BAGIAN 2: SUPABASE DATABASE (LOGIKA LAMA + UPDATE)
  // ==============================================================================

  // 1. STREAM REALTIME
  Stream<List<NotificationModel>> getNotificationsStream() {
    final userId = _supabase.auth.currentUser!.id;

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
  }

  // 2. Tandai Semua Sudah Dibaca
  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  // 3. Tandai Satu Item Sudah Dibaca
  Future<void> markAsRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  // 4. Hapus Notifikasi
  Future<void> deleteNotification(String id) async {
    await _supabase
        .from('notifications')
        .delete()
        .eq('id', id);
  }

  // 5. Kirim Notifikasi ke DIRI SENDIRI (Shortcut)
  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    await sendNotificationToUser(
      targetUserId: userId, 
      title: title, 
      message: message, 
      type: type
    );
  }

  // 6. Kirim Notifikasi ke ORANG LAIN / Target User
  // (Fungsi ini menyimpan ke DB, trigger pop-up akan dihandle oleh Listener di main.dart si penerima)
  Future<void> sendNotificationToUser({
    required String targetUserId,
    required String title,
    required String message,
    required String type,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': targetUserId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': false,
    });
    
  }
}