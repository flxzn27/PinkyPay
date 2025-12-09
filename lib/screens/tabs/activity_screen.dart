import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/transaction_model.dart';
import '../../widgets/transaction_item.dart';
import '../../services/transaction_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with SingleTickerProviderStateMixin {
  final TransactionService _transactionService = TransactionService();
  
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // All, Income, Expense
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _fetchTransactions();
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

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _transactionService.getTransactions();
      if (mounted) {
        setState(() {
          _allTransactions = transactions;
          _filterTransactions(_selectedFilter);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading activity: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterTransactions(String filterType) {
    setState(() {
      _selectedFilter = filterType;
      if (filterType == 'All') {
        _filteredTransactions = List.from(_allTransactions);
      } else if (filterType == 'Income') {
        _filteredTransactions = _allTransactions.where((t) => t.isIncome).toList();
      } else if (filterType == 'Expense') {
        _filteredTransactions = _allTransactions.where((t) => !t.isIncome).toList();
      }
    });
  }

  // Calculate statistics
  double _calculateTotal() {
    return _filteredTransactions.fold(0, (sum, item) => sum + item.amount);
  }

  double _calculateIncome() {
    return _allTransactions
        .where((t) => t.isIncome)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double _calculateExpense() {
    return _allTransactions
        .where((t) => !t.isIncome)
        .fold(0, (sum, item) => sum + item.amount);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: RefreshIndicator(
        onRefresh: _fetchTransactions,
        color: AppColors.primaryPink,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // MODERN APP BAR WITH GRADIENT
            SliverAppBar(
              expandedHeight: 200,
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
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.analytics_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Activity',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      'Track your transactions',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // STATISTICS CARDS
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(24),
                child: _isLoading
                    ? const SizedBox()
                    : Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Income',
                              currencyFormat.format(_calculateIncome()),
                              Icons.trending_up_rounded,
                              const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Expense',
                              currencyFormat.format(_calculateExpense()),
                              Icons.trending_down_rounded,
                              const Color(0xFFEF5350),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // FILTER TABS
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildModernFilterTab('All', Icons.list_rounded),
                    _buildModernFilterTab('Income', Icons.arrow_downward_rounded),
                    _buildModernFilterTab('Expense', Icons.arrow_upward_rounded),
                  ],
                ),
              ),
            ),

            // FILTERED TOTAL (if not showing all)
            if (!_isLoading && _selectedFilter != 'All' && _filteredTransactions.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedFilter == 'Income'
                          ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
                          : [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_selectedFilter == 'Income' 
                            ? const Color(0xFF4CAF50) 
                            : const Color(0xFFEF5350)).withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
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
                            'Total $_selectedFilter',
                            style: TextStyle(
                              color: _selectedFilter == 'Income'
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(_calculateTotal()),
                            style: TextStyle(
                              color: _selectedFilter == 'Income'
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFFB71C1C),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _selectedFilter == 'Income'
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: _selectedFilter == 'Income'
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // TRANSACTION LIST HEADER
            if (!_isLoading && _filteredTransactions.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkPurple,
                    ),
                  ),
                ),
              ),

            // TRANSACTION LIST OR LOADING/EMPTY STATE
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      ),
                    ),
                  )
                : _filteredTransactions.isEmpty
                    ? SliverFillRemaining(child: _buildModernEmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final transaction = _filteredTransactions[index];
                            final bool showDateHeader = index == 0 ||
                                !_isSameDay(
                                  transaction.date,
                                  _filteredTransactions[index - 1].date,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDateHeader)
                                  _buildModernDateHeader(transaction.date),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 4,
                                  ),
                                  child: TransactionItem(transaction: transaction),
                                ),
                              ],
                            );
                          },
                          childCount: _filteredTransactions.length,
                        ),
                      ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.greyText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterTab(String label, IconData icon) {
    final bool isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _filterTransactions(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? AppColors.primaryGradient
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.greyText,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.greyText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDateHeader(DateTime date) {
    final now = DateTime.now();
    String text;
    IconData icon;
    Color color;

    if (_isSameDay(date, now)) {
      text = 'Today';
      icon = Icons.today_rounded;
      color = AppColors.primaryPink;
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      text = 'Yesterday';
      icon = Icons.history_rounded;
      color = AppColors.lightBlue;
    } else {
      text = DateFormat('dd MMM yyyy').format(date);
      icon = Icons.calendar_today_rounded;
      color = AppColors.darkPurple;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEmptyState() {
    IconData icon;
    String title;
    String subtitle;
    Color color;

    switch (_selectedFilter) {
      case 'Income':
        icon = Icons.trending_up_rounded;
        title = 'No Income Yet';
        subtitle = 'Start earning by receiving payments!';
        color = const Color(0xFF4CAF50);
        break;
      case 'Expense':
        icon = Icons.trending_down_rounded;
        title = 'No Expenses Yet';
        subtitle = 'Your spending history will appear here.';
        color = const Color(0xFFEF5350);
        break;
      default:
        icon = Icons.receipt_long_rounded;
        title = 'No Transactions Yet';
        subtitle = 'Start your first transaction!';
        color = AppColors.primaryPink;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 80,
              color: color.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkPurple,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.greyText,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}