import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/task.dart';
import '../theme.dart';
import '../utils.dart';

/// Talks to the Android home-screen widget and the activity that hosts it.
class WidgetService {
  WidgetService._();

  static const _channel = MethodChannel('dayflow/widget');

  /// Sends today's data to the widget and asks it to redraw. The data travels
  /// through the channel itself, so the widget never reads stale storage.
  static Future<void> update(List<Task> tasks) async {
    try {
      final from = dayOnly(DateTime.now()).subtract(const Duration(days: 1));
      final to = from.add(const Duration(days: 62));
      final items = [
        for (final t in tasks)
          if (!t.date.isBefore(from) && t.date.isBefore(to))
            {
              'id': t.id,
              'title': t.title,
              'date': t.date.toIso8601String(),
              'done': t.done,
              'category': t.category,
            },
      ];
      final cats = [
        for (final c in categories) {'name': c.name, 'color': c.color.toARGB32()},
      ];
      await _channel.invokeMethod<void>('update', {
        'tasks': jsonEncode(items),
        'categories': jsonEncode(cats),
      });
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
