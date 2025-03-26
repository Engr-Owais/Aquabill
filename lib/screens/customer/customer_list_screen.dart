import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aqua_bill/providers/customer_provider.dart';
import 'package:aqua_bill/screens/customer/add_customer_screen.dart';
import 'package:aqua_bill/screens/customer/contact_import_screen.dart';
import 'package:aqua_bill/screens/customer/customer_detail_screen.dart';
import 'package:aqua_bill/widgets/customer_list_item.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_contacts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => const ContactImportScreen(
                        defaultBottleRate: 60.0,
                        defaultBottlesPerMonth: 4,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body:
          customers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No customers yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddCustomerScreen(),
                            ),
                          ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Customer'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ContactImportScreen(
                                    defaultBottleRate: 60.0,
                                    defaultBottlesPerMonth: 4,
                                  ),
                            ),
                          ),
                      icon: const Icon(Icons.import_contacts),
                      label: const Text('Import from Contacts'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return CustomerListItem(
                    customer: customer,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    CustomerDetailScreen(customer: customer),
                          ),
                        ),
                  );
                },
              ),
      floatingActionButton:
          customers.isEmpty
              ? null
              : FloatingActionButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddCustomerScreen(),
                      ),
                    ),
                child: const Icon(Icons.add),
              ),
    );
  }
}
