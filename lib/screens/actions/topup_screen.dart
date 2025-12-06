import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

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
  final TransactionService _service = TransactionService();
  bool _isLoading = false;
  int _selectedBankIndex = -1;

  // Data Dummy Bank (Bisa diganti asset image nanti)
  final List<Map<String, dynamic>> _banks = [
    {'name': 'BCA', 'color': const Color(0xFF005EB8)},
    {'name': 'Mandiri', 'color': const Color(0xFF003D79)},
    {'name': 'BNI', 'color': const Color(0xFF005E6A)},
    {'name': 'BRI', 'color': const Color(0xFF00529C)},
    {'name': 'Jago', 'color': const Color(0xFFFBBC05)},
    {'name': 'SeaBank', 'color': const Color(0xFFFF5500)},
  ];

  final List<double> _quickAmounts = [50000, 100000, 200000, 500000];

  void _selectQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    HapticFeedback.lightImpact(); // Efek getar halus
  }

  Future<void> _processTopUp() async {
    if (_selectedBankIndex == -1) {
      _showErrorSnackBar('Pilih Bank dulu ya! 🏦');
      return;
    }

    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountText.isEmpty) {
      _showErrorSnackBar('Masukan nominal Top Up 💸');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount < 10000) {
      _showErrorSnackBar('Minimal Top Up Rp 10.000 ya 😉');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedBankName = _banks[_selectedBankIndex]['name'];
      
      // Simulasi delay jaringan biar UX terasa "memproses"
      await Future.delayed(const Duration(seconds: 1));
      await _service.topUp(amount, selectedBankName);

      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.topup,
        amount: amount,
        description: 'Top Up via $selectedBankName',
        date: DateTime.now(),
        isIncome: true,
      );

      widget.onTopUp(amount, true);
      widget.onAddTransaction(transaction);

      if (mounted) {
        _showSuccessDialog(amount, selectedBankName);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Ups, Top Up gagal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(double amount, String bankName) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Top Up Berhasil!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 8),
            Text(
              'Saldo kamu sudah bertambah',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Text(
              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup Sheet
                  Navigator.pop(context); // Kembali ke Home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Mantap! 👍", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Top Up', style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Pilih Sumber Dana",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                    ),
                    const SizedBox(height: 16),
                    
                    // GRID BANK SELECTOR
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _banks.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedBankIndex == index;
                        final bank = _banks[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedBankIndex = index);
                            HapticFeedback.selectionClick();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryPink.withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryPink : Colors.grey[200]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo Bank Placeholder (Circle Color)
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: bank['color'],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  bank['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.primaryPink : AppColors.darkPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                    
                    const Text(
                      "Masukan Nominal",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                    ),
                    const SizedBox(height: 12),
                    
                    // INPUT NOMINAL RAKSASA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text("Rp", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.greyText)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                              decoration: const InputDecoration(
                                hintText: "0",
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // QUICK CHIPS
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _quickAmounts.map((amount) {
                        return GestureDetector(
                          onTap: () => _selectQuickAmount(amount),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              NumberFormat.compact(locale: 'id_ID').format(amount),
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkPurple),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM BUTTON
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processTopUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text("Top Up Sekarang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}