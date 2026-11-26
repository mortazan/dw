import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../pages/add_task_page.dart';
import '../pages/pomodoro_page.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../services/app_service.dart';
import 'field_actions.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.showDate = false,
    this.selected,
    this.onSelect,
    this.onLongPress,
  });

  final Task task;
  final bool showDate;

  /// Non-null while the list is in selection mode.
  final bool? selected;
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final cat = catOf(task.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Dismissible(
          key: ValueKey('tile-${task.id}'),
          direction: selected != null
              ? DismissDirection.none
              : DismissDirection.horizontal,
          background: _swipeBackground(
            kGreen,
            task.done ? Icons.undo : Icons.check,
            AlignmentDirectional.centerStart,
          ),
          secondaryBackground: _swipeBackground(
            const Color(0xFFE5484D),
            Icons.delete_outline,
            AlignmentDirectional.centerEnd,
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Swipe to complete: keep the tile, only toggle its state.
              await appState.toggleDone(task);
              return false;
            }
            if (task.repeat == Repeat.none) return true;
            final choice = await askDeleteRepeating(context);
            if (choice == 'all') await appState.deleteSeries(task);
            return choice == 'one';
          },
          onDismissed: (_) => appState.deleteWithUndo(task),
          child: Material(
        color: pal(context).tile,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: selected != null ? onSelect : () => showTaskDetails(context, task),
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
            child: Row(
              children: [
                if (selected != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      selected! ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: selected! ? kPrimary : pal(context).inactive,
                      size: 28,
                    ),
                  )
                else
                GestureDetector(
                  onTap: () => appState.toggleDone(task),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.done ? kGreen : Colors.transparent,
                        border: Border.all(
                          color: task.done ? kGreen : pal(context).inactive,
                          width: 1.6,
                        ),
                      ),
                      child: task.done
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: task.done ? kMuted : null,
                          decoration:
                              task.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            task.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: kMuted, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat.icon, size: 13, color: cat.color),
                                const SizedBox(width: 4),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    color: cat.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: cat.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                showDate
                                    ? '${jalaliShort(task.date)}  ${timeText(task.date)}'
                                    : timeText(task.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kMuted,
                                ),
                              ),
                            ],
                          ),
                          if (task.subtasks.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.checklist, size: 14, color: kMuted),
                                const SizedBox(width: 3),
                                Text(
                                  '${toFa(task.subtasksDone)}/${toFa(task.subtasks.length)}',
                                  style: const TextStyle(fontSize: 12, color: kMuted),
                                ),
                              ],
                            ),
                          if (task.repeat != Repeat.none)
                            const Icon(Icons.repeat, size: 14, color: kMuted),
                          if (task.alarm)
                            const Icon(Icons.alarm, size: 15, color: kOrange),
                          for (final f in cat.fields)
                            if ((task.extra[f.id] ?? '').isNotEmpty &&
                                f.type != FieldType.text)
                              GestureDetector(
                                onTap: () => runFieldAction(context, f, task.extra[f.id]!),
                                child: Icon(
                                  fieldIcon(f.type),
                                  size: 17,
                                  color: kGreen,
                                ),
                              ),
                          if (task.priority != TaskPriority.none)
                            Icon(
                              Icons.flag_rounded,
                              size: 15,
                              color: priorityColor(task.priority),
                            ),
                          for (final tag in task.tags)
                            Text(
                              '#$tag',
                              style: TextStyle(fontSize: 11, color: kPrimary),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => appState.toggleImportant(task),
                  icon: Icon(
                    task.important ? Icons.star_rounded : Icons.star_border_rounded,
                    color: task.important ? kOrange : pal(context).inactive,
                  ),
                ),
              ],
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }
}

Widget _swipeBackground(Color color, IconData icon, AlignmentGeometry alignment) =>
    Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Icon(icon, color: Colors.white),
    );

Future<void> showTaskDetails(BuildContext context, Task task) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: pal(context).card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => ListenableBuilder(
      listenable: appState,
      builder: (innerContext, _) {
        // Always show the latest version of the task (e.g. after ticking a subtask).
        final t = appState.tasks.firstWhere(
          (x) => x.id == task.id,
          orElse: () => task,
        );
        return _TaskDetails(
          task: t,
          parentContext: context,
          sheetContext: sheetContext,
        );
      },
    ),
  );
}

class _TaskDetails extends StatelessWidget {
  const _TaskDetails({
    required this.task,
    required this.parentContext,
    required this.sheetContext,
  });

