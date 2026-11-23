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
      );

  Task copyWith({bool? done, bool? important}) => Task(
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
      );
}
