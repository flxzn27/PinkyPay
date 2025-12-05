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

class _ActivityScreenState extends State<ActivityScreen> {
  final TransactionService _transactionService = TransactionService();
  
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // All, Income, Expense

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
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

  // Helper untuk menghitung total sesuai filter
  double _calculateTotal() {
    return _filteredTransactions.fold(0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: Column(
        children: [
          // 1. CUSTOM APP BAR & FILTER
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkPurple.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activity',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkPurple,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                
                // Filter Tabs (Capsule Style)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildFilterTab('All'),
                      _buildFilterTab('Income'),
                      _buildFilterTab('Expense'),
                    ],
                  ),
                ),

                // Mini Summary (Optional: Menampilkan total jika ada filter)
                if (!_isLoading && _filteredTransactions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total $_selectedFilter',
                        style: TextStyle(color: AppColors.greyText, fontSize: 14),
                      ),
                      Text(
                        currencyFormat.format(_calculateTotal()),
                        style: TextStyle(
                          color: _selectedFilter == 'Expense' ? Colors.red : AppColors.primaryPink,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 2. TRANSACTION LIST (GROUPED BY DATE)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchTransactions,
                        color: AppColors.primaryPink,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 16, bottom: 24),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _filteredTransactions[index];
                            final bool showDateHeader = index == 0 || 
                                !_isSameDay(transaction.date, _filteredTransactions[index - 1].date);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDateHeader) _buildDateHeader(transaction.date),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4), // Biar item tidak mepet
                                  child: TransactionItem(transaction: transaction),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final bool isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _filterTransactions(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected 
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] 
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.darkPurple : AppColors.greyText,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    String text;
    
    if (_isSameDay(date, now)) {
      text = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      text = 'Yesterday';
    } else {
      text = DateFormat('dd MMM yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.greyText,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPink.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: AppColors.primaryPink.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions found',
            style: TextStyle(
              color: AppColors.darkPurple,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t made any ${_selectedFilter == "All" ? "" : _selectedFilter.toLowerCase()} transactions yet.',
            style: const TextStyle(
              color: AppColors.greyText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}