  final Task task;
  final BuildContext parentContext;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    final cat = catOf(task.category);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (task.important) const Icon(Icons.star_rounded, color: kOrange),
              ],
            ),
            const SizedBox(height: 12),
            _line(Icons.category_outlined, cat.name, cat.color),
            _line(
              Icons.calendar_month_outlined,
              '${jalaliLong(task.date)} - ${timeText(task.date)}',
              kPrimary,
            ),
            if (task.repeat != Repeat.none)
              _line(Icons.repeat, 'تکرار ${task.repeat.label}', kBlue),
            if (task.priority != TaskPriority.none)
              _line(
                Icons.flag_rounded,
                'اولویت ${task.priority.label}',
                priorityColor(task.priority),
              ),
            if (task.tags.isNotEmpty)
              _line(
                Icons.sell_outlined,
                task.tags.map((t) => '#$t').join('  '),
                kPrimary,
              ),
            if (task.remindBefore.isNotEmpty)
              _line(
                Icons.notifications_none,
                'یادآور قبل: ${task.remindBefore.map(_beforeText).join('، ')}',
                kOrange,
              ),
            if (task.alarm)
              _line(Icons.alarm, 'هشدار با زنگ فعال است', kOrange),
            for (final f in cat.fields)
              if ((task.extra[f.id] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: f.type == FieldType.phone
                      ? Material(
                          color: kGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () =>
                                runFieldAction(context, f, task.extra[f.id]!),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: kGreen.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: kGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.call,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f.label,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: kMuted,
                                          ),
                                        ),
                                        Text(
                                          toFa(task.extra[f.id]!),
                                          textDirection: TextDirection.ltr,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1,
                                            color: Color(0xFF1F8F57),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.sms_outlined, color: kGreen),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(fieldIcon(f.type), color: kGreen),
                          title: Text(
                            AppService.isApp(task.extra[f.id]!)
                                ? AppService.nameOf(task.extra[f.id]!)
                                : task.extra[f.id]!,
                          ),
                          subtitle: Text(f.label),
                          onTap: () => runFieldAction(context, f, task.extra[f.id]!),
                        ),
                ),
            if (task.pomodoros > 0)
              _line(
                Icons.timer_outlined,
                '${toFa(task.pomodoros)} جلسه تمرکز انجام شده',
                kGreen,
              ),
            if (task.reminder != null)
              _line(
                Icons.notifications_active_outlined,
                'یادآور: ${jalaliShort(task.reminder!)} ${timeText(task.reminder!)}',
                kOrange,
              ),
            const SizedBox(height: 8),
            Text(
              task.note.isEmpty ? 'بدون یادداشت' : task.note,
              style: const TextStyle(color: kMuted, height: 1.6),
            ),
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'زیرکارها (${toFa(task.subtasksDone)} از ${toFa(task.subtasks.length)})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: LinearProgressIndicator(
                    value: task.subtasksDone / task.subtasks.length,
                    minHeight: 6,
                    color: kGreen,
                    backgroundColor: kGreen.withValues(alpha: 0.15),
                  ),
                ),
              ),
              for (final s in task.subtasks)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: s.done,
                  onChanged: (_) => appState.toggleSubtask(task, s.id),
                  title: Text(
                    s.title,
                    style: TextStyle(
                      decoration: s.done ? TextDecoration.lineThrough : null,
                      color: s.done ? kMuted : null,
                    ),
                  ),
                ),
            ],
            if (task.imagePath != null && File(task.imagePath!).existsSync())
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(task.imagePath!)),
                ),
              ),
            if (task.audioPath != null && File(task.audioPath!).existsSync())
              AudioPlayButton(path: task.audioPath!),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: kGreen),
                    onPressed: () {
                      // Close first, then do the work.
                      Navigator.pop(sheetContext);
                      appState.toggleDone(task);
                    },
                    icon: Icon(task.done ? Icons.undo : Icons.check),
                    label: Text(task.done ? 'انجام‌نشده' : 'انجام شد'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        parentContext,
                        MaterialPageRoute(
                          builder: (_) => PomodoroPage(taskId: task.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('تمرکز'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await openTaskEditor(parentContext, initial: task);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('ویرایش'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE5484D),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Close the window immediately; "undo" appears as a snackbar.
                      Navigator.pop(sheetContext);
                      _delete(parentContext, task);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('حذف'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _beforeText(int minutes) {
  if (minutes <= 0) return 'همان لحظه';
  if (minutes < 60) return '${toFa(minutes)} دقیقه';
  if (minutes < 1440) return '${toFa(minutes ~/ 60)} ساعت';
  return '${toFa(minutes ~/ 1440)} روز';
}

Widget _line(IconData icon, String text, Color color) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );

class AudioPlayButton extends StatefulWidget {
  const AudioPlayButton({super.key, required this.path});

  final String path;

  @override
  State<AudioPlayButton> createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends State<AudioPlayButton> {
  final player = AudioPlayer();
  bool playing = false;

  @override
  void initState() {
    super.initState();
    player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playing = false);
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (playing) {
      await player.stop();
      setState(() => playing = false);
    } else {
      await player.play(DeviceFileSource(widget.path));
      setState(() => playing = true);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: _toggle,
        icon: Icon(playing ? Icons.stop : Icons.play_arrow),
        label: Text(playing ? 'توقف' : 'پخش یادداشت صوتی'),
      );
}

/// Asks what to delete for a repeating task: 'one', 'all' or null (cancel).
Future<String?> askDeleteRepeating(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف کار تکراری'),
        content: const Text('فقط همین کار حذف شود یا همه تکرارهای آن؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, 'one'),
            child: const Text('فقط این کار'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE5484D)),
            onPressed: () => Navigator.pop(dialogContext, 'all'),
            child: const Text('همه تکرارها'),
          ),
        ],
      ),
    );

Future<void> _delete(BuildContext context, Task task) async {
  if (task.repeat == Repeat.none) {
    await appState.deleteWithUndo(task);
    return;
  }
  final choice = await askDeleteRepeating(context);
  if (choice == 'one') await appState.deleteWithUndo(task);
  if (choice == 'all') await appState.deleteSeries(task);
}
