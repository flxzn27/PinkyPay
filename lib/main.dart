import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // [1] Tambah import ini
import 'config/theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async { // [2] Ubah jadi Future<void> dan async
  WidgetsFlutterBinding.ensureInitialized();
  
  // [3] Inisialisasi Supabase (PASTE URL & KEY ANDA DISINI)
  await Supabase.initialize(
    url: 'https://bydxoemtxzbugyurtzju.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5ZHhvZW10eHpidWd5dXJ0emp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMTM2MDcsImV4cCI6MjA3OTg4OTYwN30.qj5stI_Mu3nOI34fj77mbvXNWlbZFgFFLW5A1fR-dzk',
  );
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const PinkyPayApp());
}

class PinkyPayApp extends StatelessWidget {
  const PinkyPayApp({super.key}); // Gunakan super.key untuk modern flutter

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