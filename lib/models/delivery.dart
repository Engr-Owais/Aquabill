import 'package:hive/hive.dart';

part 'delivery.g.dart';

@HiveType(typeId: 1)
class Delivery {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final int bottles;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final double pricePerBottle;

  Delivery({
    required this.id,
    required this.customerId,
    required this.bottles,
    required this.date,
    required this.pricePerBottle,
  });

  double get totalAmount => bottles * pricePerBottle;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'bottles': bottles,
      'date': date.toIso8601String(),
      'pricePerBottle': pricePerBottle,
    };
  }

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      bottles: json['bottles'] as int,
      date: DateTime.parse(json['date'] as String),
      pricePerBottle: (json['pricePerBottle'] as num).toDouble(),
    );
  }
}
