import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';
import '../utils.dart';

/// Entry point used when the user taps an action on a notification while the
/// app is not running.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.handleResponse(response, background: true);
}

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  // Notification id ranges: tasks use (hash & 0x3FFFFFF) * 16 + n (below ~1.08e9),
  // snoozes use 1.1e9..1.9e9, the morning summary 2e9 + day.
  static const _morningBase = 2000000000;
  static const _snoozeMinutes = 10;

  static NotificationDetails _details({bool snooze = true}) => NotificationDetails(
        android: AndroidNotificationDetails(
          'dayflow_reminders',
          'یادآورها',
          channelDescription: 'یادآور کارهای روزانه',
          importance: Importance.high,
          priority: Priority.high,
          actions: snooze
              ? const [
                  AndroidNotificationAction(
                    'snooze',
                    '۱۰ دقیقه بعد',
                    cancelNotification: true,
                  ),
                ]
              : null,
        ),
      );

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(android: _androidInit),
      onDidReceiveNotificationResponse: (r) => handleResponse(r),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static Future<void> handleResponse(
    NotificationResponse response, {
    bool background = false,
  }) async {
    if (response.actionId != 'snooze') return;
    if (background) {
      tz_data.initializeTimeZones();
      await _plugin.initialize(const InitializationSettings(android: _androidInit));
    }
    var title = 'مدیریت زمان';
    var body = '';
    try {
      final data = jsonDecode(response.payload ?? '{}') as Map<String, dynamic>;
      title = (data['t'] ?? title) as String;
      body = (data['b'] ?? '') as String;
    } catch (_) {}
    final at = DateTime.now().add(const Duration(minutes: _snoozeMinutes));
    await _plugin.zonedSchedule(
      1100000000 + DateTime.now().millisecondsSinceEpoch % 800000000,
      title,
      body,
      tz.TZDateTime.from(at, tz.UTC),
      _details(),
      payload: response.payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<bool> requestPermission() async {
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return granted ?? false;
  }

  static int _base(String taskId) => (taskId.hashCode & 0x3FFFFFF) * 16;

  static String _beforeLabel(int minutes) {
    if (minutes <= 0) return 'همین حالا';
    if (minutes < 60) return '${toFa(minutes)} دقیقه دیگر';
    if (minutes < 1440) return '${toFa(minutes ~/ 60)} ساعت دیگر';
    return '${toFa(minutes ~/ 1440)} روز دیگر';
  }

  /// Schedules every reminder of [task]: the custom one and the "before" ones.
  static Future<void> schedule(Task task) async {
    if (task.done) return;
    final now = DateTime.now();
    final plan = <(DateTime, String)>[
      if (task.reminder != null)
        (task.reminder!, task.note.isEmpty ? 'یادآور کار' : task.note),
      for (final m in task.remindBefore)
        (task.date.subtract(Duration(minutes: m)), _beforeLabel(m)),
    ];
    for (var i = 0; i < plan.length && i < 16; i++) {
      final (at, body) = plan[i];
      if (!at.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        _base(task.id) + i,
        task.title,
        body,
        // TZDateTime.from keeps the exact instant, so the local zone is not needed.
        tz.TZDateTime.from(at, tz.UTC),
        _details(),
        payload: jsonEncode({'t': task.title, 'b': body}),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancel(Task task) async {
    final base = _base(task.id);
    for (var i = 0; i < 16; i++) {
      await _plugin.cancel(base + i);
    }
  }

  /// Schedules a daily summary of the open tasks for the next two weeks.
  /// The text is built from the data at scheduling time, so this is called
  /// again whenever the tasks change.
  static Future<void> scheduleMorning({
    required List<Task> tasks,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    for (var i = 0; i < 14; i++) {
      await _plugin.cancel(_morningBase + i);
    }
    if (!enabled) return;
    final now = DateTime.now();
    for (var i = 0; i < 14; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      final at = DateTime(day.year, day.month, day.day, hour, minute);
      if (!at.isAfter(now)) continue;
      final list = tasks.where((t) => !t.done && isSameDay(t.date, day)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (list.isEmpty) continue;
      final titles = list.take(3).map((t) => t.title).join('، ');
      final more = list.length > 3 ? ' و ${toFa(list.length - 3)} کار دیگر' : '';
      await _plugin.zonedSchedule(
        _morningBase + i,
        'کارهای امروز (${toFa(list.length)})',
        '$titles$more',
        tz.TZDateTime.from(at, tz.UTC),
        _details(snooze: false),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> scheduleAt(int id, String title, String body, DateTime at) =>
      _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(at, tz.UTC),
        _details(snooze: false),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

  static Future<void> cancelId(int id) => _plugin.cancel(id);

  static Future<void> showTest() => _plugin.show(
        0,
        'مدیریت زمان',
        'اعلان‌ها به درستی کار می‌کنند ✅',
        _details(),
        payload: jsonEncode({'t': 'مدیریت زمان', 'b': 'اعلان آزمایشی'}),
      );
}
