import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../config/colors.dart';
import '../../models/user_model.dart';
import '../../services/transaction_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  // Data State
  UserModel? user;
  bool _isLoading = true;
  bool _isCardFlipped = false;
  bool _isCardFrozen = false; 
  double _totalIncome = 0;
  double _totalExpense = 0;

  final _supabase = Supabase.instance.client;
  final TransactionService _transactionService = TransactionService();
  
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _fetchWalletData();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final transactions = await _transactionService.getTransactions();
      
      double income = 0;
      double expense = 0;

      for (var trx in transactions) {
        if (trx.isIncome) {
          income += trx.amount;
        } else {
          expense += trx.amount;
        }
      }

      if (mounted) {
        setState(() {
          user = UserModel.fromJson(profileData);
          _totalIncome = income;
          _totalExpense = expense;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading wallet: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleCard() {
    if (_isCardFlipped) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() => _isCardFlipped = !_isCardFlipped);
  }

  void _toggleFreeze() {
    setState(() {
      _isCardFrozen = !_isCardFrozen;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCardFrozen ? "Card Frozen ❄️" : "Card Unfrozen 🔥"),
        backgroundColor: _isCardFrozen ? Colors.blueGrey : Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- [FIXED] APP BAR OVERFLOW ---
            SliverAppBar(
              expandedHeight: 180, // ✅ Dinaikkan jadi 180 (Safe Zone)
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryPink,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0), // ❌ Hapus padding vertical
                      child: Center( // ✅ Gunakan Center agar konten vertikal otomatis di tengah
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible( // ✅ Bungkus dengan Flexible biar teks ga nabrak kalau layar sempit
                              child: Column(
                                mainAxisSize: MainAxisSize.min, // ✅ Penting: Ambil tinggi secukupnya
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'My Wallet', 
                                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Manage your finance', 
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // KARTU VIRTUAL
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Virtual Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                            if (_isCardFrozen) 
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.circular(4)),
                                  child: const Text("FROZEN", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              )
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _toggleCard,
                          icon: Icon(_isCardFlipped ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18),
                          label: Text(_isCardFlipped ? 'Show Front' : 'Show CVV'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primaryPink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _toggleCard,
                      child: _buildFlippableCard(),
                    ),
                  ],
                ),
              ),
            ),

            // QUICK ACTIONS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            _isCardFrozen ? 'Unfreeze' : 'Freeze',
                            _isCardFrozen ? Icons.lock_open_rounded : Icons.lock_rounded,
                            _isCardFrozen ? Colors.green : AppColors.lightBlue,
                            _toggleFreeze,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildQuickAction('Set Limit', Icons.tune_rounded, AppColors.darkPurple, () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Limit akan segera hadir!")));
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildQuickAction('Pin Change', Icons.pin_invoke_rounded, const Color(0xFFFFB74D), () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Ganti PIN demi keamanan akan segera hadir!")));
                        })),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // FINANCE ANALYSIS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Income',
                            _totalIncome,
                            const Color(0xFF4CAF50),
                            Icons.arrow_downward_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Expense',
                            _totalExpense,
                            const Color(0xFFEF5350),
                            Icons.arrow_upward_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // LINKED METHODS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Linked Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                    const SizedBox(height: 16),
                    _buildLinkedCardItem('BCA', '**** 4589', 'B', const Color(0xFF005DAA)),
                    const SizedBox(height: 12),
                    _buildLinkedCardItem('Mandiri', '**** 1121', 'M', const Color(0xFF003D79)),
                    const SizedBox(height: 12),
                    _buildLinkedCardItem('GoPay', 'Link Account', 'G', const Color(0xFF00AED6)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS TETAP SAMA ---
  Widget _buildFlippableCard() {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * math.pi;
        final isBack = angle > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _buildCardBack(),
                )
              : _buildCardFront(),
        );
      },
    );
  }

  Widget _buildCardFront() {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final List<Color> gradientColors = _isCardFrozen
        ? [Colors.grey.shade400, Colors.grey.shade600]
        : [const Color(0xFFFF00B7), const Color(0xFFFF4DC4), const Color(0xFF8B4F91)];

    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isCardFrozen ? Colors.grey : AppColors.primaryPink).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FittedBox( // ✅ FittedBox agar isi kartu tidak overflow di HP kecil
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 320,
          height: 172,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pinky Pay',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 18, fontStyle: FontStyle.italic),
                  ),
                  if (_isCardFrozen) const Icon(Icons.lock_rounded, color: Colors.white)
                  else const Icon(Icons.contactless_rounded, color: Colors.white70, size: 28),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 45, height: 35,
                    decoration: BoxDecoration(
                      color: _isCardFrozen ? Colors.grey.shade300 : const Color(0xFFFFD700).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '**** **** **** 8829',
                    style: TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 3, fontWeight: FontWeight.w600, fontFamily: 'Courier'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Card Holder', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                      Text(user?.name.toUpperCase() ?? 'USER', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Balance', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                      Text(
                        _isCardFrozen ? 'Rp ---' : currencyFormat.format(user?.balance ?? 0), 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isCardFrozen 
              ? [Colors.grey.shade700, Colors.grey.shade800]
              : [const Color(0xFF2E1A30), const Color(0xFF462749)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(width: double.infinity, height: 50, color: Colors.black),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(4))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    alignment: Alignment.center,
                    child: const Text('829', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Text('VISA', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, double amount, Color color, IconData icon) {
    final currencyFormat = NumberFormat.compact(locale: 'id_ID');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppColors.greyText, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Rp ${currencyFormat.format(amount)}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedCardItem(String name, String info, String initial, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 36,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
              Text(info, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.more_horiz_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}