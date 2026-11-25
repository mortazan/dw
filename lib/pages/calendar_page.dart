import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../holidays.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/jalali_calendar.dart';
import '../widgets/task_tile.dart';
import '../widgets/week_strip.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, this.controller});

  final ScrollController? controller;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selected = DateTime.now();
  late DateTime viewed = selected;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final off = appState.hijriOffset;
          final tasks = appState.forDay(selected);
          final open = tasks.where((t) => !t.done).toList();
          final done = tasks.where((t) => t.done).toList();
          final dayEvents = occasionsOn(selected, hijriOffset: off);
          final vj = Jalali.fromDateTime(viewed);
          final monthEvents = <(int, Occasion)>[
            for (var d = 1; d <= vj.monthLength; d++)
              for (final o in occasionsOn(
                Jalali(vj.year, vj.month, d).toDateTime(),
                hijriOffset: off,
              ))
                (d, o),
          ];
          return ListView(
            controller: widget.controller,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            children: [
              const Text(
                'تقویم',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: WeekStrip(
                  days: [
                    for (var i = 0; i < 7; i++)
                      DateTime(
                        weekStart(selected).year,
                        weekStart(selected).month,
                        weekStart(selected).day + i,
                      ),
                  ],
                  selected: selected,
                  onTap: (d) => setState(() => selected = d),
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: JalaliCalendar(
                  key: ValueKey(jalaliMonthKey(selected)),
                  selected: selected,
                  onSelected: (d) => setState(() {
                    selected = d;
                    viewed = d;
                  }),
                  markerCount: (d) => appState.forDay(d).length,
                  isHoliday: (d) => isHolidayDate(d, hijriOffset: off),
                  onMonthChanged: (y, m) =>
                      setState(() => viewed = Jalali(y, m, 1).toDateTime()),
                ),
              ),
              if (monthEvents.isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مناسبت‌های این ماه',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      for (final e in monthEvents)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: e.$2.holiday ? const Color(0xFFE5484D) : kMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                toFa(e.$1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.$2.approx ? '${e.$2.title} (تقریبی)' : e.$2.title,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: e.$2.holiday ? const Color(0xFFE5484D) : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                jalaliLong(selected),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              for (final e in dayEvents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (e.holiday ? const Color(0xFFE5484D) : kPrimary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          e.holiday ? Icons.celebration_outlined : Icons.star_outline,
                          size: 18,
                          color: e.holiday ? const Color(0xFFE5484D) : kPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.holiday ? '${e.title} • تعطیل' : e.title,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (tasks.isEmpty)
                const EmptyState('برای این روز کاری ثبت نشده است')
              else ...[
                if (open.isNotEmpty) _section('در انتظار', open, kPrimary),
                if (done.isNotEmpty) _section('انجام‌شده', done, kGreen),
              ],
            ],
          );
        },
      );

  Widget _section(String title, List<Task> items, Color color) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$title (${toFa(items.length)})',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Divider(color: color.withValues(alpha: 0.25))),
                ],
              ),
            ),
            for (final t in items) TaskTile(task: t),
          ],
        ),
      );
}
