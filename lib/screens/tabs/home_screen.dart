import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../widgets/transaction_item.dart';
import '../../services/transaction_service.dart';
// Import Widget Balance Card
import '../../widgets/balance_card.dart';
// Import Halaman Aksi
import '../actions/topup_screen.dart';
import '../actions/payment_screen.dart';
import '../actions/split_pay_screen.dart';
import '../actions/friend_screen.dart';
import '../auth/login_screen.dart';
// Import Pop Up & Notification
import '../../widgets/pinky_popup.dart';
import '../notification/notification_screen.dart';
// Import Halaman List Tagihan
import '../actions/split_bill_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // Data State
  UserModel? user;
  List<TransactionModel> transactions = [];
  bool _isLoading = true;
  bool _isBalanceVisible = true;

  // Status Notifikasi (Realtime)
  bool _hasUnreadNotifications = false;

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
    fetchUserData();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

  Future<void> fetchUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final results = await Future.wait<dynamic>([
        _supabase.from('profiles').select().eq('id', userId).maybeSingle(),
        _transactionService.getTransactions(),
        _supabase
            .from('notifications')
            .select()
            .eq('user_id', userId)
            .eq('is_read', false)
            .count(),
      ]);

      final profileData = results[0] as Map<String, dynamic>?;

      if (profileData == null) {
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
      final unreadCountResponse = results[2];
      final bool hasNotif = (unreadCountResponse?.count ?? 0) > 0;

      if (mounted) {
        setState(() {
          user = UserModel.fromJson(profileData);
          transactions = transactionData;
          _hasUnreadNotifications = hasNotif;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  void updateBalance(double amount, bool isIncome) {
    if (user == null) return;
    setState(() {
      double newBalance =
          isIncome ? user!.balance + amount : user!.balance - amount;
      user = user!.copyWith(balance: newBalance);
    });

    PinkyPopUp.show(
      context,
      type: PopUpType.success,
      title: "Berhasil!",
      message: isIncome ? "Saldo berhasil ditambahkan" : "Pembayaran berhasil",
    );

    fetchUserData();
  }

  void addTransaction(TransactionModel transaction) {
    fetchUserData();
  }

  void _showSplitBillOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Menu Patungan (Split Bill)",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkPurple)),
              const SizedBox(height: 24),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SplitPayScreen(
                              currentBalance: user?.balance ?? 0,
                              onSplitPay: updateBalance,
                              onAddTransaction: addTransaction)));
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.lightBlue.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child:
                      const Icon(Icons.add_rounded, color: AppColors.lightBlue),
                ),
                title: const Text("Buat Tagihan Baru",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Talangin teman-temanmu"),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SplitBillListScreen()));
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Colors.orange),
                ),
                title: const Text("Tagihan Masuk",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Bayar hutang ke teman"),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        onRefresh: fetchUserData,
        color: AppColors.primaryPink,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // APP BAR
            SliverAppBar(
              // [FIX UTAMA] Naikkan tinggi App Bar agar BalanceCard muat
              expandedHeight: 420,
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
                                        color: Colors.white.withOpacity(0.9),
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
                                // Tombol Notifikasi
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationScreen()),
                                    );
                                    if (mounted) {
                                      fetchUserData();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(Icons.notifications_rounded,
                                            color: Colors.white, size: 26),
                                        if (_hasUnreadNotifications)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                  color: Colors.redAccent,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color:
                                                          AppColors.primaryPink,
                                                      width: 1.5),
                                                  boxShadow: [
                                                    const BoxShadow(
                                                        color: Colors.black26,
                                                        blurRadius: 2)
                                                  ]),
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Balance Card
                            BalanceCard(
                              balance: user?.balance ?? 0,
                              isVisible: _isBalanceVisible,
                              onToggleVisibility: () {
                                setState(() {
                                  _isBalanceVisible = !_isBalanceVisible;
                                });
                              },
                              onTopUp: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => TopUpScreen(
                                            onTopUp: updateBalance,
                                            onAddTransaction: addTransaction)));
                              },
                              onTransfer: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaymentScreen(
                                      currentBalance: user?.balance ?? 0,
                                      onPayment: updateBalance,
                                      onAddTransaction: addTransaction,
                                    ),
                                  ),
                                );
                              },
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
                margin:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.08),
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
                          color: AppColors.darkPurple),
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
                                      onTopUp: updateBalance,
                                      onAddTransaction: addTransaction))),
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
                                      onPayment: updateBalance,
                                      onAddTransaction: addTransaction))),
                        ),
                        _buildModernMenuItem(
                          icon: Icons.call_split_rounded,
                          label: "Split Bill",
                          color: AppColors.darkPurple,
                          onTap: _showSplitBillOptions,
                        ),
                        _buildModernMenuItem(
                          icon: Icons.person_add_rounded,
                          label: "Add Friend",
                          color: const Color(0xFFFFB74D),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FriendScreen())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // PROMO BANNER
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
                        color: AppColors.primaryPink.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.card_giftcard_rounded,
                          color: AppColors.primaryPink, size: 32),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Special Promo! 🎉',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkPurple)),
                          SizedBox(height: 4),
                          Text('Get cashback up to 20%',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.greyText)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppColors.primaryPink, size: 20),
                  ],
                ),
              ),
            ),

            // HISTORY HEADER
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Transactions',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkPurple)),
                    Text('See All',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPink)),
                  ],
                ),
              ),
            ),

            // TRANSACTION LIST
            transactions.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                                color: AppColors.greyLight,
                                shape: BoxShape.circle),
                            child: Icon(Icons.receipt_long_rounded,
                                size: 64,
                                color: AppColors.greyText.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 16),
                          const Text("No transactions yet",
                              style: TextStyle(
                                  color: AppColors.greyText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          const Text("Start your first transaction!",
                              style: TextStyle(
                                  color: AppColors.greyText, fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                          child:
                              TransactionItem(transaction: transactions[index]),
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
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
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
                color: AppColors.darkPurple),
          ),
        ],
      ),
    );
  }
}
