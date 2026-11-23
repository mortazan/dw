import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/notification_service.dart';
import '../utils.dart';

class AppState extends ChangeNotifier {
  List<Task> tasks = [];
  String userName = 'کاربر';
  bool loading = true;
  SharedPreferences? _prefs;

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName') ?? userName;
    try {
      final raw = prefs.getString('tasks') ?? '[]';
      tasks = (jsonDecode(raw) as List<dynamic>)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      tasks = [];
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(
      'tasks',
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> _commit() async {
    notifyListeners();
    await _save();
  }

  Future<void> add(Task task) async {
    tasks.add(task);
    await _commit();
    await NotificationService.schedule(task);
  }

  Future<void> update(Task task) async {
    final i = tasks.indexWhere((t) => t.id == task.id);
    if (i < 0) return;
    tasks[i] = task;
    await _commit();
    await NotificationService.cancel(task);
    await NotificationService.schedule(task);
  }

  Future<void> toggleDone(Task task) => update(task.copyWith(done: !task.done));

  Future<void> toggleImportant(Task task) =>
      update(task.copyWith(important: !task.important));

  Future<void> delete(Task task) async {
    tasks.removeWhere((t) => t.id == task.id);
    await _commit();
    await NotificationService.cancel(task);
  }

  Future<void> clearDone() async {
    final removed = tasks.where((t) => t.done).toList();
    tasks.removeWhere((t) => t.done);
    await _commit();
    for (final t in removed) {
      await NotificationService.cancel(t);
    }
  }

  Future<void> setName(String name) async {
    userName = name.trim().isEmpty ? 'کاربر' : name.trim();
    notifyListeners();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
  }

  // ---- queries ----

  List<Task> forDay(DateTime day) =>
      tasks.where((t) => isSameDay(t.date, day)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<Task> get overdue {
    final today = dayOnly(DateTime.now());
    return tasks.where((t) => !t.done && t.date.isBefore(today)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Task> get upcomingReminders {
    final now = DateTime.now();
    return tasks
        .where((t) => !t.done && t.reminder != null && t.reminder!.isAfter(now))
        .toList()
      ..sort((a, b) => a.reminder!.compareTo(b.reminder!));
  }
}

final appState = AppState();
