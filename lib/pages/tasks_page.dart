import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/task_tile.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  static const filters = [
    'همه',
    'امروز',
    'انجام‌نشده',
    'انجام‌شده',
    'مهم',
    'اولویت بالا',
  ];
  int filter = 0;
  String? tag;

  bool _match(Task t) {
    if (tag != null && !t.tags.contains(tag)) return false;
    switch (filter) {
      case 1:
        return isSameDay(t.date, DateTime.now());
      case 2:
        return !t.done;
      case 3:
        return t.done;
      case 4:
        return t.important;
      case 5:
        return t.priority == TaskPriority.high;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final list = appState.tasks.where(_match).toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            children: [
              const Text(
                'کارها',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ChoiceChip(
                    selected: filter == i,
                    onSelected: (_) => setState(() => filter = i),
                    label: Text(filters[i]),
                    selectedColor: pal(context).primarySoft,
                    backgroundColor: pal(context).card,
                  ),
                ),
              ),
              if (appState.allTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final t in appState.allTags)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: FilterChip(
                            selected: tag == t,
                            onSelected: (on) => setState(() => tag = on ? t : null),
                            label: Text('#$t'),
                            selectedColor: pal(context).primarySoft,
                            backgroundColor: pal(context).card,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (list.isEmpty)
                const EmptyState('کاری پیدا نشد')
              else
                for (final t in list) TaskTile(task: t, showDate: true),
            ],
          );
        },
      );
}

/// A simple list of the tasks selected by [filter], used for a category.
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key, required this.title, required this.filter});

  final String title;
  final bool Function(Task) filter;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final list = appState.tasks.where(filter).toList()
              ..sort((a, b) => a.date.compareTo(b.date));
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (list.isEmpty)
                  const EmptyState('کاری پیدا نشد')
                else
                  for (final t in list) TaskTile(task: t, showDate: true),
              ],
            );
          },
        ),
      );
}
