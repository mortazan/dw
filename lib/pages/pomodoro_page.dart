import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/pomodoro.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key, this.taskId});

  /// A task to focus on; null keeps the current selection.
  final String? taskId;

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  @override
  void initState() {
    super.initState();
    if (widget.taskId != null && !pomodoro.running) {
      pomodoro.taskId = widget.taskId;
    }
  }

  String _clock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return toFa('$m:$s');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تایمر تمرکز')),
        body: ListenableBuilder(
          listenable: Listenable.merge([pomodoro, appState]),
          builder: (context, _) {
            final color = pomodoro.isFocus ? kPrimary : kGreen;
            final openTasks = appState.tasks.where((t) => !t.done).toList()
              ..sort((a, b) => a.date.compareTo(b.date));
            final selected =
                openTasks.any((t) => t.id == pomodoro.taskId) ? pomodoro.taskId : null;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      selected: pomodoro.isFocus,
                      onSelected: (_) => pomodoro.setPhase(true),
                      label: const Text('تمرکز'),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      selected: !pomodoro.isFocus,
                      onSelected: (_) => pomodoro.setPhase(false),
                      label: const Text('استراحت'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CustomPaint(
                            painter: RingPainter(
                              pomodoro.progress,
                              color,
                              pal(context).track,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _clock(pomodoro.remaining),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              pomodoro.isFocus ? 'زمان تمرکز' : 'زمان استراحت',
                              style: const TextStyle(color: kMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: pomodoro.reset,
                      icon: const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: 18),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                      ),
                      onPressed: pomodoro.running ? pomodoro.pause : pomodoro.start,
                      icon: Icon(pomodoro.running ? Icons.pause : Icons.play_arrow),
                      label: Text(pomodoro.running ? 'توقف' : 'شروع'),
                    ),
                    const SizedBox(width: 18),
                    IconButton.filledTonal(
                      onPressed: pomodoro.skip,
                      icon: const Icon(Icons.skip_next),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'جلسه‌های کامل‌شده: ${toFa(pomodoro.sessions)}',
                    style: const TextStyle(color: kMuted),
                  ),
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String?>(
                        key: ValueKey(selected),
                        initialValue: selected,
                        decoration: const InputDecoration(
                          labelText: 'کار مورد تمرکز (اختیاری)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('بدون کار مشخص'),
                          ),
                          for (final t in openTasks)
                            DropdownMenuItem<String?>(
                              value: t.id,
                              child: Text(t.title, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: pomodoro.selectTask,
                      ),
                      const SizedBox(height: 12),
                      _stepper(
                        'مدت تمرکز',
                        pomodoro.focusMinutes,
                        (v) => pomodoro.setDurations(focus: v),
                      ),
                      _stepper(
                        'مدت استراحت',
                        pomodoro.breakMinutes,
                        (v) => pomodoro.setDurations(rest: v),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

  Widget _stepper(String label, int value, ValueChanged<int> onChanged) => Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            onPressed: pomodoro.running ? null : () => onChanged(value - 5 < 1 ? 1 : value - 5),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 70,
            child: Center(child: Text('${toFa(value)} دقیقه')),
          ),
          IconButton(
            onPressed: pomodoro.running ? null : () => onChanged(value + 5),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      );
}
