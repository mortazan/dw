import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/task_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: TextField(
            autofocus: true,
            onChanged: (v) => setState(() => query = v.trim()),
            decoration: const InputDecoration(
              hintText: 'جستجوی کارها...',
              border: InputBorder.none,
            ),
          ),
        ),
        body: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final results = query.isEmpty
                ? appState.tasks
                : appState.tasks
                    .where((t) =>
                        t.title.contains(query) ||
                        t.note.contains(query) ||
                        t.category.contains(query))
                    .toList();
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (results.isEmpty)
                  const EmptyState('نتیجه‌ای پیدا نشد')
                else
                  for (final t in results) TaskTile(task: t, showDate: true),
              ],
            );
          },
        ),
      );
}
