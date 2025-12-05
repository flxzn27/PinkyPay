import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'screens/root/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://bydxoemtxzbugyurtzju.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5ZHhvZW10eHpidWd5dXJ0emp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMTM2MDcsImV4cCI6MjA3OTg4OTYwN30.qj5stI_Mu3nOI34fj77mbvXNWlbZFgFFLW5A1fR-dzk',
  );
  
  // Mengatur Status Bar agar transparan dan ikon gelap
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const PinkyPayApp());
}

class PinkyPayApp extends StatelessWidget {
  const PinkyPayApp({super.key});

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