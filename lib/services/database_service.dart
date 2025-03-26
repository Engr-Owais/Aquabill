import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:aqua_bill/models/customer.dart';
import 'package:aqua_bill/models/delivery.dart';
import 'package:aqua_bill/models/payment.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static bool _isInitialized = false;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  static const String _customersBox = 'customers';
  static const String _deliveriesBox = 'deliveries';
  static const String _paymentsBox = 'payments';

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      await Hive.initFlutter();

      print('Initializing database...');

      // Close any open boxes and reset adapters
      await Hive.close();

      print('Registering adapters...');

      // Register adapters with retries
      for (var attempt = 1; attempt <= 2; attempt++) {
        print('Attempt $attempt to register adapters');

        // First, register the PaymentMode enum adapter as it's a dependency
        if (!Hive.isAdapterRegistered(3)) {
          try {
            Hive.registerAdapter(PaymentModeAdapter());
            print('PaymentModeAdapter registered with typeId 3');
          } catch (e) {
            print('Error registering PaymentModeAdapter: $e');
          }
        } else {
          print('PaymentModeAdapter already registered');
        }

        // Then register the main model adapters
        if (!Hive.isAdapterRegistered(0)) {
          try {
            Hive.registerAdapter(CustomerAdapter());
            print('CustomerAdapter registered with typeId 0');
          } catch (e) {
            print('Error registering CustomerAdapter: $e');
          }
        } else {
          print('CustomerAdapter already registered');
        }

        if (!Hive.isAdapterRegistered(1)) {
          try {
            Hive.registerAdapter(DeliveryAdapter());
            print('DeliveryAdapter registered with typeId 1');
          } catch (e) {
            print('Error registering DeliveryAdapter: $e');
          }
        } else {
          print('DeliveryAdapter already registered');
        }

        if (!Hive.isAdapterRegistered(2)) {
          try {
            Hive.registerAdapter(PaymentAdapter());
            print('PaymentAdapter registered with typeId 2');
          } catch (e) {
            print('Error registering PaymentAdapter: $e');
          }
        } else {
          print('PaymentAdapter already registered');
        }

        // Verify registration after each attempt
        print('Verifying adapter registration...');
        final adaptersRegistered =
            Hive.isAdapterRegistered(0) &&
            Hive.isAdapterRegistered(1) &&
            Hive.isAdapterRegistered(2) &&
            Hive.isAdapterRegistered(3);

        if (adaptersRegistered) {
          print('All adapters registered successfully');
          break;
        } else if (attempt == 2) {
          throw Exception(
            'Failed to register all required adapters after multiple attempts. Registered status: '
            'Customer(0):${Hive.isAdapterRegistered(0)}, '
            'Delivery(1):${Hive.isAdapterRegistered(1)}, '
            'Payment(2):${Hive.isAdapterRegistered(2)}, '
            'PaymentMode(3):${Hive.isAdapterRegistered(3)}',
          );
        } else {
          print('Some adapters failed to register, retrying...');
          // Small delay before retry
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      print('Opening boxes...');

      // Open boxes
      await Hive.openBox<Customer>(_customersBox);
      print('Customers box opened');
      await Hive.openBox<Delivery>(_deliveriesBox);
      print('Deliveries box opened');
      await Hive.openBox<Payment>(_paymentsBox);
      print('Payments box opened');

      _isInitialized = true;
      print('Database initialization completed successfully');
    } catch (e, stackTrace) {
      print('Error during database initialization:');
      print(e);
      print('Stack trace:');
      print(stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  // Helper method to ensure database is ready
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // Customer operations
  Future<List<Customer>> getCustomers() async {
    await ensureInitialized();
    final box = Hive.box<Customer>(_customersBox);
    return box.values.toList();
  }

  Future<Customer?> getCustomer(String id) async {
    await ensureInitialized();
    final box = Hive.box<Customer>(_customersBox);
    return box.get(id);
  }

  Future<void> saveCustomer(Customer customer) async {
    await ensureInitialized();
    final box = Hive.box<Customer>(_customersBox);
    await box.put(customer.id, customer);
  }

  Future<void> deleteCustomer(String id) async {
    await ensureInitialized();
    final box = Hive.box<Customer>(_customersBox);
    await box.delete(id);
  }

  // Delivery operations
  Future<List<Delivery>> getDeliveries() async {
    await ensureInitialized();
    final box = Hive.box<Delivery>(_deliveriesBox);
    return box.values.toList();
  }

  Future<List<Delivery>> getCustomerDeliveries(String customerId) async {
    await ensureInitialized();
    final box = Hive.box<Delivery>(_deliveriesBox);
    return box.values
        .where((delivery) => delivery.customerId == customerId)
        .toList();
  }

  Future<void> saveDelivery(Delivery delivery) async {
    await ensureInitialized();
    final box = Hive.box<Delivery>(_deliveriesBox);
    await box.put(delivery.id, delivery);
  }

  Future<void> deleteDelivery(String id) async {
    await ensureInitialized();
    final box = Hive.box<Delivery>(_deliveriesBox);
    await box.delete(id);
  }

  // Payment operations
  Future<List<Payment>> getPayments() async {
    await ensureInitialized();
    final box = Hive.box<Payment>(_paymentsBox);
    return box.values.toList();
  }

  Future<List<Payment>> getCustomerPayments(String customerId) async {
    await ensureInitialized();
    final box = Hive.box<Payment>(_paymentsBox);
    return box.values
        .where((payment) => payment.customerId == customerId)
        .toList();
  }

  Future<void> savePayment(Payment payment) async {
    await ensureInitialized();
    final box = Hive.box<Payment>(_paymentsBox);
    await box.put(payment.id, payment);
  }

  Future<void> deletePayment(String id) async {
    await ensureInitialized();
    final box = Hive.box<Payment>(_paymentsBox);
    await box.delete(id);
  }

  // Business logic methods
  Future<double> getCustomerOutstandingBalance(String customerId) async {
    final deliveries = await getCustomerDeliveries(customerId);
    final payments = await getCustomerPayments(customerId);
    final customer = await getCustomer(customerId);

    if (customer == null) return 0;

    final totalAmount = deliveries.fold<double>(
      0,
      (sum, delivery) => sum + delivery.totalAmount,
    );

    final totalPaid = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    return totalAmount - totalPaid;
  }

  Future<List<Delivery>> getTodayDeliveries() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final box = Hive.box<Delivery>(_deliveriesBox);
    return box.values
        .where(
          (delivery) =>
              delivery.date.year == today.year &&
              delivery.date.month == today.month &&
              delivery.date.day == today.day,
        )
        .toList();
  }

  Future<double> getTotalOutstandingBalance() async {
    final box = Hive.box<Customer>(_customersBox);
    final customers = box.values.toList();
    double total = 0;

    for (final customer in customers) {
      final balance = await getCustomerOutstandingBalance(customer.id);
      total += balance;
    }

    return total;
  }
}
