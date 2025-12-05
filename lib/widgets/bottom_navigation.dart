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
    return Container(
      height: 85, // Navbar height
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
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        items: [
          _buildNavItem(Icons.home_rounded, 'Home'),
          _buildNavItem(Icons.receipt_long_rounded, 'Activity'),
          
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
          
          _buildNavItem(Icons.account_balance_wallet_rounded, 'Wallet'),
          _buildNavItem(Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Icon(icon, size: 26),
      ),
      activeIcon: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Icon(icon, size: 26),
      ),
      label: label,
    );
  }
}