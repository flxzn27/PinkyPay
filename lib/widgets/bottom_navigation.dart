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
    // Total tinggi area navigasi (termasuk bagian tombol yang menonjol ke atas)
    return SizedBox(
      height: 100, 
      child: Stack(
        clipBehavior: Clip.none, // Mengizinkan tombol menonjol keluar
        alignment: Alignment.bottomCenter,
        children: [
          // LAYER 1: Background Putih & Shadow
          _buildBackgroundBar(),

          // LAYER 2: Floating Scan Button (Tombol Raksasa)
          Positioned(
            top: 0, // Posisi menonjol ke atas
            child: _buildGiantScanButton(),
          ),

          // LAYER 3: Ikon Menu Kiri & Kanan
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 80, // Tinggi bar navigasi aktual
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.receipt_long_rounded, 'Activity'),
                  
                  // Spacer kosong di tengah untuk memberi ruang tombol Scan
                  const SizedBox(width: 60), 
                  
                  _buildNavItem(3, Icons.people_rounded, 'Friends'),
                  _buildNavItem(4, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Background Putih Melengkung
  Widget _buildBackgroundBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
    );
  }

  // Widget Tombol Scan Besar (Floating)
  Widget _buildGiantScanButton() {
    return GestureDetector(
      onTap: () => onTap(2), // Index 2 adalah Scan
      child: Container(
        width: 72, // Ukuran lebih besar (sebelumnya 52)
        height: 72,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient, // Tetap menggunakan ciri khas PinkyPay
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPink.withOpacity(0.4), // Efek glowing pink
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            // Shadow putih tipis di sekeliling agar terlihat terpisah dari background
            const BoxShadow(
              color: Colors.white,
              blurRadius: 0,
              spreadRadius: 4, // Border putih "palsu" di sekeliling tombol
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 32, // Ikon diperbesar
        ),
      ),
    );
  }

  // Widget Item Menu Biasa
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = index == currentIndex;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque, // Agar area sentuh lebih luas
      child: SizedBox(
        width: 60, // Lebar area tap
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 4),
              child: Icon(
                icon,
                size: isSelected ? 28 : 24, // Efek zoom halus
                color: isSelected ? AppColors.primaryPink : AppColors.greyText,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryPink : AppColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}