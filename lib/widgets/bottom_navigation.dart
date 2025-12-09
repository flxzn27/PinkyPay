import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';

class PinkyPayBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PinkyPayBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Menghapus tinggi tetap (height: 85) pada Container, 
    // dan membungkus BottomNavigationBar dengan Padding di dalam SafeArea.
    return Container(
      padding: const EdgeInsets.only(top: 8.0), // Padding di atas bar
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Shadow dibuat lebih lembut
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      // Kita gunakan SafeArea agar BottomNavigationBar tidak terpotong 
      // oleh gesture bar di bagian bawah layar.
      child: SafeArea( 
        top: false, // Jangan tambahkan padding di bagian atas
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primaryPink,
          unselectedItemColor: AppColors.greyText,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700, // Dibuat lebih tebal saat terpilih
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: [
            _buildNavItem(0, Icons.home_rounded, 'Home', currentIndex),
            _buildNavItem(1, Icons.receipt_long_rounded, 'Activity', currentIndex),
            
            // Center Button (PAY / SCAN)
            BottomNavigationBarItem(
              icon: Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              label: 'Scan',
            ),
            
            _buildNavItem(3, Icons.account_balance_wallet_rounded, 'Wallet', currentIndex),
            _buildNavItem(4, Icons.person_rounded, 'Profile', currentIndex),
          ],
        ),
      ),
    );
  }

  // Menyesuaikan _buildNavItem untuk memberikan visual yang berbeda saat aktif
  BottomNavigationBarItem _buildNavItem(int index, IconData icon, String label, int currentIndex) {
    bool isSelected = index == currentIndex;
    return BottomNavigationBarItem(
      icon: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Icon(
          icon, 
          size: isSelected ? 28 : 26, // Dibuat sedikit lebih besar saat aktif
          color: isSelected ? AppColors.primaryPink : AppColors.greyText,
        ),
      ),
      // activeIcon tidak perlu di-override karena warna sudah diatur di selectedItemColor
      label: label,
    );
  }
}