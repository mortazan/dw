import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'dayflow_reminders',
      'یادآورها',
      channelDescription: 'یادآور کارهای روزانه',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
  }

  static Future<bool> requestPermission() async {
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return granted ?? false;
  }

  static int _id(String taskId) => taskId.hashCode & 0x7fffffff;

  static Future<void> schedule(Task task) async {
    final reminder = task.reminder;
    if (task.done || reminder == null || !reminder.isAfter(DateTime.now())) {
      return;
    }
    await _plugin.zonedSchedule(
      _id(task.id),
      task.title,
      task.note.isEmpty ? 'یادآور کار' : task.note,
      // TZDateTime.from keeps the exact instant, so the local zone is not needed.
      tz.TZDateTime.from(reminder, tz.UTC),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancel(Task task) => _plugin.cancel(_id(task.id));

  static Future<void> showTest() => _plugin.show(
        0,
        'DayFlow',
        'اعلان‌ها به درستی کار می‌کنند ✅',
        _details,
      );
}
