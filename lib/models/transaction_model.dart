enum TransactionType { topup, payment, splitPay, receive }

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

  String get typeLabel {
    switch (type) {
      case TransactionType.topup:
        return 'Top Up';
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.splitPay:
        return 'Split Bill';
      case TransactionType.receive:
        return 'Received';
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Translate DB string → enum
    TransactionType getType(String? dbType) {
      switch (dbType) {
        case 'topup':
          return TransactionType.topup;
        case 'transfer_in':
          return TransactionType.receive;
        case 'split_bill':
          return TransactionType.splitPay;
        default:
          return TransactionType.payment;
      }
    }

    // Income or Expense
    bool checkIsIncome(String? dbType) {
      return dbType == 'topup' || dbType == 'transfer_in';
    }

    return TransactionModel(
      id: json['id']?.toString() ?? '',
      type: getType(json['type']?.toString()),
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description']?.toString() ?? 'No Description',
      date: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      recipient: json['related_user_id']?.toString(),
      isIncome: checkIsIncome(json['type']?.toString()),
    );
  }
}
