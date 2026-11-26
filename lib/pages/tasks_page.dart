import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/task_tile.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, this.controller});

  final ScrollController? controller;

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
  String query = '';
  final selected = <String>{};
  bool selecting = false;

  void _exitSelection() => setState(() {
        selecting = false;
        selected.clear();
      });

  bool _matchQuery(Task t) {
    final q = normalizeFa(query.trim());
    if (q.isEmpty) return true;
    final hay = [
      t.title,
      t.note,
      t.category,
      ...t.tags,
      ...t.extra.values,
    ].map(normalizeFa).join(' ');
    return hay.contains(q);
  }

  bool _match(Task t) {
    if (!_matchQuery(t)) return false;
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
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Column(
                  children: [
              if (selecting)
                Row(
                  children: [
                    IconButton(
                      onPressed: _exitSelection,
                      icon: const Icon(Icons.close),
                    ),
                    Expanded(
                      child: Text(
                        '${toFa(selected.length)} کار انتخاب شد',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'انتخاب همه',
                      onPressed: () => setState(() {
                        if (selected.length == list.length) {
                          selected.clear();
                        } else {
                          selected
                            ..clear()
                            ..addAll(list.map((t) => t.id));
                        }
                      }),
                      icon: const Icon(Icons.select_all),
                    ),
                    IconButton(
                      tooltip: 'حذف انتخاب‌شده‌ها',
                      color: const Color(0xFFE5484D),
                      onPressed: selected.isEmpty
                          ? null
                          : () async {
                              final items = [
                                for (final t in list)
                                  if (selected.contains(t.id)) t,
                              ];
                              _exitSelection();
                              await appState.deleteMany(items);
                            },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'کارها',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: 'انتخاب گروهی',
                      onPressed: () => setState(() => selecting = true),
                      icon: const Icon(Icons.checklist_rtl),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: 'جستجو در عنوان، یادداشت، برچسب، شماره...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: pal(context).card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: widget.controller,
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
                  children: [
              if (list.isEmpty)
                const EmptyState('کاری پیدا نشد')
              else
                for (final t in list)
                  TaskTile(
                    task: t,
                    showDate: true,
                    selected: selecting ? selected.contains(t.id) : null,
                    onSelect: () => setState(() {
                      if (!selected.add(t.id)) selected.remove(t.id);
                    }),
                    onLongPress: () => setState(() {
                      selecting = true;
                      selected.add(t.id);
                    }),
                  ),
                  ],
                ),
              ),
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
