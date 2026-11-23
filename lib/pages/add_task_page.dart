import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/jalali_calendar.dart';

/// Opens the add/edit screen and stores the result.
Future<void> openTaskEditor(
  BuildContext context, {
  Task? initial,
  DateTime? day,
}) async {
  final task = await Navigator.push<Task>(
    context,
    MaterialPageRoute(builder: (_) => AddTaskPage(initial: initial, day: day)),
  );
  if (task == null) return;
  if (initial == null) {
    await appState.add(task);
  } else {
    await appState.update(task);
  }
}

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key, this.initial, this.day});

  final Task? initial;
  final DateTime? day;

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  late final titleController =
      TextEditingController(text: widget.initial?.title ?? '');
  late final noteController =
      TextEditingController(text: widget.initial?.note ?? '');
  final recorder = AudioRecorder();
  final subController = TextEditingController();

  late DateTime date;
  DateTime? reminder;
  late String category;
  late bool important;
  Repeat repeat = Repeat.none;
  List<SubTask> subtasks = [];
  String? imagePath;
  String? audioPath;
  bool recording = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    final now = DateTime.now();
    final base = widget.day ?? now;
    date = t?.date ??
        DateTime(base.year, base.month, base.day, now.hour, now.minute);
    reminder = t?.reminder;
    category = t == null ? categories.first.name : catOf(t.category).name;
    important = t?.important ?? false;
    repeat = t?.repeat ?? Repeat.none;
    subtasks = [...?t?.subtasks];
    imagePath = t?.imagePath;
    audioPath = t?.audioPath;
  }

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    subController.dispose();
    recorder.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await pickJalaliDate(context, date);
    if (picked == null) return;
    setState(() {
      date = DateTime(picked.year, picked.month, picked.day, date.hour, date.minute);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );
    if (picked == null) return;
    setState(() {
      date = DateTime(date.year, date.month, date.day, picked.hour, picked.minute);
    });
  }

  Future<void> _pickReminder() async {
    final pickedDate = await pickJalaliDate(context, reminder ?? date);
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(reminder ?? date),
    );
    if (pickedTime == null) return;
    setState(() {
      reminder = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    // The picker returns a cache path that can be cleared later; keep a copy.
    final directory = await getApplicationDocumentsDirectory();
    final dot = picked.path.lastIndexOf('.');
    final ext = dot == -1 ? 'jpg' : picked.path.substring(dot + 1);
    final saved = await File(picked.path)
        .copy('${directory.path}/${const Uuid().v4()}.$ext');
    if (!mounted) return;
    setState(() => imagePath = saved.path);
  }

  Future<void> _toggleRecording() async {
    if (recording) {
      final path = await recorder.stop();
      setState(() {
        recording = false;
        if (path != null) audioPath = path;
      });
      return;
    }
    if (await recorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${const Uuid().v4()}.m4a';
      await recorder.start(const RecordConfig(), path: path);
      setState(() => recording = true);
    }
  }

  void _addSubtask() {
    final text = subController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      subtasks = [
        ...subtasks,
        SubTask(id: const Uuid().v4(), title: text),
      ];
      subController.clear();
    });
  }

  Future<void> _save() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان کار را وارد کنید')),
      );
      return;
    }
    if (recording) {
      final path = await recorder.stop();
      if (path != null) audioPath = path;
    }
    if (!mounted) return;
    // Keep a subtask that was typed but not yet added with the + button.
    final pending = subController.text.trim();
    final allSubtasks = pending.isEmpty
        ? subtasks
        : [...subtasks, SubTask(id: const Uuid().v4(), title: pending)];
    Navigator.pop(
      context,
      Task(
        id: widget.initial?.id ?? const Uuid().v4(),
        title: titleController.text.trim(),
        date: date,
        category: category,
        note: noteController.text.trim(),
        done: widget.initial?.done ?? false,
        spawned: widget.initial?.spawned ?? false,
        repeat: repeat,
        subtasks: allSubtasks,
        important: important,
        imagePath: imagePath,
        audioPath: audioPath,
        reminder: reminder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.initial == null ? 'افزودن کار' : 'ویرایش کار'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextField(
              controller: titleController,
              decoration: _decoration('عنوان کار', Icons.edit_outlined),
            ),
            const SizedBox(height: 16),
            const Text('دسته‌بندی', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    selected: category == c.name,
                    onSelected: (_) => setState(() => category = c.name),
                    avatar: Icon(c.icon, size: 16, color: c.color),
                    label: Text(c.name),
                    selectedColor: c.color.withValues(alpha: 0.18),
                    backgroundColor: pal(context).card,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _action(Icons.calendar_month, 'تاریخ: ${jalaliLong(date)}', _pickDate),
            _action(Icons.access_time, 'ساعت: ${timeText(date)}', _pickTime),
            _action(
              Icons.notifications_active_outlined,
              reminder == null
                  ? 'تنظیم یادآور'
                  : 'یادآور: ${jalaliShort(reminder!)} ${timeText(reminder!)}',
              _pickReminder,
              onClear: reminder == null ? null : () => setState(() => reminder = null),
            ),
            const SizedBox(height: 8),
            const Text('تکرار', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in Repeat.values)
                  ChoiceChip(
                    selected: repeat == r,
                    onSelected: (_) => setState(() => repeat = r),
                    label: Text(r.label),
                    selectedColor: pal(context).primarySoft,
                    backgroundColor: pal(context).card,
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: important,
              onChanged: (v) => setState(() => important = v),
              title: const Text('کار مهم'),
              secondary: Icon(
                important ? Icons.star_rounded : Icons.star_border_rounded,
                color: kOrange,
              ),
            ),
            const SizedBox(height: 8),
            const Text('زیرکارها', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final s in subtasks)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: pal(context).card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: pal(context).border),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    s.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: s.done ? kGreen : kMuted,
                    size: 20,
                  ),
                  title: Text(s.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(
                      () => subtasks = subtasks.where((x) => x.id != s.id).toList(),
                    ),
                  ),
                ),
              ),
            TextField(
              controller: subController,
              onSubmitted: (_) => _addSubtask(),
              decoration: _decoration('افزودن زیرکار', Icons.add_task).copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: kPrimary),
                  onPressed: _addSubtask,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              maxLines: 4,
              decoration: _decoration('یادداشت', Icons.notes_outlined),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(imagePath == null ? 'افزودن تصویر' : 'تصویر انتخاب شد'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _toggleRecording,
              icon: Icon(recording ? Icons.stop : Icons.mic_none),
              label: Text(recording ? 'توقف ضبط' : 'ضبط یادداشت صوتی'),
            ),
            if (audioPath != null && !recording)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('یادداشت صوتی ذخیره شد', style: TextStyle(color: kMuted)),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('ذخیره کار'),
            ),
          ],
        ),
      );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: pal(context).card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: pal(context).border),
        ),
      );

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    VoidCallback? onClear,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  alignment: AlignmentDirectional.centerStart,
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              ),
            ),
            if (onClear != null)
              IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
          ],
        ),
      );
}
