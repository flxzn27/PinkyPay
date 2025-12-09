import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../config/colors.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/pinky_popup.dart';
import '../profile/create_pin_screen.dart';

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
  final NotificationService _notifService = NotificationService();
  final _supabase = Supabase.instance.client; // Instance Supabase
  
  bool _isLoading = false;
  int _selectedBankIndex = -1;

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
    HapticFeedback.lightImpact();
  }

  // [LOGIKA UTAMA] Cek PIN User & Validasi Input
  Future<void> _checkPinAndProcess() async {
    // 1. Validasi Input Dasar
    if (_selectedBankIndex == -1) {
      PinkyPopUp.show(context, type: PopUpType.warning, title: "Pilih Bank", message: "Pilih bank dulu ya biar tau mau transfer kemana.");
      return;
    }

    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountText.isEmpty) {
      PinkyPopUp.show(context, type: PopUpType.warning, title: "Nominal Kosong", message: "Isi dulu mau top up berapa.");
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount < 10000) {
      PinkyPopUp.show(context, type: PopUpType.warning, title: "Kurang Banyak", message: "Minimal Top Up Rp 10.000 ya.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Ambil Data User Terbaru dari Database (Cek PIN)
      final userId = _supabase.auth.currentUser!.id;
      final userData = await _supabase.from('profiles').select('pin').eq('id', userId).single();
      
      final String? userPin = userData['pin'];

      setState(() => _isLoading = false);

      // 3. Logika Percabangan PIN
      if (userPin == null || userPin.isEmpty) {
        // KASUS A: Belum punya PIN -> Paksa Buat PIN
        _showCreatePinDialog();
      } else {
        // KASUS B: Sudah punya PIN -> Minta Masukkan PIN
        _showEnterPinDialog(userPin, amount);
      }

    } catch (e) {
      setState(() => _isLoading = false);
      PinkyPopUp.show(context, type: PopUpType.error, title: "Error", message: "Gagal mengecek data user.");
    }
  }

  // Dialog A: Arahkan ke Create PIN
  void _showCreatePinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("PIN Belum Ada", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Kamu belum mengatur PIN transaksi. Yuk buat dulu demi keamanan!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              // Pindah ke halaman Create PIN
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const CreatePinScreen())
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
            child: const Text("Buat PIN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Dialog B: Input PIN untuk Validasi
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
            const Text("Konfirmasi transaksi dengan PIN kamu.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              // 4. Cek Kecocokan PIN
              if (pinController.text == correctPin) {
                Navigator.pop(context); // Tutup dialog
                _processTopUp(amount);  // EKSEKUSI TRANSAKSI
              } else {
                Navigator.pop(context);
                PinkyPopUp.show(context, type: PopUpType.error, title: "PIN Salah!", message: "PIN yang kamu masukkan tidak cocok.");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
            child: const Text("Konfirmasi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processTopUp(double amount) async {
    setState(() => _isLoading = true);

    try {
      final selectedBankName = _banks[_selectedBankIndex]['name'];
      
      await Future.delayed(const Duration(seconds: 1)); // Simulasi loading
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

      // Notifikasi Realtime
      await _notifService.createNotification(
        title: "Top Up Berhasil! 💰",
        message: "Saldo Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amount)} berhasil masuk via $selectedBankName.",
        type: "transaction",
      );

      if (mounted) {
        PinkyPopUp.show(
          context,
          type: PopUpType.rich, // Maskot kaya
          title: "Top Up Berhasil!",
          message: "Yey! Saldo kamu nambah nih. Jangan lupa jajan ya!",
          btnText: "Siap!",
          onPressed: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        PinkyPopUp.show(context, type: PopUpType.error, title: "Gagal Top Up", message: "Terjadi kesalahan sistem: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    const Text("Pilih Sumber Dana", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                    const SizedBox(height: 16),
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
                              border: Border.all(color: isSelected ? AppColors.primaryPink : Colors.grey[200]!, width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: bank['color'], shape: BoxShape.circle)),
                                const SizedBox(height: 8),
                                Text(bank['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primaryPink : AppColors.darkPurple)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    const Text("Masukan Nominal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(color: const Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          const Text("Rp", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.greyText)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                              decoration: const InputDecoration(hintText: "0", border: InputBorder.none, isDense: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _quickAmounts.map((amount) {
                        return GestureDetector(
                          onTap: () => _selectQuickAmount(amount),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[300]!)),
                            child: Text(NumberFormat.compact(locale: 'id_ID').format(amount), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkPurple)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // Panggil fungsi cek PIN, bukan langsung top up
                  onPressed: _isLoading ? null : _checkPinAndProcess,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text("Top Up Sekarang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}