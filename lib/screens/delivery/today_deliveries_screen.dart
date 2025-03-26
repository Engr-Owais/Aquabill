import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aqua_bill/providers/customer_provider.dart';
import 'package:aqua_bill/providers/delivery_provider.dart';

class TodayDeliveriesScreen extends ConsumerWidget {
  const TodayDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayDeliveries = ref.watch(todayDeliveriesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs');

    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Deliveries')),
      body:
          todayDeliveries.isEmpty
              ? const Center(
                child: Text(
                  'No deliveries made today',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: todayDeliveries.length,
                itemBuilder: (context, index) {
                  final delivery = todayDeliveries[index];
                  final customer = ref
                      .read(customerListProvider)
                      .firstWhere((c) => c.id == delivery.customerId);

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.local_shipping, color: Colors.white),
                    ),
                    title: Text(customer.name),
                    subtitle: Text('${delivery.bottles} bottles'),
                    trailing: Text(
                      currencyFormat.format(delivery.totalAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
