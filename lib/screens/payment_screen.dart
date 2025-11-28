import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/transaction_model.dart';

class PaymentScreen extends StatefulWidget {
  final double currentBalance;
  final Function(double, bool) onPayment;
  final Function(TransactionModel) onAddTransaction;

  const PaymentScreen({
    Key? key,
    required this.currentBalance,
    required this.onPayment,
    required this.onAddTransaction,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  void _processPayment() {
    if (_recipientController.text.isEmpty) {
      _showError('Please enter recipient');
      return;
    }

    if (_amountController.text.isEmpty) {
      _showError('Please enter amount');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (amount > widget.currentBalance) {
      _showError('Insufficient balance');
      return;
    }

    // Create transaction
    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.payment,
      amount: amount,
      description: _noteController.text.isEmpty
          ? 'Payment to ${_recipientController.text}'
          : _noteController.text,
      date: DateTime.now(),
      recipient: _recipientController.text,
      isIncome: false,
    );

    // Update balance and add transaction
    widget.onPayment(amount, false);
    widget.onAddTransaction(transaction);

    // Show success
    _showSuccess(amount);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(double amount) {
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
              'Payment Successful!',
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
            SizedBox(height: 8),
            Text(
              'To ${_recipientController.text}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.greyText,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
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
        title: Text('Send Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Balance',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkPurple,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(widget.currentBalance),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkPurple,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Recipient
            Text(
              'Recipient',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _recipientController,
              decoration: InputDecoration(
                hintText: 'Enter recipient name or number',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryPink),
                filled: true,
                fillColor: AppColors.greyLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: 24),

            // Amount
            Text(
              'Amount',
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

            // Note (Optional)
            Text(
              'Note (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a note...',
                filled: true,
                fillColor: AppColors.greyLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: 40),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send),
                    SizedBox(width: 8),
                    Text(
                      'Send Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
    _recipientController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}