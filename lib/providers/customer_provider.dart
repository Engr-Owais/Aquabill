import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_bill/models/customer.dart';
import 'package:aqua_bill/services/database_service.dart';
import 'package:uuid/uuid.dart';

final customerListProvider =
    StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
      return CustomerNotifier(ref.watch(databaseServiceProvider));
    });

class CustomerNotifier extends StateNotifier<List<Customer>> {
  final DatabaseService _db;

  CustomerNotifier(this._db) : super([]) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = await _db.getCustomers();
  }

  Future<void> addCustomer({
    required String name,
    required String phone,
    String? address,
    required double bottleRate,
    required int bottlesPerMonth,
  }) async {
    final customer = Customer(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      address: address,
      createdAt: DateTime.now(),
      bottleRate: bottleRate,
      bottlesPerMonth: bottlesPerMonth,
    );

    await _db.saveCustomer(customer);
    await loadCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.saveCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(String customerId) async {
    await _db.deleteCustomer(customerId);
    await loadCustomers();
  }
}

final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);
