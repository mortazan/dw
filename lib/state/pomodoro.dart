import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';
import 'app_state.dart';

/// A focus/break timer that keeps running while the user moves between pages.
/// The remaining time is always derived from [endsAt], so it stays correct
/// even if the app was in the background.
class PomodoroController extends ChangeNotifier {
  static const _notificationId = 1999999000;

  int focusMinutes = 25;
  int breakMinutes = 5;
  bool isFocus = true;
  bool running = false;
  Duration remaining = const Duration(minutes: 25);
  DateTime? endsAt;
  int sessions = 0;
  String? taskId;
  Timer? _timer;

  Duration get total => Duration(minutes: isFocus ? focusMinutes : breakMinutes);

  double get progress {
    if (total.inSeconds == 0) return 0;
    return (1 - remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0).toDouble();
  }

  void selectTask(String? id) {
    taskId = id;
    notifyListeners();
  }

  void setDurations({int? focus, int? rest}) {
    if (running) return;
    focusMinutes = (focus ?? focusMinutes).clamp(1, 120).toInt();
    breakMinutes = (rest ?? breakMinutes).clamp(1, 60).toInt();
    remaining = total;
    notifyListeners();
  }

  void setPhase(bool focusPhase) {
    if (running) return;
    isFocus = focusPhase;
    remaining = total;
    notifyListeners();
  }

  Future<void> start() async {
    if (running) return;
    endsAt = DateTime.now().add(remaining);
    running = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
    try {
      await NotificationService.scheduleAt(
        _notificationId,
        isFocus ? 'زمان استراحت!' : 'استراحت تمام شد',
        isFocus ? 'جلسه تمرکز به پایان رسید.' : 'برگردید سر کار.',
        endsAt!,
      );
    } catch (_) {}
  }

  Future<void> pause() async {
    if (!running) return;
    _timer?.cancel();
    final left = endsAt!.difference(DateTime.now());
    remaining = left.isNegative ? Duration.zero : left;
    running = false;
    endsAt = null;
    notifyListeners();
    try {
      await NotificationService.cancelId(_notificationId);
    } catch (_) {}
  }

  Future<void> reset() async {
    _timer?.cancel();
    running = false;
    endsAt = null;
    remaining = total;
    notifyListeners();
    try {
      await NotificationService.cancelId(_notificationId);
    } catch (_) {}
  }

  /// Jumps to the other phase (focus <-> break) without counting a session.
  Future<void> skip() async {
    await reset();
    isFocus = !isFocus;
    remaining = total;
    notifyListeners();
  }

  void _tick() {
    final end = endsAt;
    if (!running || end == null) return;
    final left = end.difference(DateTime.now());
    if (left <= Duration.zero) {
      _complete();
    } else {
      remaining = left;
      notifyListeners();
    }
  }

  Future<void> _complete() async {
    _timer?.cancel();
    running = false;
    endsAt = null;
    if (isFocus) {
      sessions++;
      final id = taskId;
      if (id != null) await appState.addPomodoro(id);
    }
    isFocus = !isFocus;
    remaining = total;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoro = PomodoroController();
