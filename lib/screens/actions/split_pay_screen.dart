import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../models/friend_model.dart';
import '../../services/transaction_service.dart';
import '../../services/friend_service.dart';
// [1] IMPORT BARU
import '../../services/notification_service.dart';
import '../../widgets/pinky_popup.dart';
import '../profile/create_pin_screen.dart';

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
  final TextEditingController _noteController = TextEditingController();
  
  // State Peserta (Diri sendiri + Teman terpilih)
  final List<UserModel> _selectedFriends = [];
  
  // Service
  final TransactionService _transactionService = TransactionService();
  final FriendService _friendService = FriendService();
  final NotificationService _notifService = NotificationService(); // [2] Notif Service
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;

  // Total orang = Teman + Diri Sendiri (1)
  int get totalPerson => _selectedFriends.length + 1;

  double get splitAmount {
    final cleanText = _totalAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final total = double.tryParse(cleanText) ?? 0;
    return totalPerson > 0 ? total / totalPerson : 0;
  }

  // --- LOGIC MEMILIH TEMAN ---
  void _showFriendSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text("Pilih Teman Patungan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<FriendModel>>(
                  future: _friendService.getMyFriends(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
                    }
                    
                    final friends = snapshot.data ?? [];
                    final myId = _supabase.auth.currentUser!.id;

                    if (friends.isEmpty) {
                      return Center(child: Text("Belum ada teman, yuk add dulu!", style: TextStyle(color: Colors.grey[400])));
                    }

                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friendship = friends[index];
                        final isMeSender = friendship.sender?.id == myId;
                        final friendProfile = isMeSender ? friendship.receiver : friendship.sender;
                        
                        if (friendProfile == null) return const SizedBox();

                        // Cek apakah sudah terpilih
                        final isSelected = _selectedFriends.any((f) => f.id == friendProfile.id);

                        return CheckboxListTile(
                          activeColor: AppColors.primaryPink,
                          title: Text(friendProfile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(friendProfile.email),
                          secondary: CircleAvatar(
                            backgroundColor: AppColors.lightPeach,
                            child: Text(friendProfile.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedFriends.add(friendProfile);
                              } else {
                                _selectedFriends.removeWhere((f) => f.id == friendProfile.id);
                              }
                            });
                            Navigator.pop(context); // Tutup sheet
                            _showFriendSelector(); // Buka lagi (Refresh UI Sheet)
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Selesai", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- [LOGIKA 1] VALIDASI & CEK PIN ---
  Future<void> _validateAndProcess() async {
    final cleanText = _totalAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final totalAmount = double.tryParse(cleanText);

    if (totalAmount == null || totalAmount <= 0) {
      PinkyPopUp.show(context, type: PopUpType.warning, title: "Nominal Kosong", message: "Masukan total tagihan dulu ya.");
      return;
    }

    if (_selectedFriends.isEmpty) {
      PinkyPopUp.show(context, type: PopUpType.warning, title: "Sendirian?", message: "Pilih minimal 1 teman untuk patungan.");
      return;
    }

    if (totalAmount > widget.currentBalance) {
      PinkyPopUp.show(context, type: PopUpType.error, title: "Saldo Kurang", message: "Saldo kamu kurang untuk nalangin tagihan ini.");
      return;
    }

    // Cek PIN User
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final userData = await _supabase.from('profiles').select('pin').eq('id', userId).single();
      final String? userPin = userData['pin'];

      setState(() => _isLoading = false);

      if (userPin == null || userPin.isEmpty) {
        _showCreatePinDialog();
      } else {
        _showEnterPinDialog(userPin, totalAmount);
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
        content: const Text("Buat PIN transaksi dulu yuk demi keamanan."),
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
            const Text("Konfirmasi pembayaran tagihan.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: "",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == correctPin) {
                Navigator.pop(context);
                _processSplitPay(amount); // EKSEKUSI
              } else {
                Navigator.pop(context);
                PinkyPopUp.show(context, type: PopUpType.error, title: "PIN Salah", message: "PIN tidak cocok.");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
            child: const Text("Bayar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- [LOGIKA 2] PROSES SPLIT PAY ---
  Future<void> _processSplitPay(double totalAmount) async {
    setState(() => _isLoading = true);

    try {
      final note = _noteController.text.isEmpty
          ? 'Split Bill with ${_selectedFriends.length} friends'
          : _noteController.text;

      // 1. Bayar Full Amount (Kurangi Saldo User Sendiri)
      await _transactionService.paySplitBill(totalAmount, note);

      // Hitung tagihan per orang
      final amountPerPerson = splitAmount; 
      final myName = _supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Temanmu';

      // 2. LOOPING KE SETIAP TEMAN
      for (var friend in _selectedFriends) {
        
        // A. Catat Hutang di Database (Agar nanti bisa ditagih/dibayar)
        await _transactionService.createSplitRequest(
          debtorId: friend.id,
          amount: amountPerPerson,
          note: note,
        );

        // B. Kirim Notifikasi ke HP Teman (Realtime!)
        // Format Rupiah
        final formattedAmount = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amountPerPerson);
        
        await _notifService.sendNotificationToUser(
          targetUserId: friend.id, // ID Teman
          title: "Tagihan Split Bill 🧾",
          message: "$myName menalangin $formattedAmount untuk '$note'. Yuk segera bayar!",
          type: "promo", // Kita pakai ikon promo (oranye) atau info (biru) biar eye-catching
        );
      }

      // 3. Catat Transaksi Lokal (History User Sendiri)
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.splitBill, // Gunakan Tipe Baru
        amount: totalAmount, 
        description: "$note (with ${_selectedFriends.length} friends)",
        date: DateTime.now(),
        isIncome: false,
      );

      widget.onSplitPay(totalAmount, false);
      widget.onAddTransaction(transaction);

      // 4. Notifikasi ke Diri Sendiri (Konfirmasi Sukses)
      await _notifService.createNotification(
        title: "Split Bill Berhasil ✅",
        message: "Kamu menalangi Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(totalAmount)}. Tagihan sudah dikirim ke teman-teman.",
        type: "transaction",
      );

      if (mounted) {
        // Tampilkan Maskot Sukses
        PinkyPopUp.show(
          context,
          type: PopUpType.success,
          title: "Berhasil Dibayar!",
          message: "Tagihan sudah lunas. Teman-temanmu akan diberitahu.",
          btnText: "Sip!",
          onPressed: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        PinkyPopUp.show(context, type: PopUpType.error, title: "Gagal", message: "Terjadi kesalahan: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Split Bill', style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
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
            // INPUT TOTAL TAGIHAN
            const Text("Total Tagihan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.greyText)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      controller: _totalAmountController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() {}), // Refresh kalkulasi realtime
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                      decoration: const InputDecoration(
                        hintText: "0",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // INPUT CATATAN
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Untuk pembayaran apa? (Contoh: Makan Siang)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryPink),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
            ),

            const SizedBox(height: 32),

            // BAGIAN PESERTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Peserta Patungan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                Text("${totalPerson} Orang", style: const TextStyle(color: AppColors.greyText)),
              ],
            ),
            const SizedBox(height: 16),

            // LIST PESERTA & SHARE CALCULATION
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Diri Sendiri (Payer)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryPink,
                      child: Text("Y", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: const Text("You (Payer)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                    trailing: Text(
                      currencyFormatter.format(splitAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                    ),
                  ),
                  const Divider(),
                  
                  // Teman Terpilih
                  ..._selectedFriends.map((friend) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.lightPeach,
                      child: Text(friend.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormatter.format(splitAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _selectedFriends.remove(friend)),
                          child: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                        )
                      ],
                    ),
                  )),

                  // Tombol Tambah Teman
                  InkWell(
                    onTap: _showFriendSelector,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, color: AppColors.lightBlue, size: 20),
                          SizedBox(width: 8),
                          Text("Tambah Teman", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightBlue)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // BUTTON BAYAR
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                // Panggil Validasi PIN dulu
                onPressed: _isLoading ? null : _validateAndProcess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: AppColors.primaryPink.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Bayar & Bagi Tagihan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
    _noteController.dispose();
    super.dispose();
  }
}