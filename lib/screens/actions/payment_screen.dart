import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart'; // Import Service

class PaymentScreen extends StatefulWidget {
  final double currentBalance;
  final Function(double, bool) onPayment;
  final Function(TransactionModel) onAddTransaction;

  const PaymentScreen({
    super.key,
    required this.currentBalance,
    required this.onPayment,
    required this.onAddTransaction,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  // Service & Loading State
  final TransactionService _service = TransactionService();
  bool _isLoading = false;

  Future<void> _processPayment() async {
    // 1. Validasi Input Dasar
    if (_recipientController.text.isEmpty) {
      _showSnackBar('Please enter recipient email', isError: true);
      return;
    }

    if (_amountController.text.isEmpty) {
      _showSnackBar('Please enter transfer amount', isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text);
    
    // 2. Validasi Nominal
    if (amount == null || amount <= 0) {
      _showSnackBar('Invalid amount entered', isError: true);
      return;
    }

    // 3. Validasi Saldo Cukup
    if (amount > widget.currentBalance) {
      _showSnackBar('Insufficient balance!', isError: true);
      return;
    }

    // 4. Proses Transaksi ke Database
    setState(() => _isLoading = true);

    try {
      // Panggil Service Transfer Supabase
      await _service.transfer(
        recipientEmail: _recipientController.text.trim(),
        amount: amount,
        note: _noteController.text,
      );

      // Buat model transaksi untuk update UI lokal (agar instan)
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.payment,
        amount: amount,
        description: _noteController.text.isEmpty
            ? 'Transfer to ${_recipientController.text}'
            : _noteController.text,
        date: DateTime.now(),
        recipient: _recipientController.text,
        isIncome: false,
      );

      // Update Saldo & History Lokal
      widget.onPayment(amount, false);
      widget.onAddTransaction(transaction);

      // 5. Tampilkan Dialog Sukses
      if (mounted) {
        _showSuccessDialog(amount);
      }
    } catch (e) {
      // Error Handling (Misal: Email penerima tidak ditemukan)
      String errorMessage = e.toString();
      if (errorMessage.contains('Penerima tidak ditemukan')) {
        errorMessage = 'Recipient email not found';
      } else if (errorMessage.contains('Saldo tidak mencukupi')) {
        errorMessage = 'Insufficient balance';
      } else if (errorMessage.contains('diri sendiri')) {
        errorMessage = 'Cannot transfer to yourself';
      }
      
      if (mounted) {
        _showSnackBar(errorMessage, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primaryPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.green, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Transfer Sent!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
              ),
              const SizedBox(height: 10),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryPink),
              ),
              const SizedBox(height: 8),
              Text(
                'To ${_recipientController.text}',
                style: const TextStyle(color: AppColors.greyText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup Dialog
                    Navigator.pop(context); // Kembali ke Dashboard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: const Text('Send Money', style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.darkPurple),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO SALDO (CARD KECIL MODERN)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkPurple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: AppColors.white, size: 28),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 12),
                          ),
                          Text(
                            'Pinky Pay',
                            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    currencyFormatter.format(widget.currentBalance),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // INPUT PENERIMA
            const Text(
              'Recipient Email',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: TextField(
                controller: _recipientController,
                keyboardType: TextInputType.emailAddress, // Keyboard email
                decoration: InputDecoration(
                  hintText: 'e.g. friend@email.com',
                  hintStyle: TextStyle(color: AppColors.greyText.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.alternate_email, color: AppColors.primaryPink),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // INPUT NOMINAL BESAR
            const Text(
              'Transfer Amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.greyText),
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(color: AppColors.greyText),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // INPUT CATATAN
            const Text(
              'Note (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'What is this for?',
                  hintStyle: TextStyle(color: AppColors.greyText.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  icon: const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Icon(Icons.edit_note, color: AppColors.greyText),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // TOMBOL KIRIM DENGAN LOADING
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppColors.primaryPink.withOpacity(0.4),
                  disabledBackgroundColor: AppColors.primaryPink.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Send Now',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}