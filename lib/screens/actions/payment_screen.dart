import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../services/transaction_service.dart';
// [1] IMPORT SERVICE & WIDGET BARU
import '../../services/notification_service.dart';
import '../../widgets/pinky_popup.dart';
import '../profile/create_pin_screen.dart';

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
  final NotificationService _notifService = NotificationService(); // [2] Service Notif
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

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _noteController.dispose();
    _debounce?.cancel();
    super.dispose();
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

  // [LOGIKA UTAMA] Validasi Input & Cek PIN
  Future<void> _validateAndProcess() async {
    // 1. Validasi Input Dasar
    if (_recipientController.text.isEmpty) {
      PinkyPopUp.show(context, type: PopUpType.warning, title: "Email Kosong", message: "Mau kirim ke siapa? Isi email dulu ya!");
      return;
    }

    final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanAmount.isEmpty) {
      PinkyPopUp.show(context, type: PopUpType.warning, title: "Nominal Kosong", message: "Isi dulu mau kirim berapa.");
      return;
    }

    final amount = double.tryParse(cleanAmount);
    if (amount == null || amount < 1000) {
      PinkyPopUp.show(context, type: PopUpType.warning, title: "Kurang Banyak", message: "Minimal transfer Rp 1.000 ya.");
      return;
    }

    if (amount > widget.currentBalance) {
      PinkyPopUp.show(context, type: PopUpType.error, title: "Saldo Kurang", message: "Waduh, saldo kamu nggak cukup nih.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Cek PIN User di Database
      final userId = _supabase.auth.currentUser!.id;
      final userData = await _supabase.from('profiles').select('pin').eq('id', userId).single();
      final String? userPin = userData['pin'];

      setState(() => _isLoading = false);

      // 3. Logika Percabangan PIN
      if (userPin == null || userPin.isEmpty) {
        _showCreatePinDialog();
      } else {
        _showEnterPinDialog(userPin, amount);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      PinkyPopUp.show(context, type: PopUpType.error, title: "Error", message: "Gagal mengecek data user.");
    }
  }

  void _showCreatePinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("PIN Belum Ada"),
        content: const Text("Kamu wajib punya PIN untuk transfer uang. Yuk buat dulu!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePinScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
            child: const Text("Buat PIN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEnterPinDialog(String correctPin, double amount) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Masukkan PIN", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Konfirmasi transfer kamu.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.darkPurple),
              decoration: InputDecoration(
                counterText: "",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == correctPin) {
                Navigator.pop(context);
                _processPayment(amount); // EKSEKUSI TRANSFER
              } else {
                Navigator.pop(context);
                PinkyPopUp.show(context, type: PopUpType.error, title: "PIN Salah", message: "PIN tidak cocok. Transaksi dibatalkan.");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
            child: const Text("Kirim", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(double amount) async {
    setState(() => _isLoading = true);

    try {
      // 1. Panggil Service Transfer
      await _service.transfer(
        recipientEmail: _recipientController.text.trim(),
        amount: amount,
        note: _noteController.text,
      );

      // 2. Buat Model Transaksi Lokal
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

      // 3. Callback ke Home
      widget.onPayment(amount, false);
      widget.onAddTransaction(transaction);

      // 4. Kirim Notifikasi Realtime
      await _notifService.createNotification(
        title: "Transfer Terkirim 💸",
        message: "Kamu berhasil mengirim Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amount)} ke ${_recipientController.text}",
        type: "transaction",
      );

      // 5. Maskot Sukses
      if (mounted) {
        PinkyPopUp.show(
          context,
          type: PopUpType.success,
          title: "Transfer Berhasil!",
          message: "Uang berhasil dikirim ke tujuan.",
          btnText: "Selesai",
          onPressed: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Penerima tidak ditemukan')) {
        errorMessage = 'Email penerima tidak terdaftar.';
      }
      
      if (mounted) {
        PinkyPopUp.show(context, type: PopUpType.error, title: "Gagal Kirim", message: errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  return _searchUsers(textEditingValue.text);
                },
                displayStringForOption: (UserModel option) => option.email,
                onSelected: (UserModel selection) {
                  _recipientController.text = selection.email;
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  // Sinkronisasi controller lokal
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
                        width: MediaQuery.of(context).size.width - 48, 
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
                // Panggil Validasi PIN Dulu
                onPressed: _isLoading ? null : _validateAndProcess,
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
}