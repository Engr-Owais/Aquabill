import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_bill/models/delivery.dart';
import 'package:aqua_bill/services/database_service.dart';

final deliveryListProvider =
    StateNotifierProvider<DeliveryListNotifier, List<Delivery>>((ref) {
      return DeliveryListNotifier(ref.watch(databaseServiceProvider));
    });

final customerDeliveriesProvider = Provider.family<List<Delivery>, String>((
  ref,
  customerId,
) {
  final deliveries = ref.watch(deliveryListProvider);
  return deliveries
      .where((delivery) => delivery.customerId == customerId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

class DeliveryListNotifier extends StateNotifier<List<Delivery>> {
  final DatabaseService _db;

  DeliveryListNotifier(this._db) : super([]) {
    loadDeliveries();
  }

  Future<void> loadDeliveries() async {
    state = await _db.getDeliveries();
  }

  Future<void> addDelivery({
    required String customerId,
    required int bottles,
    required DateTime date,
    required double pricePerBottle,
  }) async {
    final delivery = Delivery(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: customerId,
      bottles: bottles,
      date: date,
      pricePerBottle: pricePerBottle,
    );

    await _db.saveDelivery(delivery);
    state = [...state, delivery];
  }

  Future<void> removeDelivery(String id) async {
    await _db.deleteDelivery(id);
    state = state.where((delivery) => delivery.id != id).toList();
  }
}

final todayDeliveriesProvider = Provider<List<Delivery>>((ref) {
  final deliveries = ref.watch(deliveryListProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return deliveries
      .where(
        (delivery) =>
            delivery.date.year == today.year &&
            delivery.date.month == today.month &&
            delivery.date.day == today.day,
      )
      .toList();
});
