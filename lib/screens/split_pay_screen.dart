import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/transaction_model.dart';

class SplitPayScreen extends StatefulWidget {
  final double currentBalance;
  final Function(double, bool) onSplitPay;
  final Function(TransactionModel) onAddTransaction;

  const SplitPayScreen({
    Key? key,
    required this.currentBalance,
    required this.onSplitPay,
    required this.onAddTransaction,
  }) : super(key: key);

  @override
  State<SplitPayScreen> createState() => _SplitPayScreenState();
}

class _SplitPayScreenState extends State<SplitPayScreen> {
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _participants = ['You'];
  final TextEditingController _nameController = TextEditingController();

  double get splitAmount {
    final total = double.tryParse(_totalAmountController.text) ?? 0;
    return _participants.length > 0 ? total / _participants.length : 0;
  }

  void _addParticipant() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _participants.add(_nameController.text);
      _nameController.clear();
    });
  }

  void _removeParticipant(int index) {
    if (index == 0) return; // Cannot remove "You"
    setState(() {
      _participants.removeAt(index);
    });
  }

  void _processSplitPay() {
    if (_totalAmountController.text.isEmpty) {
      _showError('Please enter total amount');
      return;
    }

    final totalAmount = double.tryParse(_totalAmountController.text);
    if (totalAmount == null || totalAmount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (_participants.length < 2) {
      _showError('Add at least one more participant');
      return;
    }

    if (splitAmount > widget.currentBalance) {
      _showError('Insufficient balance for your share');
      return;
    }

    // Create transaction
    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.splitPay,
      amount: splitAmount,
      description: _descriptionController.text.isEmpty
          ? 'Split payment with ${_participants.length} people'
          : _descriptionController.text,
      date: DateTime.now(),
      isIncome: false,
    );

    // Update balance and add transaction
    widget.onSplitPay(splitAmount, false);
    widget.onAddTransaction(transaction);

    // Show success
    _showSuccess(totalAmount, splitAmount);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(double total, double yourShare) {
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
              'Split Pay Success!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount:'),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(total),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Split ${_participants.length} ways:'),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(yourShare),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPink,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
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
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Split Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Amount
            Text(
              'Total Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _totalAmountController,
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
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

            // Description
            Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'e.g., Dinner with friends',
                filled: true,
                fillColor: AppColors.greyLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: 24),

            // Participants
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Participants (${_participants.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkPurple,
                  ),
                ),
                if (splitAmount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${formatter.format(splitAmount)} each',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkPurple,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),

            // Add Participant
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter participant name',
                      filled: true,
                      fillColor: AppColors.greyLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, color: AppColors.white),
                    onPressed: _addParticipant,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Participant List
            Container(
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _participants.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index == 0
                          ? AppColors.primaryPink
                          : AppColors.lightBlue,
                      child: Text(
                        _participants[index][0].toUpperCase(),
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      _participants[index],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkPurple,
                      ),
                    ),
                    subtitle: splitAmount > 0
                        ? Text(
                            formatter.format(splitAmount),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.greyText,
                            ),
                          )
                        : null,
                    trailing: index != 0
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () => _removeParticipant(index),
                          )
                        : null,
                  );
                },
              ),
            ),

            SizedBox(height: 40),

            // Split Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _processSplitPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people),
                    SizedBox(width: 8),
                    Text(
                      'Split Payment',
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
    _totalAmountController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}