import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 3)
enum PaymentMode {
  @HiveField(0)
  cash,
  @HiveField(1)
  upi,
  @HiveField(2)
  bankTransfer,
  @HiveField(3)
  cheque,
  @HiveField(4)
  other
}

@HiveType(typeId: 2)
class Payment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final PaymentMode mode;

  Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    required this.mode,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'mode': mode.toString(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      mode: PaymentMode.values[int.parse(json['mode'] as String)],
    );
  }
}
