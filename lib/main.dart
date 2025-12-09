import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'screens/root/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inisialisasi Supabase (KEMBALI KE KEY ASLI KAMU)
  await Supabase.initialize(
    url: 'https://bydxoemtxzbugyurtzju.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5ZHhvZW10eHpidWd5dXJ0emp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMTM2MDcsImV4cCI6MjA3OTg4OTYwN30.qj5stI_Mu3nOI34fj77mbvXNWlbZFgFFLW5A1fR-dzk',
  );

  // 2. Inisialisasi Local Notification
  await NotificationService().init();
  
  // Mengatur Status Bar agar transparan
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const PinkyPayApp());
}

class PinkyPayApp extends StatefulWidget {
  const PinkyPayApp({super.key});

  @override
  State<PinkyPayApp> createState() => _PinkyPayAppState();
}

class _PinkyPayAppState extends State<PinkyPayApp> {
  final _supabase = Supabase.instance.client;
  
  // Variabel untuk menyimpan channel agar bisa ditutup nanti
  RealtimeChannel? _notificationChannel; 

  @override
  void initState() {
    super.initState();
    _setupRealtimeNotificationListener();
  }

  @override
  void dispose() {
    // Matikan listener saat aplikasi ditutup total
    if (_notificationChannel != null) {
      _supabase.removeChannel(_notificationChannel!);
    }
    super.dispose();
  }

  void _setupRealtimeNotificationListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      // Jika user Login
      if (event == AuthChangeEvent.signedIn && session != null) {
        
        // Cek jika sudah ada channel sebelumnya, tutup dulu biar gak double
        if (_notificationChannel != null) {
           _supabase.removeChannel(_notificationChannel!);
        }

        // Mulai dengarkan channel baru
        _notificationChannel = _supabase
            .channel('public:notifications:${session.user.id}')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: session.user.id, 
              ),
              callback: (payload) {               
                final newNotif = payload.newRecord;                                 
                NotificationService().showLocalNotification(
                  newNotif['title'] ?? 'Info Baru', 
                  newNotif['message'] ?? 'Kamu punya notifikasi baru.'
                );
              },
            )
            .subscribe();
      } 
      // Jika user Logout
      else if (event == AuthChangeEvent.signedOut) {
        if (_notificationChannel != null) {
           _supabase.removeChannel(_notificationChannel!);
           _notificationChannel = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pinky Pay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}