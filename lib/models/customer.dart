import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 0)
class Customer extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String? address;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  double bottleRate;

  @HiveField(7)
  int bottlesPerMonth;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    required this.createdAt,
    this.isActive = true,
    required this.bottleRate,
    required this.bottlesPerMonth,
  });

  double get monthlyCharge => bottleRate * bottlesPerMonth;
}
