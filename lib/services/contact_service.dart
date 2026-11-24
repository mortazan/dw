import 'package:flutter/services.dart';

/// Opens the system contact picker and returns the chosen name and phone.
class ContactService {
  ContactService._();

  static const _channel = MethodChannel('dayflow/contacts');

  static Future<({String name, String phone})?> pick() async {
    try {
      final result = await _channel.invokeMapMethod<String, String>('pick');
      if (result == null) return null;
      final phone = (result['phone'] ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
      if (phone.isEmpty) return null;
      return (name: result['name'] ?? '', phone: phone);
    } catch (_) {
      return null;
    }
  }
}
