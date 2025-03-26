import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_bill/models/payment.dart';
import 'package:aqua_bill/services/database_service.dart';

import 'package:aqua_bill/providers/delivery_provider.dart';

final paymentListProvider =
    StateNotifierProvider<PaymentListNotifier, List<Payment>>((ref) {
      return PaymentListNotifier();
    });

final customerPaymentsProvider = Provider.family<List<Payment>, String>((
  ref,
  customerId,
) {
  final payments = ref.watch(paymentListProvider);
  return payments.where((payment) => payment.customerId == customerId).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

class PaymentListNotifier extends StateNotifier<List<Payment>> {
  final _databaseService = DatabaseService();
  
  PaymentListNotifier() : super([]) {
    // Load payments when the provider is initialized
    loadPayments();
  }

  Future<void> loadPayments() async {
    try {
      final payments = await _databaseService.getPayments();
      state = payments;
    } catch (e) {
      print('Error loading payments: $e');
      state = [];
    }
  }

  Future<void> addPayment({
    required String customerId,
    required double amount,
    required DateTime date,
    required PaymentMode mode,
  }) async {
    try {
      final payment = Payment(
        id: DateTime.now().toIso8601String(),
        customerId: customerId,
        amount: amount,
        date: date,
        mode: mode,
      );

      await _databaseService.savePayment(payment);
      await loadPayments(); // Reload payments from database after saving
    } catch (e) {
      print('Error adding payment: $e');
      rethrow;
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      await _databaseService.deletePayment(id);
      await loadPayments(); // Reload payments from database after deleting
    } catch (e) {
      print('Error deleting payment: $e');
      rethrow;
    }
  }
}

final customerBalanceProvider = Provider.family<double, String>((
  ref,
  customerId,
) {
  final deliveries = ref
      .watch(deliveryListProvider)
      .where((delivery) => delivery.customerId == customerId);
  final payments = ref
      .watch(paymentListProvider)
      .where((payment) => payment.customerId == customerId);

  final totalDeliveryAmount = deliveries.fold<double>(
    0,
    (sum, delivery) => sum + delivery.totalAmount,
  );

  final totalPaymentAmount = payments.fold<double>(
    0,
    (sum, payment) => sum + payment.amount,
  );

  return totalDeliveryAmount - totalPaymentAmount;
});

final todayPaymentsProvider = Provider<List<Payment>>((ref) {
  final payments = ref.watch(paymentListProvider);
  final now = DateTime.now();
  return payments.where((payment) {
    return payment.date.year == now.year &&
        payment.date.month == now.month &&
        payment.date.day == now.day;
  }).toList();
});
