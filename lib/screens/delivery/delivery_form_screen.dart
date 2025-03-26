import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_bill/models/delivery.dart';
import 'package:aqua_bill/models/payment.dart';
import 'package:aqua_bill/providers/customer_provider.dart';
import 'package:aqua_bill/providers/delivery_provider.dart';
import 'package:aqua_bill/providers/payment_provider.dart';
import 'package:uuid/uuid.dart';

class DeliveryFormScreen extends ConsumerStatefulWidget {
  const DeliveryFormScreen({super.key});

  @override
  ConsumerState<DeliveryFormScreen> createState() => _DeliveryFormScreenState();
}

class _DeliveryFormScreenState extends ConsumerState<DeliveryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  int _bottles = 1;
  double? _pricePerBottle;
  bool _isPaid = false;
  PaymentMode _paymentMode = PaymentMode.cash;
  final DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Delivery')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCustomerId,
                      items:
                          customers.map((customer) {
                            return DropdownMenuItem(
                              value: customer.id,
                              child: Text(customer.name),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomerId = value;
                          if (value != null) {
                            final customer = customers.firstWhere(
                              (c) => c.id == value,
                            );
                            _pricePerBottle = customer.bottleRate;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a customer';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Number of Bottles',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _bottles.toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _bottles = int.tryParse(value) ?? 1;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter number of bottles';
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value) < 1) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Price per Bottle',
                              border: OutlineInputBorder(),
                              prefixText: 'Rs',
                            ),
                            initialValue:
                                _pricePerBottle?.toStringAsFixed(2) ?? '',
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _pricePerBottle = double.tryParse(value) ?? 0.0;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter price';
                              }
                              if (double.tryParse(value) == null ||
                                  double.parse(value) <= 0) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Payment Collected?'),
                      trailing: Switch(
                        value: _isPaid,
                        onChanged: (value) {
                          setState(() {
                            _isPaid = value;
                          });
                        },
                      ),
                    ),
                    if (_isPaid) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PaymentMode>(
                        decoration: const InputDecoration(
                          labelText: 'Payment Mode',
                          border: OutlineInputBorder(),
                        ),
                        value: _paymentMode,
                        items:
                            PaymentMode.values.map((mode) {
                              return DropdownMenuItem(
                                value: mode,
                                child: Text(mode.toString().split('.').last),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _paymentMode = value;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedCustomerId != null &&
                _pricePerBottle != null &&
                _bottles > 0) ...[
              Text(
                'Total Amount: Rs${(_pricePerBottle! * _bottles).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _saveDelivery,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Save Delivery'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveDelivery() async {
    if (_formKey.currentState?.validate() ?? false) {
      final delivery = Delivery(
        id: const Uuid().v4(),
        customerId: _selectedCustomerId!,
        bottles: _bottles,
        pricePerBottle: _pricePerBottle!,
        date: _selectedDate,
      );

      await ref
          .read(deliveryListProvider.notifier)
          .addDelivery(
            customerId: delivery.customerId,
            bottles: delivery.bottles,
            date: delivery.date,
            pricePerBottle: delivery.pricePerBottle,
          );

      if (_isPaid) {
        final payment = Payment(
          id: const Uuid().v4(),
          customerId: _selectedCustomerId!,
          amount: _pricePerBottle! * _bottles,
          date: _selectedDate,
          mode: _paymentMode,
        );

        await ref
            .read(paymentListProvider.notifier)
            .addPayment(
              customerId: payment.customerId,
              amount: payment.amount,
              date: payment.date,
              mode: payment.mode,
            );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
