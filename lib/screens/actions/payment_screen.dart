import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../services/transaction_service.dart';

class PaymentScreen extends StatefulWidget {
  final double currentBalance;
  final Function(double, bool) onPayment;
  final Function(TransactionModel) onAddTransaction;
  
  // Parameter Opsional untuk menerima data dari QR Scanner
  final String? initialRecipientEmail;

  const PaymentScreen({
    super.key,
    required this.currentBalance,
    required this.onPayment,
    required this.onAddTransaction,
    this.initialRecipientEmail,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  // Controller untuk Autocomplete (Penerima)
  final TextEditingController _recipientController = TextEditingController();
  
  // Service & Loading State
  final TransactionService _service = TransactionService();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Jika ada data awal dari Scanner, isi otomatis
    if (widget.initialRecipientEmail != null) {
      _recipientController.text = widget.initialRecipientEmail!;
    }
  }

  // Fungsi Pencarian User (Untuk Autocomplete)
  Future<List<UserModel>> _searchUsers(String query) async {
    if (query.length < 3) return []; // Minimal 3 huruf baru cari

    final response = await _supabase
        .from('profiles')
        .select()
        .ilike('email', '%$query%')
        .neq('id', _supabase.auth.currentUser!.id) // Jangan tampilkan diri sendiri
        .limit(5); // Batasi 5 hasil agar rapi

    return (response as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> _processPayment() async {
    // 1. Validasi Input Dasar
    if (_recipientController.text.isEmpty) {
      _showErrorSnackBar('Mau kirim ke siapa? Isi email dulu ya! 📧');
      return;
    }

    // Hilangkan karakter non-angka (Rp, titik, dll)
    final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanAmount.isEmpty) {
      _showErrorSnackBar('Mau kirim berapa? Isi nominalnya dong 💸');
      return;
    }

    final amount = double.tryParse(cleanAmount);
    
    // 2. Validasi Nominal
    if (amount == null || amount < 1000) {
      _showErrorSnackBar('Minimal transfer Rp 1.000 ya 😉');
      return;
    }

    // 3. Validasi Saldo Cukup
    if (amount > widget.currentBalance) {
      _showErrorSnackBar('Waduh, saldo kamu nggak cukup nih 🙈');
      return;
    }

    // 4. Proses Transaksi
    setState(() => _isLoading = true);

    try {
      // Panggil Service Transfer Supabase
      await _service.transfer(
        recipientEmail: _recipientController.text.trim(),
        amount: amount,
        note: _noteController.text,
      );

      // Buat model transaksi lokal
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

      if (mounted) {
        _showSuccessDialog(amount);
      }
    } catch (e) {
      String errorMessage = e.toString();
      // Translate Error Supabase yang umum
      if (errorMessage.contains('Penerima tidak ditemukan') || errorMessage.contains('Row not found')) {
        errorMessage = 'Email penerima tidak terdaftar di PinkyPay 🧐';
      } else if (errorMessage.contains('Saldo tidak mencukupi')) {
        errorMessage = 'Saldo kurang, top up dulu yuk!';
      } else if (errorMessage.contains('diri sendiri')) {
        errorMessage = 'Jangan kirim ke diri sendiri dong 😆';
      }
      
      if (mounted) {
        _showErrorSnackBar(errorMessage);
      }
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

  void _showSuccessDialog(double amount) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Transfer Berhasil!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 8),
            Text(
              'Uang sudah terkirim ke',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              _recipientController.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 24),
            Text(
              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryPink),
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
                child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Kirim Uang', style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO SALDO (CARD GRADIENT)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Kamu',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(widget.currentBalance),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // INPUT PENERIMA (AUTOCOMPLETE)
            const Text(
              'Mau kirim ke siapa?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Autocomplete<UserModel>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<UserModel>.empty();
                  }
                  // Debounce search (tunggu 500ms biar ga spam request)
                  // Note: Di implementasi simple ini kita panggil langsung, 
                  // untuk performa tinggi gunakan rxdart debounce
                  return _searchUsers(textEditingValue.text);
                },
                displayStringForOption: (UserModel option) => option.email,
                onSelected: (UserModel selection) {
                  _recipientController.text = selection.email;
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  // Bind controller lokal ke controller Autocomplete
                  // Agar kita bisa ambil value-nya saat tombol kirim ditekan
                  if (_recipientController.text.isEmpty && controller.text.isNotEmpty) {
                     _recipientController.text = controller.text;
                  }
                  controller.addListener(() {
                    _recipientController.text = controller.text;
                  });

                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: InputDecoration(
                      hintText: 'Ketik email penerima...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryPink),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      child: Container(
                        width: MediaQuery.of(context).size.width - 48, // Sesuaikan lebar
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final UserModel option = options.elementAt(index);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.lightPeach,
                                child: Text(option.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(option.email),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // INPUT NOMINAL
            const Text(
              'Nominal Transfer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Text('Rp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // INPUT CATATAN
            const Text(
              'Catatan (Opsional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Contoh: Bayar makan siang',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // TOMBOL KIRIM
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
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Kirim Sekarang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
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
    _debounce?.cancel();
    super.dispose();
  }
}