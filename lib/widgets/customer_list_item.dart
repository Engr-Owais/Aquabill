import 'package:flutter/material.dart';
import 'package:aqua_bill/models/customer.dart';

class CustomerListItem extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const CustomerListItem({
    super.key,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text(customer.name[0].toUpperCase())),
        title: Text(
          customer.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          customer.phone,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs${customer.bottleRate}/bottle',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                Text(
                  '${customer.bottlesPerMonth} bottles/month',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
