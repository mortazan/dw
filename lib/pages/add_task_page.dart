import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/app_service.dart';
import '../services/contact_service.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/field_actions.dart';
import '../widgets/jalali_calendar.dart';

/// Opens the add/edit screen and stores the result.
Future<void> openTaskEditor(
  BuildContext context, {
  Task? initial,
  Task? prefill,
  DateTime? day,
}) async {
  final task = await Navigator.push<Task>(
    context,
    MaterialPageRoute(
      builder: (_) => AddTaskPage(initial: initial, prefill: prefill, day: day),
    ),
  );
  if (task == null) return;
  if (initial == null) {
    await appState.add(task);
  } else {
    await appState.update(task);
  }
}

const _beforeOptions = [0, 10, 30, 60, 1440];

String _beforeLabel(int minutes) {
  if (minutes <= 0) return 'همان لحظه';
  if (minutes < 60) return '${toFa(minutes)} دقیقه قبل';
  if (minutes < 1440) return '${toFa(minutes ~/ 60)} ساعت قبل';
  return '${toFa(minutes ~/ 1440)} روز قبل';
}

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key, this.initial, this.prefill, this.day});

  final Task? initial;

  /// Values to start from when creating a new task (e.g. from quick add).
  final Task? prefill;
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
  final tagController = TextEditingController();

  late DateTime date;
  DateTime? reminder;
  late String category;
  late bool important;
  Repeat repeat = Repeat.none;
  List<SubTask> subtasks = [];
  TaskPriority priority = TaskPriority.none;
  List<String> tags = [];
  Set<int> remindBefore = {};
  bool alarm = false;
  bool alsoNotify = false;
  final Map<String, TextEditingController> fieldControllers = {};
  String? imagePath;
  String? audioPath;
  bool recording = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initial ?? widget.prefill;
    final now = DateTime.now();
    final base = widget.day ?? now;
    date = t?.date ??
        DateTime(base.year, base.month, base.day, now.hour, now.minute);
    reminder = t?.reminder;
    category = t == null ? categories.first.name : catOf(t.category).name;
    important = t?.important ?? false;
    repeat = t?.repeat ?? Repeat.none;
    priority = t?.priority ?? TaskPriority.none;
    tags = [...?t?.tags];
    remindBefore = {...?t?.remindBefore};
    alarm = t?.alarm ?? false;
    alsoNotify = t?.alsoNotify ?? false;
    for (final e in (t?.extra ?? const <String, String>{}).entries) {
      if (AppService.isApp(e.value)) {
        appValues[e.key] = e.value;
        fieldControllers[e.key] =
            TextEditingController(text: AppService.nameOf(e.value));
      } else {
        fieldControllers[e.key] = TextEditingController(text: e.value);
      }
    }
    subtasks = [...?t?.subtasks];
    imagePath = t?.imagePath;
    audioPath = t?.audioPath;
  }

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    subController.dispose();
    tagController.dispose();
    for (final c in fieldControllers.values) {
      c.dispose();
    }
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

  /// Fields where an installed app was chosen: field id -> `app:pkg|name`.
  final Map<String, String> appValues = {};

  String _valueOf(CatField f) {
    final text = _fieldController(f.id).text.trim();
    final app = appValues[f.id];
    if (app != null && text == AppService.nameOf(app)) return app;
    return text;
  }

  Future<void> _pickApp(CatField field) async {
    final app = await pickInstalledApp(context);
    if (app == null || !mounted) return;
    setState(() {
      appValues[field.id] = AppService.encode(app);
      _fieldController(field.id).text = app.name;
    });
  }

  TextEditingController _fieldController(String id) =>
      fieldControllers.putIfAbsent(id, () => TextEditingController());

  Future<void> _pickContact(CatField field) async {
    final contact = await ContactService.pick();
    if (contact == null || !mounted) return;
    setState(() {
      _fieldController(field.id).text = contact.phone;
      if (titleController.text.trim().isEmpty && contact.name.isNotEmpty) {
        titleController.text = '$category ${contact.name}';
      }
    });
  }

  void _addTag([String? value]) {
    final text = (value ?? tagController.text).trim().replaceAll('#', '');
    if (text.isEmpty || tags.contains(text)) {
      tagController.clear();
      return;
    }
    setState(() {
      tags = [...tags, text];
      tagController.clear();
    });
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
    final fields = catOf(category).fields;
    for (final f in fields) {
      if (f.required && _fieldController(f.id).text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('«${f.label}» الزامی است')),
        );
        return;
      }
    }
    if (recording) {
      final path = await recorder.stop();
      if (path != null) audioPath = path;
    }
    if (!mounted) return;
    // Keep a subtask that was typed but not yet added with the + button.
    final pendingTag = tagController.text.trim().replaceAll('#', '');
    final allTags = pendingTag.isEmpty || tags.contains(pendingTag)
        ? tags
        : [...tags, pendingTag];
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
        priority: priority,
        tags: allTags,
        remindBefore: (remindBefore.toList()..sort()),
        pomodoros: widget.initial?.pomodoros ?? 0,
        alarm: alarm,
        alsoNotify: alarm && alsoNotify,
        doneAt: widget.initial?.doneAt,
        extra: {
          for (final f in fields)
            if (_valueOf(f).isNotEmpty) f.id: _valueOf(f),
        },
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
            DropdownButtonFormField<String>(
              initialValue: categories.any((c) => c.name == category) ? category : null,
              isExpanded: true,
              decoration: _decoration('دسته‌بندی', Icons.folder_outlined),
              items: [
                for (final c in categories)
                  DropdownMenuItem(
                    value: c.name,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 20, color: c.color),
                        const SizedBox(width: 10),
                        Text(c.name),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => category = v);
              },
            ),
            for (final f in catOf(category).fields) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _fieldController(f.id),
                keyboardType: f.type == FieldType.phone
                    ? TextInputType.phone
                    : (f.type == FieldType.link ? TextInputType.url : TextInputType.text),
                textDirection: f.type == FieldType.text ? null : TextDirection.ltr,
                decoration: _decoration(
                  f.required ? '${f.label} *' : f.label,
                  fieldIcon(f.type),
                ).copyWith(
                  suffixIcon: f.type == FieldType.phone
                      ? IconButton(
                          tooltip: 'انتخاب از مخاطبین',
                          icon: Icon(Icons.contacts_outlined, color: kPrimary),
                          onPressed: () => _pickContact(f),
                        )
                      : (f.type == FieldType.link
                          ? IconButton(
                              tooltip: 'انتخاب از برنامه‌های نصب‌شده',
                              icon: Icon(Icons.apps, color: kPrimary),
                              onPressed: () => _pickApp(f),
                            )
                          : null),
                ),
              ),
            ],
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
            const Text('اولویت', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskPriority>(
              initialValue: priority,
              isExpanded: true,
              decoration: _decoration('اولویت', Icons.flag_outlined),
              items: [
                for (final p in TaskPriority.values)
                  DropdownMenuItem(
                    value: p,
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          size: 20,
                          color: p == TaskPriority.none ? kMuted : priorityColor(p),
                        ),
                        const SizedBox(width: 10),
                        Text(p.label),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => priority = v);
              },
            ),
            const SizedBox(height: 16),
            const Text('یادآور قبل از موعد', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _action(
              Icons.alarm_add_outlined,
              remindBefore.isEmpty
                  ? 'انتخاب کنید'
                  : (remindBefore.toList()..sort()).map(_beforeLabel).join('، '),
              _pickBefore,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: !alarm ? 0 : (alsoNotify ? 2 : 1),
              isExpanded: true,
              decoration: _decoration('نوع هشدار', Icons.alarm),
              items: const [
                DropdownMenuItem(
                  value: 0,
                  child: Row(children: [
                    Icon(Icons.notifications_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('اعلان ساده'),
                  ]),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Row(children: [
                    Icon(Icons.alarm, size: 20, color: kOrange),
                    SizedBox(width: 10),
                    Text('آلارم (مثل ساعت زنگ‌دار)'),
                  ]),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Row(children: [
                    Icon(Icons.notifications_active, size: 20, color: kOrange),
                    SizedBox(width: 10),
                    Text('هر دو (اعلان و آلارم)'),
                  ]),
                ),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() {
                  alarm = v != 0;
                  alsoNotify = v == 2;
                });
                if (v != 0) await NotificationService.requestExactAlarms();
              },
            ),
            const SizedBox(height: 8),
            const Text('برچسب‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final tag in tags)
                  InputChip(
                    label: Text('#$tag'),
                    onDeleted: () => setState(
                      () => tags = tags.where((x) => x != tag).toList(),
                    ),
                  ),
                for (final tag in appState.allTags.where((x) => !tags.contains(x)))
                  ActionChip(label: Text('#$tag'), onPressed: () => _addTag(tag)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tagController,
              onSubmitted: _addTag,
              decoration: _decoration('برچسب جدید', Icons.sell_outlined).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(Icons.add_circle, color: kPrimary),
                  onPressed: _addTag,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('تکرار', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Repeat>(
              initialValue: repeat,
              isExpanded: true,
              decoration: _decoration('تکرار', Icons.repeat),
              items: [
                for (final r in Repeat.values)
                  DropdownMenuItem(value: r, child: Text(r.label)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => repeat = v);
              },
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
                  icon: Icon(Icons.add_circle, color: kPrimary),
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

  Future<void> _pickBefore() async {
    final chosen = remindBefore.toSet();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('یادآور قبل از موعد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in _beforeOptions)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: chosen.contains(m),
                  title: Text(_beforeLabel(m)),
                  onChanged: (on) => setLocal(
                    () => on == true ? chosen.add(m) : chosen.remove(m),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تأیید'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() {
        remindBefore
          ..clear()
          ..addAll(chosen);
      });
    }
  }

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
