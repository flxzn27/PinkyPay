import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onTopUp;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.isVisible,
    required this.onToggleVisibility,
    this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      height: 180, // Tinggi yang pas untuk header
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30), // Radius lebih bulat (Modern)
        
        // [1] Shadow Lembut di bawah
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],

        // [2] Background Image dari Canva (card.png)
        image: const DecorationImage(
          image: AssetImage('assets/images/card.png'),
          fit: BoxFit.cover, // Memenuhi seluruh kotak
        ),
      ),
      child: Stack(
        children: [
          // [3] Overlay Gradient Transparan (Agar teks putih terbaca jelas di background apapun)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.1), // Sedikit gelap di kiri atas
                  Colors.transparent,
                  Colors.black.withOpacity(0.2), // Sedikit gelap di kanan bawah
                ],
              ),
            ),
          ),

          // [4] Konten Utama
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Konten di tengah vertikal
              children: [
                // Label Kecil
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded, 
                        color: Colors.white, 
                        size: 14
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Total Balance",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Angka Saldo Besar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Saldo
                    Text(
                      isVisible ? formatter.format(balance) : 'Rp •••••••',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32, // Ukuran Font Besar
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5, // Sedikit rapat biar modern
                      ),
                    ),

                    // Tombol Mata
                    IconButton(
                      onPressed: onToggleVisibility,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: Icon(
                        isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const Spacer(), // Dorong ke bawah

                // Footer: Branding Kecil
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Pinky Pay Premium",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    // Indikator Aktif (Dot Hijau)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: Colors.lightGreenAccent, size: 8),
                          SizedBox(width: 6),
                          Text("Active", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}