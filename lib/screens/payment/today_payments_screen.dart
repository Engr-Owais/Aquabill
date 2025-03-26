import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aqua_bill/providers/customer_provider.dart';
import 'package:aqua_bill/providers/payment_provider.dart';

class TodayPaymentsScreen extends ConsumerWidget {
  const TodayPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayPayments = ref.watch(todayPaymentsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs');

    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Payments')),
      body:
          todayPayments.isEmpty
              ? const Center(
                child: Text(
                  'No payments collected today',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: todayPayments.length,
                itemBuilder: (context, index) {
                  final payment = todayPayments[index];
                  final customer = ref
                      .read(customerListProvider)
                      .firstWhere((c) => c.id == payment.customerId);

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.payment, color: Colors.white),
                    ),
                    title: Text(customer.name),
                    subtitle: Text(payment.mode.toString().split('.').last),
                    trailing: Text(
                      currencyFormat.format(payment.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
