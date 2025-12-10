import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';
import '../../services/transaction_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/pinky_popup.dart';
import '../profile/create_pin_screen.dart';
import '../root/main_screen.dart'; // [1] Import MainScreen

class SplitBillListScreen extends StatefulWidget {
  const SplitBillListScreen({super.key});

  @override
  State<SplitBillListScreen> createState() => _SplitBillListScreenState();
}

class _SplitBillListScreenState extends State<SplitBillListScreen> {
  final TransactionService _transactionService = TransactionService();
  final NotificationService _notifService = NotificationService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;

  Future<void> _validateAndPay(int requestId, String payerId, double amount, String payerName, String note) async {
    final myId = _supabase.auth.currentUser!.id;
    
    // [SAFETY] Gunakan .maybeSingle()
    final myProfile = await _supabase.from('profiles').select().eq('id', myId).maybeSingle();
    
    if (myProfile == null) return;

    final myBalance = (myProfile['balance'] ?? 0).toDouble();

    if (amount > myBalance) {
      if(mounted) PinkyPopUp.show(context, type: PopUpType.error, title: "Saldo Kurang", message: "Top up dulu yuk.");
      return;
    }

    final String? userPin = myProfile['pin']; // Sesuaikan jika nama kolom 'pin_code'
    
    if (userPin == null || userPin.isEmpty) {
      _showCreatePinDialog();
    } else {
      _showEnterPinDialog(userPin, requestId, payerId, amount, payerName, note);
    }
  }

  void _showCreatePinDialog() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePinScreen()));
  }

  void _showEnterPinDialog(String correctPin, int requestId, String payerId, double amount, String payerName, String note) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Masukkan PIN"),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          textAlign: TextAlign.center,
          maxLength: 6,
          decoration: const InputDecoration(counterText: ""),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == correctPin) {
                Navigator.pop(context);
                _processRepayment(requestId, payerId, amount, payerName, note);
              } else {
                Navigator.pop(context);
                PinkyPopUp.show(context, type: PopUpType.error, title: "PIN Salah", message: "Coba lagi.");
              }
            },
            child: const Text("Bayar"),
          ),
        ],
      ),
    );
  }

  Future<void> _processRepayment(int requestId, String payerId, double amount, String payerName, String note) async {
    setState(() => _isLoading = true);
    try {
      await _transactionService.repaySplitBill(
        requestId: requestId,
        payerId: payerId,
        amount: amount,
        note: note,
      );

      final myName = _supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Temanmu';
      await _notifService.sendNotificationToUser(
        targetUserId: payerId,
        title: "Hutang Lunas! 🤑",
        message: "$myName sudah membayar Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amount)} untuk '$note'.",
        type: "transaction",
      );

      if (mounted) {
        PinkyPopUp.show(
          context, 
          type: PopUpType.success, 
          title: "Lunas!", 
          message: "Hutang kamu ke $payerName sudah dibayar.",
          btnText: "Kembali ke Home", // [2] Ubah tombol
          onPressed: () {
            // [3] NAVIGASI KE MAIN SCREEN
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false, 
            );
          },
        );
      }
    } catch (e) {
      if(mounted) PinkyPopUp.show(context, type: PopUpType.error, title: "Gagal", message: "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: const Text("Tagihan Masuk", style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _transactionService.getIncomingSplitRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
                }
                
                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green),
                        const SizedBox(height: 16),
                        const Text("Hore! Tidak ada hutang.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                        Text("Hidup tenang tanpa beban tagihan.", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    
                    final payer = req['payer'] ?? {};
                    final payerName = payer['full_name'] ?? payer['name'] ?? 'Unknown'; 
                    final payerAvatar = payer['avatar_url'];
                    
                    final amount = (req['amount'] ?? 0).toDouble();
                    final note = req['description'] ?? 'Split Bill';
                    final date = DateTime.parse(req['created_at']).toLocal();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.lightPeach,
                                backgroundImage: (payerAvatar != null && payerAvatar != '') ? NetworkImage(payerAvatar) : null,
                                child: (payerAvatar == null || payerAvatar == '')
                                    ? Text(payerName.isNotEmpty ? payerName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink))
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Ditagih oleh $payerName", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                                    Text(DateFormat('dd MMM HH:mm').format(date), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFFFE0E0), borderRadius: BorderRadius.circular(8)),
                                child: const Text("UNPAID", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            ],
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(note, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () => _validateAndPay(req['id'], req['payer_id'], amount, payerName, note),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPink,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text("Bayar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}