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
      );

  Task copyWith({
    bool? done,
    bool? important,
    bool? spawned,
    List<SubTask>? subtasks,
  }) =>
      Task(
        id: id,
        title: title,
        date: date,
        category: category,
        note: note,
        done: done ?? this.done,
        important: important ?? this.important,
        imagePath: imagePath,
        audioPath: audioPath,
        reminder: reminder,
        repeat: repeat,
        spawned: spawned ?? this.spawned,
        subtasks: subtasks ?? this.subtasks,
      );
}
