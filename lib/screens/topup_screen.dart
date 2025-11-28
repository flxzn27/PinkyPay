import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/transaction_model.dart';

class TopUpScreen extends StatefulWidget {
  final Function(double, bool) onTopUp;
  final Function(TransactionModel) onAddTransaction;

  const TopUpScreen({
    Key? key,
    required this.onTopUp,
    required this.onAddTransaction,
  }) : super(key: key);

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedBank = 'BCA';
  final List<String> _banks = ['BCA', 'Mandiri', 'BNI', 'BRI', 'CIMB'];
  final List<double> _quickAmounts = [50000, 100000, 200000, 500000];

  void _selectQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
  }

  void _processTopUp() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create transaction
    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.topup,
      amount: amount,
      description: 'Top Up from Bank $_selectedBank',
      date: DateTime.now(),
      isIncome: true,
    );

    // Update balance and add transaction
    widget.onTopUp(amount, true);
    widget.onAddTransaction(transaction);

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.green[700],
                size: 48,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Top Up Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            SizedBox(height: 8),
            Text(
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(amount),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPink,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Top Up'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Bank
            Text(
              'Select Bank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBank,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.darkPurple),
                  items: _banks.map((String bank) {
                    return DropdownMenuItem<String>(
                      value: bank,
                      child: Text(
                        'Bank $bank',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.darkPurple,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedBank = newValue;
                      });
                    }
                  },
                ),
              ),
            ),

            SizedBox(height: 24),

            // Amount Input
            Text(
              'Enter Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkPurple,
                ),
                filled: true,
                fillColor: AppColors.greyLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: '0',
              ),
            ),

            SizedBox(height: 24),

            // Quick Amount Buttons
            Text(
              'Quick Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _quickAmounts.map((amount) {
                return InkWell(
                  onTap: () => _selectQuickAmount(amount),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.darkPurple.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(amount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkPurple,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 40),

            // Top Up Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _processTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Top Up Now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
    _amountController.dispose();
    super.dispose();
  }
}