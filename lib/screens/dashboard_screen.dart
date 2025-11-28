import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../config/colors.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../widgets/balance_card.dart';
import '../widgets/menu_button.dart';
import '../widgets/transaction_item.dart';
import 'topup_screen.dart';
import 'payment_screen.dart';
import 'split_pay_screen.dart';
import 'auth/login_screen.dart'; // Untuk navigasi logout

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 1. Ubah User jadi nullable (?) karena data belum ada saat aplikasi baru buka
  UserModel? user;
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  // Data transaksi DUMMY (Akan kita ubah jadi Real-time di fase selanjutnya)
  List<TransactionModel> transactions = [
    TransactionModel(
      id: '1',
      type: TransactionType.topup,
      amount: 100000,
      description: 'Hadiah Pengguna Baru',
      date: DateTime.now(),
      isIncome: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Ambil data saat layar dibuka
  }

  // 2. Fungsi Ambil Data Profil dari Supabase
  Future<void> _fetchUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          user = UserModel.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Fungsi Logout
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

  // 4. Fitur Greeting Otomatis (Pagi/Siang/Sore/Malam)
  String get _greeting {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    if (hour < 20) return 'Good Evening,';
    return 'Good Night,';
  }

  // Update Balance Logic (Lokal sementara)
  void _updateBalance(double amount, bool isIncome) {
    if (user == null) return;
    setState(() {
      double newBalance = isIncome 
          ? user!.balance + amount 
          : user!.balance - amount;
      
      user = user!.copyWith(balance: newBalance);
    });
    // Nanti disini kita tambahkan logic save ke database
  }

  void _addTransaction(TransactionModel transaction) {
    setState(() {
      transactions.insert(0, transaction);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan Loading
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.greyLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryPink)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      // 5. Fitur Refresh Indicator (Tarik ke bawah untuk refresh)
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: AppColors.primaryPink,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting, // Greeting dinamis
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.greyText,
                            ),
                          ),
                          Text(
                            user?.name ?? 'User', // Tampilkan Nama Asli
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkPurple,
                            ),
                          ),
                        ],
                      ),
                      
                      // 6. Menu Button Modern (Profile & Logout)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.person_outline, color: AppColors.darkPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'logout') {
                              _logout();
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: AppColors.primaryPink, size: 20),
                                  SizedBox(width: 8),
                                  Text('My Profile'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Logout', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Balance Card
                BalanceCard(
                  balance: user?.balance ?? 0, // Tampilkan Saldo Asli
                  userName: user?.name ?? '',
                ),

                // Menu Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      MenuButton(
                        icon: Icons.add_circle_outline,
                        label: 'Top Up',
                        backgroundColor: AppColors.primaryPink,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TopUpScreen(
                                onTopUp: _updateBalance,
                                onAddTransaction: _addTransaction,
                              ),
                            ),
                          );
                        },
                      ),
                      MenuButton(
                        icon: Icons.arrow_upward,
                        label: 'Send',
                        backgroundColor: AppColors.lightBlue,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                currentBalance: user?.balance ?? 0,
                                onPayment: _updateBalance,
                                onAddTransaction: _addTransaction,
                              ),
                            ),
                          );
                        },
                      ),
                      MenuButton(
                        icon: Icons.people_outline,
                        label: 'Split Pay',
                        backgroundColor: AppColors.darkPurple,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SplitPayScreen(
                                currentBalance: user?.balance ?? 0,
                                onSplitPay: _updateBalance,
                                onAddTransaction: _addTransaction,
                              ),
                            ),
                          );
                        },
                      ),
                      MenuButton(
                        icon: Icons.mail_outline,
                        label: 'Inbox',
                        backgroundColor: const Color(0xFFFFA726),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Inbox feature coming soon!'),
                              backgroundColor: AppColors.darkPurple,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Transaction History Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkPurple,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: AppColors.primaryPink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Transaction List (Menggunakan ListView.builder dengan shrinkWrap agar bisa discroll parentnya)
                transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: AppColors.greyText.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No transactions yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.greyText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        shrinkWrap: true, // Wajib jika di dalam SingleChildScrollView
                        physics: const NeverScrollableScrollPhysics(), // Scroll ikut parent
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          return TransactionItem(
                            transaction: transactions[index],
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}