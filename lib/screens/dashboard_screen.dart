import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_item.dart';
import '../services/transaction_service.dart';
import 'topup_screen.dart';
import 'payment_screen.dart';
import 'split_pay_screen.dart';
import 'auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Data State
  UserModel? user;
  List<TransactionModel> transactions = [];
  bool _isLoading = true;
  
  // Dependencies
  final _supabase = Supabase.instance.client;
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 1. Ambil Data User & Transaksi Real-time
  Future<void> _fetchUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      // ⬇⬇⬇ TAMBAHKAN DI SINI
      print("📱 DEBUG: CURRENT USER ID = $userId");
      if (userId == null) return;

      // PERBAIKAN DISINI: Tambahkan <dynamic> agar Dart tidak bingung
      final results = await Future.wait<dynamic>([
       _supabase.from('profiles').select().eq('id', userId).maybeSingle(),
        _transactionService.getTransactions(),
      ]);

      // Parsing Hasil
     final profileData = results[0] as Map<String, dynamic>?;

      if (profileData == null) {
        debugPrint("⚠️ Profile tidak ditemukan untuk userId: $userId");
        if (mounted) {
          setState(() {
            user = null;
            transactions = [];
            _isLoading = false;
          });
        }
        return;
      }

      final transactionData = results[1] as List<TransactionModel>;

      if (mounted) {
        setState(() {
          user = UserModel.fromJson(profileData);
          transactions = transactionData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Logika Logout
  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // 3. Greeting Otomatis
  String get _greeting {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    if (hour < 20) return 'Good Evening,';
    return 'Good Night,';
  }

  // Callback Update Saldo Lokal
  void _updateBalance(double amount, bool isIncome) {
    if (user == null) return;
    setState(() {
      double newBalance = isIncome 
          ? user!.balance + amount 
          : user!.balance - amount;
      user = user!.copyWith(balance: newBalance);
    });
    // Refresh data asli di background
    _fetchUserData();
  }

  void _addTransaction(TransactionModel transaction) {
    // Refresh data total dari server
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    // Format Rupiah
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0
    );

    // Tampilan Loading
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryPink)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: AppColors.primaryPink,
        child: Stack(
          children: [
            // BACKGROUND UTAMA (PINK CURVED)
            Container(
              height: 300,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // HEADER (Salam & Profile)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting,
                              style: TextStyle(
                                color: AppColors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              user?.name ?? 'User',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        // Tombol Menu Profil / Logout
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.person_outline, color: AppColors.white),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) {
                              if (value == 'logout') _logout();
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'profile',
                                child: Row(children: [Icon(Icons.person, color: AppColors.primaryPink), SizedBox(width: 8), Text("My Profile")]),
                              ),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text("Logout")]),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // BALANCE CARD (KARTU SALDO FLOATING)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkPurple.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Balance',
                              style: TextStyle(
                                color: AppColors.greyText,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.lightPeach,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.wallet, color: AppColors.primaryPink, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currencyFormat.format(user?.balance ?? 0),
                          style: const TextStyle(
                            color: AppColors.darkPurple,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // MENU BUTTONS DALAM CARD (Agar terlihat menyatu)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMenuItem(Icons.add_circle_outline, "Top Up", () => 
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TopUpScreen(onTopUp: _updateBalance, onAddTransaction: _addTransaction)))),
                            _buildMenuItem(Icons.arrow_upward_rounded, "Send", () => 
                              Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(currentBalance: user?.balance ?? 0, onPayment: _updateBalance, onAddTransaction: _addTransaction)))),
                            _buildMenuItem(Icons.group_outlined, "Split", () => 
                              Navigator.push(context, MaterialPageRoute(builder: (_) => SplitPayScreen(currentBalance: user?.balance ?? 0, onSplitPay: _updateBalance, onAddTransaction: _addTransaction)))),
                            _buildMenuItem(Icons.grid_view_rounded, "More", () {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur lainnya segera hadir!")));
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TRANSACTION HISTORY (SHEET STYLE)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkPurple,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Expanded(
                            child: transactions.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long, size: 60, color: AppColors.greyText.withOpacity(0.3)),
                                        const SizedBox(height: 8),
                                        const Text("No transactions yet", style: TextStyle(color: AppColors.greyText)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: transactions.length,
                                    itemBuilder: (context, index) {
                                      return TransactionItem(transaction: transactions[index]);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper Menu
  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.darkPurple,
            ),
          ),
        ],
      ),
    );
  }
}