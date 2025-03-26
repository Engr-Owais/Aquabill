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
  PaymentListNotifier() : super([]);

  Future<void> loadPayments() async {
    final payments = await DatabaseService().getPayments();
    state = payments;
  }

  Future<void> addPayment({
    required String customerId,
    required double amount,
    required DateTime date,
    required PaymentMode mode,
  }) async {
    final payment = Payment(
      id: DateTime.now().toIso8601String(),
      customerId: customerId,
      amount: amount,
      date: date,
      mode: mode,
    );

    await DatabaseService().savePayment(payment);
    state = [...state, payment];
  }

  Future<void> deletePayment(String id) async {
    await DatabaseService().deletePayment(id);
    state = state.where((payment) => payment.id != id).toList();
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
