import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aqua_bill/providers/customer_provider.dart';
import 'package:aqua_bill/providers/delivery_provider.dart';
import 'package:aqua_bill/providers/payment_provider.dart';
import 'package:aqua_bill/screens/customer/customer_form_screen.dart';
import 'package:aqua_bill/screens/customer/customer_list_screen.dart';
import 'package:aqua_bill/screens/delivery/delivery_form_screen.dart';
import 'package:aqua_bill/screens/delivery/today_deliveries_screen.dart';
import 'package:aqua_bill/screens/payment/payment_form_screen.dart';
import 'package:aqua_bill/screens/payment/today_payments_screen.dart';
import 'package:aqua_bill/screens/reports/monthly_report_screen.dart';
import 'package:aqua_bill/screens/payment/pending_payments_screen.dart';

import '../../models/payment.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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
    final customers = ref.watch(customerListProvider);
    final todayDeliveries = ref.watch(todayDeliveriesProvider);
    final todayPayments = ref.watch(todayPaymentsProvider);
    final todayCollection = todayPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs');

    return Scaffold(
      appBar: AppBar(
        title: const Text('AquaBill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MonthlyReportScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerFormScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          _buildMetricsCard(
            context,
            customers.length,
            todayDeliveries.length,
            currencyFormat,
          ),
          const SizedBox(height: 16),
          _buildTotalCollectionCard(
            context,
            todayCollection,
            currencyFormat,
            todayPayments,
          ),
          const SizedBox(height: 16),
          _buildPendingPaymentsCard(context, ref, currencyFormat),
          const SizedBox(height: 16),
          _buildAdvancePaymentsCard(context, ref, currencyFormat),
          const SizedBox(height: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder:
                (context) =>
                    _AddTransactionSheet(currencyFormat: currencyFormat),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMetricsCard(
    BuildContext context,
    int customerCount,
    int todayDeliveries,
    NumberFormat currencyFormat,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricItem(
                  'Total Customers',
                  _formatNumber(customerCount.toDouble()),
                  Icons.people,
                  null,
                ),
                _buildMetricItem(
                  'Today\'s Deliveries',
                  _formatNumber(todayDeliveries.toDouble()),
                  Icons.local_shipping,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TodayDeliveriesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCollectionCard(
    BuildContext context,
    double todayCollection,
    NumberFormat currencyFormat,
    List<Payment> todayPayments,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Collection',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TodayPaymentsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('See Details'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Collection',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(todayCollection),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Payments',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${todayPayments.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.blue[700]),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPendingPaymentsCard(
    BuildContext context,
    WidgetRef ref,
    NumberFormat currencyFormat,
  ) {
    final deliveries = ref.watch(deliveryListProvider);
    final payments = ref.watch(paymentListProvider);
    final customers = ref.watch(customerListProvider);

    // Calculate pending amounts for each customer
    final pendingPayments = <String, double>{};
    var totalPendingAmount = 0.0;

    for (final customer in customers) {
      final customerDeliveryList =
          deliveries
              .where((delivery) => delivery.customerId == customer.id)
              .toList();

      final totalDeliveryAmount = customerDeliveryList.fold<double>(
        0,
        (sum, delivery) => sum + (delivery.totalAmount),
      );

      final totalPayments = payments
          .where((payment) => payment.customerId == customer.id)
          .fold<double>(0, (sum, payment) => sum + (payment.amount));

      final pendingAmount = totalDeliveryAmount - totalPayments;
      if (pendingAmount > 0) {
        pendingPayments[customer.id] = pendingAmount;
        totalPendingAmount += pendingAmount;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Payments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PendingPaymentsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('See Details'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pending Amount',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(totalPendingAmount),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Customers',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pendingPayments.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancePaymentsCard(
    BuildContext context,
    WidgetRef ref,
    NumberFormat currencyFormat,
  ) {
    final deliveries = ref.watch(deliveryListProvider);
    final payments = ref.watch(paymentListProvider);
    final customers = ref.watch(customerListProvider);

    // Calculate advance payments for each customer
    final advancePayments = <String, double>{};
    var totalAdvanceAmount = 0.0;

    for (final customer in customers) {
      final customerDeliveryList =
          deliveries
              .where((delivery) => delivery.customerId == customer.id)
              .toList();

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
        totalAdvanceAmount += advanceAmount;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advance Payments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Navigate to advance payments screen
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const AdvancePaymentsScreen(),
                    //   ),
                    // );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('See Details'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Advance Amount',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(totalAdvanceAmount),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Customers',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${advancePayments.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTransactionSheet extends StatelessWidget {
  final NumberFormat currencyFormat;

  const _AddTransactionSheet({required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('Record Delivery'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeliveryFormScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Record Payment'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
