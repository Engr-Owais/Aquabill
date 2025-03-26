import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aqua_bill/models/customer.dart';
import 'package:aqua_bill/models/delivery.dart';
import 'package:aqua_bill/models/payment.dart';
import 'package:aqua_bill/providers/customer_provider.dart';
import 'package:aqua_bill/providers/delivery_provider.dart';
import 'package:aqua_bill/providers/payment_provider.dart';
import 'package:aqua_bill/services/pdf_service.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveries = ref.watch(deliveryListProvider);
    final payments = ref.watch(paymentListProvider);
    final customers = ref.watch(customerListProvider);

    final monthlyDeliveries =
        deliveries.where((delivery) {
          return delivery.date.year == selectedDate.year &&
              delivery.date.month == selectedDate.month;
        }).toList();

    final monthlyPayments =
        payments.where((payment) {
          return payment.date.year == selectedDate.year &&
              payment.date.month == selectedDate.month;
        }).toList();

    final totalBottles = monthlyDeliveries.fold<int>(
      0,
      (sum, delivery) => sum + (delivery.bottles),
    );
    final totalRevenue = monthlyDeliveries.fold<double>(
      0,
      (sum, delivery) => sum + (delivery.totalAmount),
    );
    final totalCollections = monthlyPayments.fold<double>(
      0,
      (sum, payment) => sum + (payment.amount),
    );
    final collectionRate =
        totalRevenue > 0 ? (totalCollections / totalRevenue) * 100.0 : 0.0;
    final activeCustomers = customers.where((c) => c.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _selectMonth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(DateFormat('MMMM yyyy').format(selectedDate)),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Deliveries'),
            Tab(text: 'Payments'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              PdfService.generateAndPrintMonthlyReport(
                customers: customers,
                deliveries: deliveries,
                payments: payments,
                month: selectedDate,
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(
            activeCustomers,
            totalBottles,
            totalRevenue,
            totalCollections,
            collectionRate,
          ),
          _buildDeliveriesTab(monthlyDeliveries, customers),
          _buildPaymentsTab(monthlyPayments, customers),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(
    int activeCustomers,
    int totalBottles,
    double totalRevenue,
    double totalCollections,
    double collectionRate,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Monthly Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildOverviewItem(
                    'Active Customers',
                    '$activeCustomers',
                    Icons.people_outline,
                  ),
                  const Divider(),
                  _buildOverviewItem(
                    'Total Bottles Delivered',
                    '$totalBottles',
                    Icons.water_drop_outlined,
                  ),
                  const Divider(),
                  _buildOverviewItem(
                    'Total Revenue',
                    currencyFormat.format(totalRevenue),
                    Icons.attach_money,
                  ),
                  const Divider(),
                  _buildOverviewItem(
                    'Total Collections',
                    currencyFormat.format(totalCollections),
                    Icons.payments,
                  ),
                  const Divider(),
                  _buildOverviewItem(
                    'Collection Rate',
                    '${collectionRate.toStringAsFixed(1)}%',
                    Icons.percent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDeliveriesTab(
    List<Delivery> deliveries,
    List<Customer> customers,
  ) {
    // Group deliveries by date
    final groupedDeliveries = <DateTime, List<Delivery>>{};
    for (var delivery in deliveries) {
      final date = DateTime(
        delivery.date.year,
        delivery.date.month,
        delivery.date.day,
      );
      groupedDeliveries.putIfAbsent(date, () => []).add(delivery);
    }

    return ListView.builder(
      itemCount: groupedDeliveries.length,
      itemBuilder: (context, index) {
        final date = groupedDeliveries.keys.elementAt(index);
        final dailyDeliveries = groupedDeliveries[date]!;
        final totalBottles = dailyDeliveries.fold<int>(
          0,
          (sum, delivery) => sum + (delivery.bottles),
        );
        final totalAmount = dailyDeliveries.fold<double>(
          0,
          (sum, delivery) => sum + (delivery.totalAmount),
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(date),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${totalBottles.toString()} bottles - ${currencyFormat.format(totalAmount)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dailyDeliveries.length,
                itemBuilder: (context, index) {
                  final delivery = dailyDeliveries[index];
                  final customer = customers.firstWhere(
                    (c) => c.id == delivery.customerId,
                    orElse:
                        () => Customer(
                          id: 'unknown',
                          name: 'Unknown Customer',
                          address: '',
                          phone: '',
                          createdAt: DateTime.now(),
                          bottleRate: 0,
                          bottlesPerMonth: 0,
                        ),
                  );

                  return ListTile(
                    title: Text(customer.name),
                    subtitle: Text(
                      '${delivery.bottles} bottles @ Rs${delivery.pricePerBottle}/bottle',
                    ),
                    trailing: Text(currencyFormat.format(delivery.totalAmount)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab(List<Payment> payments, List<Customer> customers) {
    // Group payments by date
    final groupedPayments = <DateTime, List<Payment>>{};
    for (var payment in payments) {
      final date = DateTime(
        payment.date.year,
        payment.date.month,
        payment.date.day,
      );
      groupedPayments.putIfAbsent(date, () => []).add(payment);
    }

    return ListView.builder(
      itemCount: groupedPayments.length,
      itemBuilder: (context, index) {
        final date = groupedPayments.keys.elementAt(index);
        final dailyPayments = groupedPayments[date]!;
        final totalAmount = dailyPayments.fold<double>(
          0,
          (sum, payment) => sum + (payment.amount),
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(date),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      currencyFormat.format(totalAmount),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dailyPayments.length,
                itemBuilder: (context, index) {
                  final payment = dailyPayments[index];
                  final customer = customers.firstWhere(
                    (c) => c.id == payment.customerId,
                    orElse:
                        () => Customer(
                          id: 'unknown',
                          name: 'Unknown Customer',
                          address: '',
                          phone: '',
                          createdAt: DateTime.now(),
                          bottleRate: 0,
                          bottlesPerMonth: 0,
                        ),
                  );

                  return ListTile(
                    title: Text(customer.name),
                    subtitle: Text(payment.mode.toString().split('.').last),
                    trailing: Text(currencyFormat.format(payment.amount)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
