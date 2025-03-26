import 'package:flutter/material.dart';
import 'package:aqua_bill/models/customer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_bill/providers/delivery_provider.dart';
import 'package:aqua_bill/providers/payment_provider.dart';
import 'package:intl/intl.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final Customer customer;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs');

  CustomerDetailScreen({super.key, required this.customer});

  String _formatNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(customerDeliveriesProvider(customer.id));
    final payments = ref.watch(customerPaymentsProvider(customer.id));

    final totalDelivered = deliveries.fold<int>(
      0,
      (sum, delivery) => sum + delivery.bottles,
    );

    final totalAmount = totalDelivered * customer.bottleRate;
    final totalPaid = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final balance = totalAmount - totalPaid;
    final advancePayment =
        totalPaid > totalAmount ? totalPaid - totalAmount : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit customer screen
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(customer.phone),
                    onTap: () {
                      // TODO: Launch phone dialer
                    },
                  ),
                  if (customer.address != null)
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(customer.address!),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Total Bottles Delivered'),
                    trailing: Text(
                      _formatNumber(totalDelivered.toDouble()),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Total Amount'),
                    trailing: Text(
                      currencyFormat.format(totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Total Paid'),
                    trailing: Text(
                      currencyFormat.format(totalPaid),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Balance'),
                    trailing: Text(
                      currencyFormat.format(balance),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: balance > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Advance Payment'),
                    trailing: Text(
                      currencyFormat.format(advancePayment),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: advancePayment > 0 ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (deliveries.isNotEmpty) ...[
            Text(
              'Recent Deliveries',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deliveries.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final delivery = deliveries[index];
                  return ListTile(
                    title: Text('${delivery.bottles} bottles'),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy').format(delivery.date),
                    ),
                    trailing: Text(
                      'Rs${delivery.bottles * customer.bottleRate}',
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (payments.isNotEmpty) ...[
            Text(
              'Recent Payments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payments.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return ListTile(
                    title: Text(DateFormat('dd MMM yyyy').format(payment.date)),
                    subtitle: Text(currencyFormat.format(payment.amount)),
                    trailing: Text(payment.mode.toString().split('.').last),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
