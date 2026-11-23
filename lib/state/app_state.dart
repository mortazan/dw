import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/notification_service.dart';
import '../utils.dart';

const defaultGreeting = 'چه روز خوبی برای انجام کارهای عالیه!';

class AppState extends ChangeNotifier {
  List<Task> tasks = [];
  String userName = 'کاربر';
  String greeting = defaultGreeting;
  String? avatarPath;
  ThemeMode themeMode = ThemeMode.system;
  bool loading = true;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> load() async {
    final prefs = await _p;
    userName = prefs.getString('userName') ?? userName;
    greeting = prefs.getString('greeting') ?? defaultGreeting;
    avatarPath = prefs.getString('avatarPath');
    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == prefs.getString('themeMode'),
      orElse: () => ThemeMode.system,
    );
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
    final prefs = await _p;
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

  /// Marks a task as done or open. Completing a repeating task creates its
  /// next occurrence (once).
  Future<void> toggleDone(Task task) async {
    final nowDone = !task.done;
    var updated = task.copyWith(done: nowDone);
    Task? next;
    if (nowDone && task.repeat != Repeat.none && !task.spawned) {
      next = _nextOf(task);
      updated = updated.copyWith(spawned: true);
    }
    await update(updated);
    if (next != null) await add(next);
  }

  Task _nextOf(Task task) {
    final today = dayOnly(DateTime.now());
    var date = nextOccurrence(task.date, task.repeat);
    // Skip occurrences that are already in the past.
    while (!dayOnly(date).isAfter(today)) {
      date = nextOccurrence(date, task.repeat);
    }
    final offset = task.reminder?.difference(task.date);
    return Task(
      id: const Uuid().v4(),
      title: task.title,
      date: date,
      category: task.category,
      note: task.note,
      important: task.important,
      reminder: offset == null ? null : date.add(offset),
      repeat: task.repeat,
      subtasks: [for (final s in task.subtasks) s.copyWith(done: false)],
    );
  }

  Future<void> toggleImportant(Task task) =>
      update(task.copyWith(important: !task.important));

  Future<void> toggleSubtask(Task task, String subId) => update(
        task.copyWith(
          subtasks: [
            for (final s in task.subtasks)
              s.id == subId ? s.copyWith(done: !s.done) : s,
          ],
        ),
      );

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
    await (await _p).setString('userName', userName);
  }

  Future<void> setGreeting(String text) async {
    greeting = text.trim().isEmpty ? defaultGreeting : text.trim();
    notifyListeners();
    await (await _p).setString('greeting', greeting);
  }

  /// Lets the user pick a profile photo from the gallery. Returns false if
  /// nothing was picked.
  Future<bool> pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (picked == null) return false;
    final dir = await getApplicationDocumentsDirectory();
    final dot = picked.path.lastIndexOf('.');
    final ext = dot == -1 ? 'jpg' : picked.path.substring(dot + 1);
    final saved = await File(picked.path).copy(
      '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await _deleteAvatarFile();
    avatarPath = saved.path;
    notifyListeners();
    await (await _p).setString('avatarPath', saved.path);
    return true;
  }

  Future<void> removeAvatar() async {
    await _deleteAvatarFile();
    avatarPath = null;
    notifyListeners();
    await (await _p).remove('avatarPath');
  }

  Future<void> _deleteAvatarFile() async {
    final old = avatarPath;
    if (old == null) return;
    try {
      final f = File(old);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await (await _p).setString('themeMode', mode.name);
  }

  // ---- backup ----

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'DayFlow',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'userName': userName,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      });

  /// Restores tasks from a backup. Throws [FormatException] for bad input.
  /// Returns the number of tasks added.
  Future<int> importJson(String text, {required bool replace}) async {
    final Object? data;
    try {
      data = jsonDecode(text.trim());
    } catch (_) {
      throw const FormatException('متن واردشده JSON معتبر نیست');
    }
    if (data is! Map<String, dynamic> || data['tasks'] is! List) {
      throw const FormatException('این متن، پشتیبان DayFlow نیست');
    }
    final List<Task> incoming;
    try {
      incoming = (data['tasks'] as List<dynamic>)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const FormatException('ساختار کارها در پشتیبان درست نیست');
    }
    for (final t in tasks) {
      await NotificationService.cancel(t);
    }
    if (replace) tasks = [];
    final ids = tasks.map((t) => t.id).toSet();
    var added = 0;
    for (final t in incoming) {
      if (ids.add(t.id)) {
        tasks.add(t);
        added++;
      }
    }
    if (replace && data['userName'] is String) {
      userName = data['userName'] as String;
      await (await _p).setString('userName', userName);
    }
    await _commit();
    for (final t in tasks) {
      await NotificationService.schedule(t);
    }
    return added;
  }

  Future<void> addSamples() async {
    final now = DateTime.now();
    DateTime at(int dayOffset, int h, int m) =>
        DateTime(now.year, now.month, now.day + dayOffset, h, m);
    const uuid = Uuid();
    SubTask sub(String t, {bool done = false}) =>
        SubTask(id: uuid.v4(), title: t, done: done);
    Task t(
      String title,
      String cat,
      DateTime date, {
      String note = '',
      bool done = false,
      bool important = false,
      Repeat repeat = Repeat.none,
      List<SubTask> subtasks = const [],
    }) =>
        Task(
          id: uuid.v4(),
          title: title,
          category: cat,
          date: date,
          note: note,
          done: done,
          important: important,
          repeat: repeat,
          spawned: done && repeat != Repeat.none,
          subtasks: subtasks,
        );
    tasks.addAll([
      t('تماس با مشتری', 'تماس', at(0, 9, 0),
          note: 'تماس مربوط به پروژه جدید', done: true, important: true),
      t('مراجعه به بانک', 'بانکی', at(0, 11, 30), note: 'پیگیری وام مسکن'),
      t('جلسه تیمی', 'کار', at(0, 13, 0),
          note: 'بررسی وضعیت پروژه',
          subtasks: [
            sub('آماده‌کردن گزارش', done: true),
            sub('ارسال دستور جلسه'),
            sub('رزرو اتاق'),
          ]),
      t('ارسال پیامک به مشتریان', 'پیامک', at(0, 15, 0),
          note: 'پیامک تبلیغاتی ماهانه'),
      t('ورزش صبحگاهی', 'شخصی', at(0, 7, 0),
          done: true, repeat: Repeat.daily),
      t('خرید هفتگی', 'شخصی', at(1, 17, 0),
          repeat: Repeat.weekly,
          subtasks: [sub('نان'), sub('میوه'), sub('لبنیات')]),
      t('پرداخت قبض‌ها', 'بانکی', at(-1, 10, 0), important: true),
      t('تعمیر لپ‌تاپ', 'سایر', at(-2, 16, 0)),
      t('گزارش ماهانه', 'کار', at(-3, 9, 0), done: true),
      t('پیگیری سفارش', 'پیامک', at(-4, 12, 0), done: true),
      t('ملاقات دوستان', 'شخصی', at(2, 19, 0), important: true),
    ]);
    await _commit();
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
