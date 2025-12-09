import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../widgets/bottom_navigation.dart';
import '../tabs/home_screen.dart';
import '../tabs/activity_screen.dart';
import '../tabs/profile_screen.dart';
import '../actions/scan_qr_screen.dart';
import '../actions/friend_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Daftar Halaman Tab (Hanya 4 halaman utama, Scan QR dipisah)
  final List<Widget> _pages = [
    const DashboardScreen(), // Index 0
    const ActivityScreen(),  // Index 1
    const SizedBox(),        // Index 2 (Placeholder kosong untuk Scan)
    const FriendScreen(),    // Index 3 [GANTI] Wallet menjadi FriendScreen
    const ProfileScreen(),   // Index 4
  ];

  void _onItemTapped(int index) {
    // [LOGIKA BARU]
    // Jika tombol tengah (Scan QR - Index 2) ditekan:
    if (index == 2) {
      // Buka ScanQrScreen sebagai halaman penuh (Modal/Page)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanQrScreen()),
      );
      // Jangan update _currentIndex agar tab tidak berpindah
      return;
    }

    // Jika tombol lain, pindah tab seperti biasa
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      // IndexedStack menjaga state halaman agar tidak reload saat pindah tab
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: PinkyPayBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}