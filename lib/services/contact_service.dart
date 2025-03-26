import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  Future<List<Contact>> getContacts() async {
    if (await Permission.contacts.request().isGranted) {
      return await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
    }
    return [];
  }

  Future<Contact?> getContact(String id) async {
    if (await Permission.contacts.request().isGranted) {
      return await FlutterContacts.getContact(id);
    }
    return null;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  static String? getPhoneNumber(Contact contact) {
    if (contact.phones.isEmpty) {
      return null;
    }

    // Try to find a mobile number first
    final mobileNumber = contact.phones.firstWhere(
      (phone) => phone.label.toString().toLowerCase() == 'mobile',
      orElse: () => contact.phones.first,
    );

    String? number = mobileNumber.number;

    // Remove all non-digit characters
    number = number.replaceAll(RegExp(r'[^\d]'), '');

    // If the number starts with country code (e.g., +91), remove it
    if (number.length > 10) {
      number = number.substring(number.length - 10);
    }

    return number;
  }
}
