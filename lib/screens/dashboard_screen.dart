import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../widgets/balance_card.dart';
import '../widgets/menu_button.dart';
import '../widgets/transaction_item.dart';
import 'topup_screen.dart';
import 'payment_screen.dart';
import 'split_pay_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel user = UserModel(
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
    balance: 10000,
  );

  List<TransactionModel> transactions = [
    TransactionModel(
      id: '1',
      type: TransactionType.topup,
      amount: 100000,
      description: 'Top Up from Bank BCA',
      date: DateTime.now().subtract(Duration(hours: 2)),
      isIncome: true,
    ),
    TransactionModel(
      id: '2',
      type: TransactionType.payment,
      amount: 50000,
      description: 'Payment to Coffee Shop',
      date: DateTime.now().subtract(Duration(hours: 5)),
      recipient: 'Starbucks',
      isIncome: false,
    ),
    TransactionModel(
      id: '3',
      type: TransactionType.splitPay,
      amount: 30000,
      description: 'Dinner Split with Friends',
      date: DateTime.now().subtract(Duration(days: 1)),
      isIncome: false,
    ),
  ];

  void _updateBalance(double amount, bool isIncome) {
    setState(() {
      if (isIncome) {
        user = user.copyWith(balance: user.balance + amount);
      } else {
        user = user.copyWith(balance: user.balance - amount);
      }
    });
  }

  void _addTransaction(TransactionModel transaction) {
    setState(() {
      transactions.insert(0, transaction);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.greyText,
                        ),
                      ),
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkPurple,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.notifications_outlined),
                      color: AppColors.darkPurple,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            // Balance Card
            BalanceCard(
              balance: user.balance,
              userName: user.name,
            ),

            // Menu Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                            currentBalance: user.balance,
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
                            currentBalance: user.balance,
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
                    backgroundColor: Color(0xFFFFA726),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Inbox feature coming soon!'),
                          backgroundColor: AppColors.darkPurple,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Transaction History
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  TextButton(
                    onPressed: () {},
                    child: Text(
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

            // Transaction List
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppColors.greyText.withValues(alpha: 0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
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
                      padding: EdgeInsets.only(bottom: 20),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        return TransactionItem(
                          transaction: transactions[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}