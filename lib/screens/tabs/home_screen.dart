import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../widgets/transaction_item.dart';
import '../../services/transaction_service.dart';
import '../actions/topup_screen.dart';
import '../actions/payment_screen.dart';
import '../actions/split_pay_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  // Data State
  UserModel? user;
  List<TransactionModel> transactions = [];
  bool _isLoading = true;
  bool _isBalanceVisible = true;
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Dependencies
  final _supabase = Supabase.instance.client;
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _fetchUserData();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 1. Ambil Data User & Transaksi Real-time
  Future<void> _fetchUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      print("📱 DEBUG: CURRENT USER ID = $userId");
      if (userId == null) return;

      final results = await Future.wait<dynamic>([
        _supabase.from('profiles').select().eq('id', userId).maybeSingle(),
        _transactionService.getTransactions(),
      ]);

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
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 20) return 'Good Evening';
    return 'Good Night';
  }

  String get _greetingEmoji {
    var hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    if (hour < 20) return '🌆';
    return '🌙';
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
    _fetchUserData();
  }

  void _addTransaction(TransactionModel transaction) {
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0
    );

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: AppColors.primaryPink,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // MODERN APP BAR
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryPink,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_greeting $_greetingEmoji',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.name ?? 'User',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                // Profile Menu
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: PopupMenuButton<String>(
                                    icon: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    offset: const Offset(0, 50),
                                    onSelected: (value) {
                                      if (value == 'logout') _logout();
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'profile',
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_rounded, color: AppColors.primaryPink),
                                            SizedBox(width: 12),
                                            Text("My Profile"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'settings',
                                        child: Row(
                                          children: [
                                            Icon(Icons.settings_rounded, color: AppColors.lightBlue),
                                            SizedBox(width: 12),
                                            Text("Settings"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'logout',
                                        child: Row(
                                          children: [
                                            Icon(Icons.logout_rounded, color: Colors.red),
                                            SizedBox(width: 12),
                                            Text("Logout"),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Balance Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
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
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isBalanceVisible = !_isBalanceVisible;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.lightPeach,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _isBalanceVisible 
                                                ? Icons.visibility_rounded 
                                                : Icons.visibility_off_rounded,
                                            color: AppColors.primaryPink,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _isBalanceVisible 
                                        ? currencyFormat.format(user?.balance ?? 0)
                                        : 'Rp •••••••',
                                    style: const TextStyle(
                                      color: AppColors.darkPurple,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // MENU QUICK ACTIONS
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkPurple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildModernMenuItem(
                          icon: Icons.add_circle_outline_rounded,
                          label: "Top Up",
                          color: AppColors.primaryPink,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TopUpScreen(
                                onTopUp: _updateBalance,
                                onAddTransaction: _addTransaction,
                              ),
                            ),
                          ),
                        ),
                        _buildModernMenuItem(
                          icon: Icons.arrow_upward_rounded,
                          label: "Send",
                          color: AppColors.lightBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                currentBalance: user?.balance ?? 0,
                                onPayment: _updateBalance,
                                onAddTransaction: _addTransaction,
                              ),
                            ),
                          ),
                        ),
                        _buildModernMenuItem(
                          icon: Icons.group_rounded,
                          label: "Split",
                          color: AppColors.darkPurple,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SplitPayScreen(
                                currentBalance: user?.balance ?? 0,
                                onSplitPay: _updateBalance,
                                onAddTransaction: _addTransaction,
                              ),
                            ),
                          ),
                        ),
                        _buildModernMenuItem(
                          icon: Icons.people_rounded,
                          label: "Friend",
                          color: Color(0xFFFFB74D),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Fitur Friend segera hadir! 👥"),
                                backgroundColor: AppColors.darkPurple,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // PROMO BANNER (Optional)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE5F4), Color(0xFFE8F0FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: AppColors.primaryPink,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Special Promo! 🎉',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkPurple,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Get cashback up to 20%',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primaryPink,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // TRANSACTION HISTORY HEADER
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkPurple,
                      ),
                    ),
                    Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // TRANSACTION LIST
            transactions.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.greyLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 64,
                              color: AppColors.greyText.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No transactions yet",
                            style: TextStyle(
                              color: AppColors.greyText,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Start your first transaction!",
                            style: TextStyle(
                              color: AppColors.greyText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          child: TransactionItem(transaction: transactions[index]),
                        );
                      },
                      childCount: transactions.length,
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // Modern Menu Item Widget
  Widget _buildModernMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkPurple,
            ),
          ),
        ],
      ),
    );
  }
}