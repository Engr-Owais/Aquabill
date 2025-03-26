import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aqua_bill/models/customer.dart';
import 'package:aqua_bill/models/delivery.dart';
import 'package:aqua_bill/models/payment.dart';
import 'package:aqua_bill/providers/customer_provider.dart';
import 'package:aqua_bill/providers/delivery_provider.dart';
import 'package:aqua_bill/providers/payment_provider.dart';

class AdvancePaymentsScreen extends ConsumerWidget {
  const AdvancePaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customerListProvider);
    final deliveries = ref.watch(deliveryListProvider);
    final payments = ref.watch(paymentListProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs');

    // Calculate advance payments for each customer
    final advancePayments = <String, double>{};
    final customerDeliveries = <String, List<Delivery>>{};

    for (final customer in customers) {
      final customerDeliveryList =
          deliveries
              .where((delivery) => delivery.customerId == customer.id)
              .toList();

      customerDeliveries[customer.id] = customerDeliveryList;

      final totalDeliveryAmount = customerDeliveryList.fold<double>(
        0,
        (sum, delivery) => sum + (delivery.totalAmount),
      );

      final totalPayments = payments
          .where((payment) => payment.customerId == customer.id)
          .fold<double>(0, (sum, payment) => sum + (payment.amount));

      final advanceAmount = totalPayments - totalDeliveryAmount;
      if (advanceAmount > 0) {
        advancePayments[customer.id] = advanceAmount;
      }
    }

    if (advancePayments.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Advance Payments')),
        body: const Center(child: Text('No advance payments')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Advance Payments')),
      body: ListView.builder(
        itemCount: advancePayments.length,
        itemBuilder: (context, index) {
          final customerId = advancePayments.keys.elementAt(index);
          final customer = customers.firstWhere(
            (customer) => customer.id == customerId,
          );
          final advanceAmount = advancePayments[customerId]!;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(customer.name),
              subtitle: Text('Phone: ${customer.phone}'),
              trailing: Text(
                currencyFormat.format(advanceAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 20,
                ),
              ),
              onTap: () {
                _showCustomerDetails(
                  context,
                  customer,
                  customerDeliveries[customerId]!,
                  payments
                      .where((payment) => payment.customerId == customerId)
                      .toList(),
                  currencyFormat,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCustomerDetails(
    BuildContext context,
    Customer customer,
    List<Delivery> deliveries,
    List<Payment> payments,
    NumberFormat currencyFormat,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final totalDeliveryAmount = deliveries.fold<double>(
          0,
          (sum, delivery) => sum + (delivery.totalAmount),
        );
        final totalPayments = payments.fold<double>(
          0,
          (sum, payment) => sum + (payment.amount),
        );
        final pendingAmount = totalDeliveryAmount - totalPayments;

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        customer.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Total Deliveries',
                            currencyFormat.format(totalDeliveryAmount),
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Total Payments',
                            currencyFormat.format(totalPayments),
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Pending Amount',
                            currencyFormat.format(pendingAmount),
                            isHighlighted: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recent Deliveries',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: deliveries.length,
                      itemBuilder: (context, index) {
                        final delivery = deliveries[index];
                        return ListTile(
                          title: Text(
                            DateFormat('dd MMM yyyy').format(delivery.date),
                          ),
                          subtitle: Text(
                            '${delivery.bottles} bottles @ Rs${delivery.pricePerBottle}/bottle',
                          ),
                          trailing: Text(
                            currencyFormat.format(delivery.totalAmount),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
