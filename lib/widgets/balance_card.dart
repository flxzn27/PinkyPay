import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final String userName;

  const BalanceCard({
    Key? key,
    required this.balance,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.white,
                child: Icon(
                  Icons.person,
                  color: AppColors.primaryPink,
                  size: 24,
                ),
              ),
              Text(
                formatter.format(balance),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 40),
          Text(
            'Current Balance',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkPurple.withOpacity(0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 8),
          Text(
            formatter.format(balance),
            style: TextStyle(
              fontSize: 32,
              color: AppColors.darkPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}