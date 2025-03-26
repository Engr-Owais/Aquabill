import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:aqua_bill/screens/splash/splash_screen.dart';
import 'package:aqua_bill/services/database_service.dart';
import 'package:aqua_bill/models/payment.dart';
import 'package:intl/intl.dart';
import 'package:aqua_bill/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dbService = DatabaseService();
    await dbService.initialize();
    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    print('Failed to initialize app: $e');
    runApp(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: ErrorScreen(error: e.toString()),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to initialize app',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaBill',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const SplashScreen(),
    );
  }
}

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
        padding: const EdgeInsets.all(16),
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
          _buildBusinessAnalytics(context, ref, currencyFormat),
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
        padding: const EdgeInsets.all(16),
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
          Icon(icon, size: 32, color: Colors.blue),
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
        padding: const EdgeInsets.all(16),
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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

  Widget _buildBusinessAnalytics(
    BuildContext context,
    WidgetRef ref,
    NumberFormat currencyFormat,
  ) {
    final deliveries = ref.watch(deliveryListProvider);
    final payments = ref.watch(paymentListProvider);
    final activeCustomers =
        ref.watch(customerListProvider).where((c) => c.isActive).length;

    final totalBottles = deliveries.fold<int>(0, (sum, d) => sum + d.bottles);
    final totalRevenue = deliveries.fold<double>(
      0,
      (sum, d) => sum + d.totalAmount,
    );
    final totalCollected = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final collectionRate =
        totalRevenue > 0 ? (totalCollected / totalRevenue) * 100 : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.people_outline, color: Colors.blue),
              title: const Text('Active Customers'),
              trailing: Text(
                '$activeCustomers',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.water_drop_outlined,
                color: Colors.blue,
              ),
              title: const Text('Total Bottles Delivered'),
              trailing: Text(
                '$totalBottles',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.green),
              title: const Text('Total Revenue'),
              trailing: Text(
                currencyFormat.format(totalRevenue),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined, color: Colors.green),
              title: const Text('Total Collections'),
              trailing: Text(
                currencyFormat.format(totalCollected),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.percent, color: Colors.orange),
              title: const Text('Collection Rate'),
              trailing: Text(
                '${collectionRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: collectionRate >= 80 ? Colors.green : Colors.orange,
                ),
              ),
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
