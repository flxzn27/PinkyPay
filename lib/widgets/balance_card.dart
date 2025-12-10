import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  // Parameter TopUp dan Transfer dibuat opsional namun tetap ada
  final VoidCallback? onTopUp;
  final VoidCallback? onTransfer;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.isVisible,
    required this.onToggleVisibility,
    this.onTopUp,
    this.onTransfer,
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
      // [FIX 1] Tinggi dihapus atau dibuat minHeight agar fleksibel
      // height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),

        // [1] Shadow Lembut
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],

        // [2] Background Image
        image: const DecorationImage(
          image: AssetImage('assets/images/card.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // [3] Overlay Gradient Transparan
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),

          // [4] Konten Utama
          Padding(
            padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 16,
                bottom:
                    20), // [FIX] Padding disesuaikan untuk menghilangkan overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:
                  MainAxisSize.min, // [FIX 3] Agar tinggi menyesuaikan isi
              children: [
                // --- BAGIAN ATAS: Label & Icon ---
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 14),
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

                const SizedBox(height: 20), // Jarak antar elemen

                // --- BAGIAN TENGAH: Saldo Besar ---
                // [FIX 4] Anti Overflow untuk Saldo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Saldo (Menggunakan Expanded & FittedBox)
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown, // Kecilkan font jika mentok
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isVisible ? formatter.format(balance) : 'Rp •••••••',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32, // Font besar
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Tombol Mata
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: onToggleVisibility,
                        padding: const EdgeInsets.all(0),
                        icon: Icon(
                          isVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24), // Jarak ke footer

                // --- BAGIAN BAWAH: Status & Chip ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // [FIX 5] Flexible untuk teks footer
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pinky Pay Premium",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Jika mau menampilkan nomor kartu, bisa uncomment ini
                          // Text("**** 8899", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Indikator Aktif
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                color: Colors.lightGreenAccent, size: 8),
                            SizedBox(width: 4),
                            Text("Active",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
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
