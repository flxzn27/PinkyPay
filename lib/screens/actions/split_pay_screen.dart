import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart'; // [1] Import Service

class SplitPayScreen extends StatefulWidget {
  final double currentBalance;
  final Function(double, bool) onSplitPay;
  final Function(TransactionModel) onAddTransaction;

  const SplitPayScreen({
    super.key,
    required this.currentBalance,
    required this.onSplitPay,
    required this.onAddTransaction,
  });

  @override
  State<SplitPayScreen> createState() => _SplitPayScreenState();
}

class _SplitPayScreenState extends State<SplitPayScreen> {
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  final List<String> _participants = ['You']; // Default selalu ada 'You'
  
  // [2] Service & Loading State
  final TransactionService _service = TransactionService();
  bool _isLoading = false;

  double get splitAmount {
    final total = double.tryParse(_totalAmountController.text) ?? 0;
    return _participants.isNotEmpty ? total / _participants.length : 0;
  }

  void _addParticipant() {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Please enter a name', isError: true);
      return;
    }
    setState(() {
      _participants.add(_nameController.text);
      _nameController.clear();
    });
  }

  void _removeParticipant(int index) {
    if (index == 0) return; // Tidak bisa hapus diri sendiri
    setState(() {
      _participants.removeAt(index);
    });
  }

  Future<void> _processSplitPay() async {
    // 1. Validasi Input
    if (_totalAmountController.text.isEmpty) {
      _showSnackBar('Please enter total bill amount', isError: true);
      return;
    }

    final totalAmount = double.tryParse(_totalAmountController.text);
    if (totalAmount == null || totalAmount <= 0) {
      _showSnackBar('Invalid amount', isError: true);
      return;
    }

    if (_participants.length < 2) {
      _showSnackBar('Add at least one friend to split with', isError: true);
      return;
    }

    // Cek saldo (asumsi kita talangin dulu atau bayar bagian kita)
    if (splitAmount > widget.currentBalance) {
      _showSnackBar('Insufficient balance for your share', isError: true);
      return;
    }

    // 2. Mulai Proses Database
    setState(() => _isLoading = true);

    try {
      final note = _descriptionController.text.isEmpty
          ? 'Split Bill with ${_participants.length - 1} friends'
          : _descriptionController.text;

      // PANGGIL SERVICE: Bayar bagian sendiri & Catat di DB
      await _service.paySplitBill(splitAmount, note);

      // Buat model transaksi untuk update UI lokal (agar instan)
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.splitPay,
        amount: splitAmount, 
        description: note,
        date: DateTime.now(),
        isIncome: false,
      );

      // Update Dashboard UI
      widget.onSplitPay(splitAmount, false);
      widget.onAddTransaction(transaction);

      // 3. Tampilkan Sukses
      if (mounted) {
        _showSuccessDialog(totalAmount, splitAmount);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memproses: $e', isError: true);
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

  void _showSuccessDialog(double total, double share) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
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
                  color: AppColors.lightBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.lightBlue, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bill Split Created!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
              ),
              const SizedBox(height: 16),
              // Rincian
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bill'),
                        Text(currency.format(total), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Per Person (${_participants.length})'),
                        Text(
                          currency.format(share),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink),
                        ),
                      ],
                    ),
                  ],
                ),
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
        title: const Text('Split Bill', style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
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
            // CARD INPUT UTAMA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Bill Amount', style: TextStyle(fontSize: 14, color: AppColors.greyText)),
                  TextField(
                    controller: _totalAmountController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() {}), // Update kalkulasi realtime
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.greyText),
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'What is this for? (e.g. Dinner)',
                      border: InputBorder.none,
                      icon: Icon(Icons.edit_note, color: AppColors.primaryPink),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SUMMARY SINGKAT (PITA HASIL)
            if (splitAmount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient, // Pastikan ada di colors.dart
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Each person pays', style: TextStyle(color: AppColors.white)),
                    Text(
                      currencyFormatter.format(splitAmount),
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),

            // ADD PARTICIPANT SECTION
            const Text('Participants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
            const SizedBox(height: 12),
            
            // Input Add Friend
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter friend\'s name',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  onPressed: _addParticipant,
                  backgroundColor: AppColors.darkPurple,
                  elevation: 0,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // LIST PARTICIPANTS
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index == 0 ? AppColors.primaryPink : AppColors.lightBlue.withOpacity(0.3),
                      child: Text(
                        _participants[index][0].toUpperCase(),
                        style: TextStyle(
                          color: index == 0 ? Colors.white : AppColors.darkPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      _participants[index],
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkPurple),
                    ),
                    trailing: index == 0 
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(8)),
                            child: const Text("Owner", style: TextStyle(fontSize: 10, color: AppColors.greyText)),
                          )
                        : IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeParticipant(index),
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // BUTTON SPLIT (DENGAN LOADING)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processSplitPay,
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call_split, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Split Bill Now',
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
    _totalAmountController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}