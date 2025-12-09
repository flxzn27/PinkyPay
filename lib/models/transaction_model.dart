import 'package:flutter/material.dart';

enum TransactionType { 
  topup, 
  payment, 
  splitBill,        // Nalangin (Uang Keluar)
  splitBillPay,     // Bayar Hutang (Uang Keluar)
  splitBillReceive, // [BARU] Terima Pelunasan (Uang Masuk)
  receive           // Terima Uang (Uang Masuk)
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;
  final String? recipient;
  final bool isIncome;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.recipient,
    required this.isIncome,
  });

  // Helper untuk Label di UI
  String get typeLabel {
    switch (type) {
      case TransactionType.topup:
        return 'Top Up';
      case TransactionType.payment:
        return 'Transfer';
      case TransactionType.splitBill:
        return 'Split Bill (Nalangin)';
      case TransactionType.splitBillPay:
        return 'Bayar Hutang';
      case TransactionType.splitBillReceive: // [BARU] Label UI
        return 'Terima Pelunasan';
      case TransactionType.receive:
        return 'Uang Masuk';
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Translate String dari Database ke Enum
    TransactionType getType(String? dbType) {
      switch (dbType) {
        case 'topup':
          return TransactionType.topup;
        case 'transfer_in': 
        case 'received':    
          return TransactionType.receive;
        case 'split_bill': 
          return TransactionType.splitBill; 
        case 'split_bill_pay': 
          return TransactionType.splitBillPay; 
        case 'split_bill_receive': // [BARU] Map dari Database
          return TransactionType.splitBillReceive;
        case 'payment':
        case 'transfer':
        default:
          return TransactionType.payment;
      }
    }

    // Cek apakah uang masuk atau keluar
    bool checkIsIncome(String? dbType) {
      return dbType == 'topup' || 
             dbType == 'transfer_in' || 
             dbType == 'received' || 
             dbType == 'split_bill_receive'; // [BARU] Dianggap Pemasukan
    }

    return TransactionModel(
      id: json['id']?.toString() ?? '',
      type: getType(json['type']?.toString()),
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description']?.toString() ?? 'No Description',
      date: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      recipient: json['related_user_id']?.toString(),
      isIncome: checkIsIncome(json['type']?.toString()),
    );
  }
}