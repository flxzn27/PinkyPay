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
        return 'Split Pay';
      case TransactionType.receive:
        return 'Received';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'recipient': recipient,
      'isIncome': isIncome,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      amount: json['amount'].toDouble(),
      description: json['description'],
      date: DateTime.parse(json['date']),
      recipient: json['recipient'],
      isIncome: json['isIncome'],
    );
  }
}