import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart'; // Import Service

class TopUpScreen extends StatefulWidget {
  final Function(double, bool) onTopUp;
  final Function(TransactionModel) onAddTransaction;

  const TopUpScreen({
    super.key,
    required this.onTopUp,
    required this.onAddTransaction,
  });

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  
  // Service Instance
  final TransactionService _service = TransactionService();
  bool _isLoading = false;

  // Bank Selection Logic
  int _selectedBankIndex = -1; 
  final List<String> _banks = ['BCA', 'Mandiri', 'BNI', 'BRI', 'Jago', 'SeaBank'];
  
  // Nominal Cepat
  final List<double> _quickAmounts = [50000, 100000, 200000, 500000, 1000000];

  void _selectQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
  }

  Future<void> _processTopUp() async {
    // 1. Validasi Input
    if (_selectedBankIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Bank first'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount'), backgroundColor: Colors.red),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount'), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Mulai Loading & Proses Database
    setState(() => _isLoading = true);

    try {
      final selectedBankName = _banks[_selectedBankIndex];
      
      // Panggil Service (Simpan ke Supabase)
      await _service.topUp(amount, selectedBankName);

      // Buat model transaksi untuk update UI lokal (opsional, biar instan)
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.topup,
        amount: amount,
        description: 'Top Up via $selectedBankName',
        date: DateTime.now(),
        isIncome: true,
      );

      // Update Saldo & History di Dashboard (Callback)
      widget.onTopUp(amount, true);
      widget.onAddTransaction(transaction);

      if (mounted) {
        // Tampilkan Dialog Sukses
        _showSuccessDialog(amount, selectedBankName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Top Up Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(double amount, String bankName) {
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
                'Top Up Success!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
              ),
              const SizedBox(height: 10),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryPink),
              ),
              const SizedBox(height: 8),
              Text(
                'From $bankName',
                style: const TextStyle(color: AppColors.greyText),
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
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: const Text('Top Up Balance', style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
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
            // SECTION 1: PILIH BANK (GRID MODERN)
            const Text(
              'Select Source',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _banks.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedBankIndex == index;
                return InkWell(
                  onTap: () => setState(() => _selectedBankIndex = index),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryPink : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : AppColors.darkPurple.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        if (!isSelected)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _banks[index],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.white : AppColors.darkPurple,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // SECTION 2: INPUT NOMINAL BESAR
            const Text(
              'Enter Amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.greyText),
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(color: AppColors.greyText),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // SECTION 3: QUICK AMOUNT CHIPS
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickAmounts.map((amount) {
                return InkWell(
                  onTap: () => _selectQuickAmount(amount),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.lightGreen),
                    ),
                    child: Text(
                      NumberFormat.compact(locale: 'id_ID').format(amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkPurple,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // SECTION 4: CONFIRM BUTTON DENGAN LOADING
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: AppColors.primaryPink.withOpacity(0.4),
                  disabledBackgroundColor: AppColors.primaryPink.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Top Up Now',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    super.dispose();
  }
}