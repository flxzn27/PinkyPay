import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../models/friend_model.dart';
import '../../services/transaction_service.dart';
import '../../services/friend_service.dart'; // Import Friend Service

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
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;

  // Total orang = Teman + Diri Sendiri (1)
  int get totalPerson => _selectedFriends.length + 1;

  double get splitAmount {
    // Hilangkan karakter non-angka
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
                            Navigator.pop(context); // Tutup sheet biar refresh UI utama
                            _showFriendSelector(); // Buka lagi (trik refresh bottom sheet)
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
                  child: const Text("Selesai", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _processSplitPay() async {
    // 1. Validasi
    final cleanText = _totalAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final totalAmount = double.tryParse(cleanText);

    if (totalAmount == null || totalAmount <= 0) {
      _showErrorSnackBar('Masukan total tagihan dulu ya 🧾');
      return;
    }

    if (_selectedFriends.isEmpty) {
      _showErrorSnackBar('Pilih minimal 1 teman untuk patungan 👥');
      return;
    }

    // Cek saldo (asumsi kita talangin dulu)
    if (totalAmount > widget.currentBalance) {
      _showErrorSnackBar('Saldo kamu kurang untuk nalangin tagihan ini 🙈');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final note = _noteController.text.isEmpty
          ? 'Split Bill with ${_selectedFriends.length} friends'
          : _noteController.text;

      // PANGGIL SERVICE (Bayar Full Amount dari Saldo Sendiri)
      // Logic: Kurangi saldo user sebesar Total Amount
      // Nanti fitur "Request Money" ke teman bisa dikembangkan terpisah
      await _transactionService.paySplitBill(totalAmount, note);

      // Catat transaksi lokal
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.splitPay,
        amount: totalAmount, 
        description: note,
        date: DateTime.now(),
        isIncome: false,
      );

      widget.onSplitPay(totalAmount, false); // false = pengeluaran
      widget.onAddTransaction(transaction);

      if (mounted) {
        _showSuccessDialog(totalAmount, splitAmount);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Gagal memproses: $e');
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

  void _showSuccessDialog(double total, double share) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.lightBlue, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Split Bill Berhasil!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu telah membayar lunas tagihan ini',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            
            // RINCIAN KOTAK
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan', style: TextStyle(color: Colors.grey)),
                      Text(currency.format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Per Orang (${totalPerson}x)', style: const TextStyle(color: Colors.grey)),
                      Text(
                        currency.format(share),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup Sheet
                  Navigator.pop(context); // Kembali ke Dashboard
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
                      onChanged: (val) => setState(() {}), // Refresh kalkulasi
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // BAGIAN PESERTA (PARTICIPANTS)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Peserta Patungan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                Text("${totalPerson} Orang", style: const TextStyle(color: AppColors.greyText)),
              ],
            ),
            const SizedBox(height: 16),

            // LIST PESERTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Diri Sendiri (Selalu ada)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryPink,
                      child: Text("Y", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: const Text("You (Owner)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
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
                onPressed: _isLoading ? null : _processSplitPay,
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}