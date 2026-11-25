import 'dart:async';

import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../utils.dart';

/// Full-screen alarm, like a clock app: big time, the task and two buttons.
class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key, required this.info});

  final AlarmInfo info;

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> with SingleTickerProviderStateMixin {
  late final Timer _clock;
  late final AnimationController _pulse;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _clock.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _stop() async {
    await NotificationService.stopAlarm(widget.info);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _snooze() async {
    await NotificationService.snoozeAlarm(widget.info);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFF14111F),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: Tween(begin: 0.9, end: 1.1).animate(_pulse),
                    child: const Icon(Icons.alarm, size: 84, color: Color(0xFFFFA726)),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    timeText(now),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    jalaliLong(now),
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    widget.info.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.info.body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.info.body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE5484D),
                      ),
                      onPressed: _stop,
                      icon: const Icon(Icons.alarm_off),
                      label: const Text('متوقف کن', style: TextStyle(fontSize: 17)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      onPressed: _snooze,
                      icon: const Icon(Icons.snooze),
                      label: Text('${toFa(10)} دقیقه بعد'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
