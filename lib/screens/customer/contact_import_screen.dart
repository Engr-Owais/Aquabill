import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aqua_bill/providers/customer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactImportScreen extends ConsumerStatefulWidget {
  final double defaultBottleRate;
  final int defaultBottlesPerMonth;

  const ContactImportScreen({
    super.key,
    required this.defaultBottleRate,
    required this.defaultBottlesPerMonth,
  });

  @override
  ConsumerState<ContactImportScreen> createState() =>
      _ContactImportScreenState();
}

class _ContactImportScreenState extends ConsumerState<ContactImportScreen> {
  List<Contact> _contacts = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      if (await Permission.contacts.request().isGranted) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: true,
        );
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Contacts permission denied';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading contacts: $e';
        _isLoading = false;
      });
    }
  }

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) return _contacts;
    return _contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final phone =
          contact.phones.isNotEmpty ? contact.phones.first.number : '';
      return name.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery);
    }).toList();
  }

  Future<void> _importContact(Contact contact) async {
    try {
      if (contact.phones.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact has no phone number')),
        );
        return;
      }

      await ref
          .read(customerListProvider.notifier)
          .addCustomer(
            name: contact.displayName,
            phone: contact.phones.first.number,
            address:
                contact.addresses.isNotEmpty
                    ? contact.addresses.first.street
                    : null,
            bottleRate: widget.defaultBottleRate,
            bottlesPerMonth: widget.defaultBottlesPerMonth,
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing contact: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Contacts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
              ),
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadContacts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return ListTile(
                    leading:
                        contact.photo != null
                            ? CircleAvatar(
                              backgroundImage: MemoryImage(contact.photo!),
                            )
                            : CircleAvatar(
                              child: Text(contact.displayName[0].toUpperCase()),
                            ),
                    title: Text(contact.displayName),
                    subtitle:
                        contact.phones.isNotEmpty
                            ? Text(contact.phones.first.number)
                            : null,
                    onTap: () => _importContact(contact),
                  );
                },
              ),
    );
  }
}
