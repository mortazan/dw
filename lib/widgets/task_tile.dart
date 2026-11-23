import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../pages/add_task_page.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, this.showDate = false});

  final Task task;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final cat = catOf(task.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF7F6FC),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showTaskDetails(context, task),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
            child: Row(
              children: [
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
                          color: task.done ? kGreen : const Color(0xFFB9B7C9),
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
                          color: task.done ? kMuted : kText,
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
                    color: task.important ? kOrange : const Color(0xFFB9B7C9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showTaskDetails(BuildContext context, Task task) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
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
                  if (task.important)
                    const Icon(Icons.star_rounded, color: kOrange),
                ],
              ),
              const SizedBox(height: 12),
              _line(Icons.category_outlined, cat.name, cat.color),
              _line(
                Icons.calendar_month_outlined,
                '${jalaliLong(task.date)} - ${timeText(task.date)}',
                kPrimary,
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
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await openTaskEditor(context, initial: task);
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
                      ),
                      onPressed: () async {
                        final ok = await confirmDelete(sheetContext, task);
                        if (ok && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
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
    },
  );
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

Future<bool> confirmDelete(BuildContext context, Task task) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('حذف کار'),
      content: Text('کار «${task.title}» حذف شود؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await appState.delete(task);
    return true;
  }
  return false;
}

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
