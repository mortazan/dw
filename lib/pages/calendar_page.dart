import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/jalali_calendar.dart';
import '../widgets/task_tile.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selected = DateTime.now();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final tasks = appState.forDay(selected);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            children: [
              const Text(
                'تقویم',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: JalaliCalendar(
                  selected: selected,
                  onSelected: (d) => setState(() => selected = d),
                  markerCount: (d) => appState.forDay(d).length,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                jalaliLong(selected),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (tasks.isEmpty)
                const EmptyState('برای این روز کاری ثبت نشده است')
              else
                for (final t in tasks) TaskTile(task: t),
            ],
          );
        },
      );
}
