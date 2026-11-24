class SubTask {
  const SubTask({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  SubTask copyWith({bool? done}) =>
      SubTask(id: id, title: title, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        id: json['id'] as String,
        title: json['title'] as String,
        done: (json['done'] ?? false) as bool,
      );
}

/// How a task repeats. A repeating task creates its next occurrence when it
/// is marked as done.
enum Repeat {
  none('بدون تکرار'),
  daily('روزانه'),
  weekly('هفتگی'),
  monthly('ماهانه');

  const Repeat(this.label);
  final String label;

  static Repeat parse(Object? value) => Repeat.values.firstWhere(
        (r) => r.name == value,
        orElse: () => Repeat.none,
      );
}

enum TaskPriority {
  none('بدون اولویت'),
  low('کم'),
  medium('متوسط'),
  high('زیاد');

  const TaskPriority(this.label);
  final String label;

  static TaskPriority parse(Object? value) => TaskPriority.values.firstWhere(
        (p) => p.name == value,
        orElse: () => TaskPriority.none,
      );
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    this.note = '',
    this.done = false,
    this.important = false,
    this.imagePath,
    this.audioPath,
    this.reminder,
    this.repeat = Repeat.none,
    this.spawned = false,
    this.subtasks = const [],
    this.priority = TaskPriority.none,
    this.tags = const [],
    this.remindBefore = const [],
    this.pomodoros = 0,
    this.alarm = false,
    this.alsoNotify = false,
    this.extra = const {},
    this.doneAt,
  });

  final String id;
  final String title;
  final String category;
  final DateTime date;
  final String note;
  final bool done;
  final bool important;
  final String? imagePath;
  final String? audioPath;
  final DateTime? reminder;
  final Repeat repeat;

  /// True once the next occurrence of a repeating task has been created.
  final bool spawned;
  final List<SubTask> subtasks;
  final TaskPriority priority;
  final List<String> tags;

  /// Extra reminders, in minutes before [date] (0 = at the task time).
  final List<int> remindBefore;

  /// Completed focus (pomodoro) sessions spent on this task.
  final int pomodoros;

  /// Ring like an alarm clock (loud, repeating) instead of a quiet notification.
  final bool alarm;

  /// With [alarm]: also post a normal notification at the same time.
  final bool alsoNotify;

  /// Values of the category's extra fields, keyed by field id.
  final Map<String, String> extra;

  /// When the task was completed (null while open).
  final DateTime? doneAt;

  int get subtasksDone => subtasks.where((s) => s.done).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'category': category,
        'note': note,
        'done': done,
        'important': important,
        'imagePath': imagePath,
        'audioPath': audioPath,
        'reminder': reminder?.toIso8601String(),
        'repeat': repeat.name,
        'spawned': spawned,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'priority': priority.name,
        'tags': tags,
        'remindBefore': remindBefore,
        'pomodoros': pomodoros,
        'alarm': alarm,
        'alsoNotify': alsoNotify,
        'extra': extra,
        'doneAt': doneAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        category: json['category'] as String,
        note: (json['note'] ?? '') as String,
        done: (json['done'] ?? false) as bool,
        important: (json['important'] ?? false) as bool,
        imagePath: json['imagePath'] as String?,
        audioPath: json['audioPath'] as String?,
        reminder: json['reminder'] == null
            ? null
            : DateTime.parse(json['reminder'] as String),
        repeat: Repeat.parse(json['repeat']),
        spawned: (json['spawned'] ?? false) as bool,
        subtasks: ((json['subtasks'] ?? []) as List<dynamic>)
            .map((e) => SubTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        priority: TaskPriority.parse(json['priority']),
        tags: ((json['tags'] ?? []) as List<dynamic>).cast<String>(),
        remindBefore:
            ((json['remindBefore'] ?? []) as List<dynamic>).cast<int>(),
        pomodoros: (json['pomodoros'] ?? 0) as int,
        alarm: (json['alarm'] ?? false) as bool,
        alsoNotify: (json['alsoNotify'] ?? false) as bool,
        extra: ((json['extra'] ?? {}) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v.toString())),
        doneAt: json['doneAt'] == null
            ? null
            : DateTime.parse(json['doneAt'] as String),
      );

  Task copyWith({
    String? category,
    bool? done,
    bool? important,
    bool? spawned,
    List<SubTask>? subtasks,
    int? pomodoros,
    DateTime? doneAt,
    bool clearDoneAt = false,
  }) =>
      Task(
        id: id,
        title: title,
        date: date,
        category: category ?? this.category,
        note: note,
        done: done ?? this.done,
        important: important ?? this.important,
        imagePath: imagePath,
        audioPath: audioPath,
        reminder: reminder,
        repeat: repeat,
        spawned: spawned ?? this.spawned,
        subtasks: subtasks ?? this.subtasks,
        priority: priority,
        tags: tags,
        remindBefore: remindBefore,
        pomodoros: pomodoros ?? this.pomodoros,
        alarm: alarm,
        alsoNotify: alsoNotify,
        extra: extra,
        doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
      );
}
