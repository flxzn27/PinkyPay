import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/transaction_model.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionItem({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  IconData _getIcon() {
    switch (transaction.type) {
      case TransactionType.topup:
        return Icons.add_circle;
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.splitPay:
        return Icons.people;
      case TransactionType.receive:
        return Icons.arrow_downward;
    }
  }

  Color _getIconColor() {
    switch (transaction.type) {
      case TransactionType.topup:
      case TransactionType.receive:
        return AppColors.lightGreen;
      case TransactionType.payment:
        return AppColors.primaryPink;
      case TransactionType.splitPay:
        return AppColors.lightBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.greyLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getIconColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIcon(),
              color: _getIconColor(),
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkPurple,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.greyText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  dateFormatter.format(transaction.date),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.greyText.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.isIncome ? '+' : '-'} ${formatter.format(transaction.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: transaction.isIncome
                  ? Colors.green[600]
                  : AppColors.primaryPink,
            ),
          ),
        ],
      ),
    );
  }
}