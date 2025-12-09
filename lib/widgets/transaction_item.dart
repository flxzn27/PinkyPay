import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/transaction_model.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionItem({
    super.key, 
    required this.transaction,
  });

  // [UPDATE] Mapping Ikon untuk SEMUA Tipe Transaksi
  IconData _getIcon() {
    switch (transaction.type) {
      case TransactionType.topup:
        return Icons.add_circle_outline_rounded;
        
      case TransactionType.payment:
        return Icons.payment_rounded;
        
      case TransactionType.splitBill: // Nalangin (Keluar)
        return Icons.call_split_rounded;
        
      case TransactionType.splitBillPay: // Bayar Hutang (Keluar)
        return Icons.check_circle_outline_rounded;
        
      case TransactionType.splitBillReceive: // Terima Pelunasan (Masuk)
        return Icons.savings_rounded; // Ikon celengan/tabungan
        
      case TransactionType.receive: // Transfer Masuk
        return Icons.arrow_downward_rounded;
    }
  }

  // [UPDATE] Mapping Warna Ikon
  Color _getIconColor() {
    switch (transaction.type) {
      // KELOMPOK PEMASUKAN (HIJAU)
      case TransactionType.topup:
      case TransactionType.receive:
      case TransactionType.splitBillReceive:
        return AppColors.lightGreen; 
      
      // KELOMPOK PENGELUARAN UMUM (MERAH/PINK)
      case TransactionType.payment:
        return AppColors.primaryPink; 
      
      // KELOMPOK SPLIT BILL (ORANYE & UNGU)
      case TransactionType.splitBill:
        return Colors.orange; 
      
      case TransactionType.splitBillPay:
        return AppColors.darkPurple; 
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.greyLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getIconColor().withOpacity(0.1), 
              borderRadius: BorderRadius.circular(14), 
            ),
            child: Icon(
              _getIcon(),
              color: _getIconColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeLabel, // Label Dinamis dari Model
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // Agar teks panjang aman
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.greyText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormatter.format(transaction.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.greyText.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Amount Text
          Text(
            '${transaction.isIncome ? '+' : '-'} ${formatter.format(transaction.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: transaction.isIncome
                  ? Colors.green[600] // Hijau jika Pemasukan
                  : AppColors.primaryPink, // Merah jika Pengeluaran
            ),
          ),
        ],
      ),
    );
  }
}