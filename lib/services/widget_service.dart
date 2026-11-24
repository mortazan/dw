import 'package:flutter/services.dart';

/// Talks to the Android home-screen widget and the activity that hosts it.
class WidgetService {
  WidgetService._();

  static const _channel = MethodChannel('dayflow/widget');

  /// Asks the widget to redraw itself.
  static Future<void> update() async {
    try {
      await _channel.invokeMethod<void>('update');
    } catch (_) {
      // No widget host or not on Android: nothing to do.
    }
  }

  /// Calls [onOpen] with the task id whenever a widget row is tapped, and
  /// once for a tap that started the app.
  static Future<void> listen(void Function(String id) onOpen) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openTask' && call.arguments is String) {
        onOpen(call.arguments as String);
      }
    });
    try {
      final id = await _channel.invokeMethod<String>('takeTask');
      if (id != null) onOpen(id);
    } catch (_) {}
  }
}
