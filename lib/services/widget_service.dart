import 'package:flutter/services.dart';

/// Asks the Android home-screen widget to redraw itself.
class WidgetService {
  WidgetService._();

  static const _channel = MethodChannel('dayflow/widget');

  static Future<void> update() async {
    try {
      await _channel.invokeMethod<void>('update');
    } catch (_) {
      // No widget host or not on Android: nothing to do.
    }
  }
}
