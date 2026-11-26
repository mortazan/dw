import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/media_item.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../theme.dart';
import '../utils.dart';

/// Lets any code show a snackbar (e.g. "undo delete") after its page is gone.
final messengerKey = GlobalKey<ScaffoldMessengerState>();

const defaultGreeting = 'چه روز خوبی برای انجام کارهای عالیه!';

class AppState extends ChangeNotifier {
  List<Task> tasks = [];
  String userName = 'کاربر';
  String greeting = defaultGreeting;
  String? avatarPath;
  ThemeMode themeMode = ThemeMode.system;
  List<MediaItem> media = [];
  int hijriOffset = 0;
  int accentIndex = 0;
  bool backupReminder = false;
  bool eveningReview = false;
  String? pinHash;
  bool morningEnabled = false;
  int morningHour = 7;
  int morningMinute = 30;
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
    try {
      final raw = prefs.getString('categories');
      if (raw != null) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((e) => Cat.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) categories = list;
      }
    } catch (_) {}
    try {
      final raw = prefs.getString('media');
      if (raw != null) {
        media = (jsonDecode(raw) as List<dynamic>)
            .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    hijriOffset = prefs.getInt('hijriOffset') ?? 0;
    accentIndex = prefs.getInt('accent') ?? 0;
    backupReminder = prefs.getBool('backupReminder') ?? false;
    eveningReview = prefs.getBool('eveningReview') ?? false;
    pinHash = prefs.getString('pinHash');
    applyAccent(accentIndex);
    morningEnabled = prefs.getBool('morningEnabled') ?? false;
    morningHour = prefs.getInt('morningHour') ?? 7;
    morningMinute = prefs.getInt('morningMinute') ?? 30;
    loading = false;
    notifyListeners();
    await _afterChange();
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
    await _afterChange();
  }

  /// Refreshes things that depend on the task list: the morning summary
  /// notifications and the home-screen widget.
  Future<void> _afterChange() async {
    // The widget first and on its own, so a notification problem can never
    // keep it from refreshing.
    await WidgetService.update(tasks);
    try {
      await NotificationService.scheduleMorning(
        tasks: tasks,
        enabled: morningEnabled,
        hour: morningHour,
        minute: morningMinute,
      );
    } catch (_) {}
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
    var updated = nowDone
        ? task.copyWith(done: true, doneAt: DateTime.now())
        : task.copyWith(done: false, clearDoneAt: true);
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
      priority: task.priority,
      tags: task.tags,
      remindBefore: task.remindBefore,
      alarm: task.alarm,
      alsoNotify: task.alsoNotify,
      extra: task.extra,
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

  /// Deletes a task and offers an "undo" bar for a few seconds.
  Future<void> deleteWithUndo(Task task) => deleteMany([task]);

  /// Tasks that belong to the same repeating series as [task].
  List<Task> seriesOf(Task task) => task.repeat == Repeat.none
      ? [task]
      : tasks
          .where((t) =>
              t.title == task.title &&
              t.category == task.category &&
              t.repeat == task.repeat)
          .toList();

  /// Deletes every task of [task]'s repeating series.
  Future<void> deleteSeries(Task task) => deleteMany(seriesOf(task));

  /// Deletes several tasks at once and offers one "undo" for all of them.
  Future<void> deleteMany(List<Task> items) async {
    final ids = items.map((t) => t.id).toSet();
    final removed = <(int, Task)>[
      for (var i = 0; i < tasks.length; i++)
        if (ids.contains(tasks[i].id)) (i, tasks[i]),
    ];
    if (removed.isEmpty) return;
    tasks.removeWhere((t) => ids.contains(t.id));
    await _commit();
    final text = removed.length == 1
        ? '«${removed.first.$2.title}» حذف شد'
        : '${toFa(removed.length)} کار حذف شد';
    messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 4),
          // With an action, newer Flutter keeps the bar until dismissed
          // unless persist is turned off.
          persist: false,
          action: SnackBarAction(
            label: 'بازگردانی',
            onPressed: () => restoreMany(removed),
          ),
        ),
      );
    for (final r in removed) {
      await NotificationService.cancel(r.$2);
    }
  }

  Future<void> restoreMany(List<(int, Task)> removed) async {
    for (final r in removed) {
      if (tasks.any((t) => t.id == r.$2.id)) continue;
      tasks.insert(r.$1 > tasks.length ? tasks.length : r.$1, r.$2);
    }
    await _commit();
    for (final r in removed) {
      await NotificationService.schedule(r.$2);
    }
  }

  Future<void> restore(Task task, int index) async {
    if (tasks.any((t) => t.id == task.id)) return;
    tasks.insert(index > tasks.length ? tasks.length : index, task);
    await _commit();
    await NotificationService.schedule(task);
  }

  Future<void> addPomodoro(String taskId) async {
    final i = tasks.indexWhere((t) => t.id == taskId);
    if (i < 0) return;
    await update(tasks[i].copyWith(pomodoros: tasks[i].pomodoros + 1));
  }

  List<String> get allTags {
    final set = <String>{for (final t in tasks) ...t.tags};
    return set.toList()..sort();
  }

  // ---- categories ----

  Future<void> _saveCategories() async => (await _p).setString(
        'categories',
        jsonEncode(categories.map((c) => c.toJson()).toList()),
      );

  /// Adds a category, or edits the one called [oldName]. Returns false if the
  /// name is empty or already used.
  Future<bool> saveCategory(Cat cat, {String? oldName}) async {
    final name = cat.name.trim();
    if (name.isEmpty) return false;
    final list = [...categories];
    final clash = list.any((c) => c.name == name && c.name != oldName);
    if (clash) return false;
    final edited = Cat(name, cat.color, cat.iconIndex, cat.fields);
    if (oldName == null) {
      list.add(edited);
    } else {
      final i = list.indexWhere((c) => c.name == oldName);
      if (i < 0) return false;
      list[i] = edited;
      if (oldName != name) {
        tasks = [
          for (final t in tasks)
            catOf(t.category).name == oldName ? t.copyWith(category: name) : t,
        ];
      }
    }
    categories = list;
    await _saveCategories();
    await _commit();
    return true;
  }

  /// Deletes a category; its tasks move to "سایر" (or the last category left).
  Future<void> deleteCategory(String name) async {
    if (categories.length <= 1) return;
    final list = categories.where((c) => c.name != name).toList();
    final fallback =
        list.firstWhere((c) => c.name == 'سایر', orElse: () => list.last).name;
    tasks = [
      for (final t in tasks)
        catOf(t.category).name == name ? t.copyWith(category: fallback) : t,
    ];
    categories = list;
    await _saveCategories();
    await _commit();
  }

  // ---- media slider ----

  Future<void> _saveMedia() async => (await _p).setString(
        'media',
        jsonEncode(media.map((m) => m.toJson()).toList()),
      );

  Future<void> addMedia(MediaItem item) async {
    media = [...media, item];
    notifyListeners();
    await _saveMedia();
  }

  Future<void> updateMedia(MediaItem item) async {
    media = [for (final m in media) m.id == item.id ? item : m];
    notifyListeners();
    await _saveMedia();
  }

  Future<void> deleteMedia(String id) async {
    media = media.where((m) => m.id != id).toList();
    notifyListeners();
    await _saveMedia();
  }

  Future<void> setHijriOffset(int offset) async {
    hijriOffset = offset.clamp(-2, 2).toInt();
    notifyListeners();
    await (await _p).setInt('hijriOffset', hijriOffset);
  }

  // ---- morning summary ----

  Future<void> setMorning({bool? enabled, int? hour, int? minute}) async {
    morningEnabled = enabled ?? morningEnabled;
    morningHour = hour ?? morningHour;
    morningMinute = minute ?? morningMinute;
    notifyListeners();
    final prefs = await _p;
    await prefs.setBool('morningEnabled', morningEnabled);
    await prefs.setInt('morningHour', morningHour);
    await prefs.setInt('morningMinute', morningMinute);
    await _afterChange();
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

  Future<void> setBackupReminder(bool on) async {
    backupReminder = on;
    notifyListeners();
    await (await _p).setBool('backupReminder', on);
    await NotificationService.setBackupReminder(on);
  }

  Future<void> setEveningReview(bool on) async {
    eveningReview = on;
    notifyListeners();
    await (await _p).setBool('eveningReview', on);
    await NotificationService.setEveningReview(on);
  }

  Future<void> setPinHash(String? hash) async {
    pinHash = hash;
    notifyListeners();
    final prefs = await _p;
    if (hash == null) {
      await prefs.remove('pinHash');
    } else {
      await prefs.setString('pinHash', hash);
    }
  }

  /// Moves every overdue task to today (0) or tomorrow (1), keeping its time.
  Future<int> moveOverdue(int days) async {
    final today = dayOnly(DateTime.now());
    final list = overdue;
    for (final t in list) {
      final target = DateTime(
        today.year,
        today.month,
        today.day + days,
        t.date.hour,
        t.date.minute,
      );
      final shift = target.difference(t.date);
      await update(
        t.copyWith(
          date: target,
          reminder: t.reminder?.add(shift),
        ),
      );
    }
    return list.length;
  }

  Future<void> setAccent(int index) async {
    accentIndex = index;
    applyAccent(index);
    notifyListeners();
    // Colors are read from globals, so every widget (even const ones) must
    // rebuild once after the change.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void visit(Element e) {
        e.markNeedsBuild();
        e.visitChildren(visit);
      }

      WidgetsBinding.instance.rootElement?.visitChildren(visit);
    });
    await (await _p).setInt('accent', index);
  }

  /// Moves a slider item from [from] to [to] (indexes before the move).
  Future<void> reorderMedia(int from, int to) async {
    if (from < 0 || from >= media.length) return;
    final list = [...media];
    final item = list.removeAt(from);
    list.insert(to.clamp(0, list.length).toInt(), item);
    media = list;
    notifyListeners();
    await _saveMedia();
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
        'categories': categories.map((c) => c.toJson()).toList(),
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
    if (replace && data['categories'] is List) {
      try {
        final list = (data['categories'] as List<dynamic>)
            .map((e) => Cat.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          categories = list;
          await _saveCategories();
        }
      } catch (_) {}
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
