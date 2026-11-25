import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../models/task.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

/// The day a finished task counts for.
DateTime _doneDay(Task t) => dayOnly(t.doneAt ?? t.date);

({int current, int best}) _streaks(List<Task> tasks) {
  final days = {for (final t in tasks.where((t) => t.done)) _doneDay(t)};
  if (days.isEmpty) return (current: 0, best: 0);
  final sorted = days.toList()..sort();
  var best = 1;
  var run = 1;
  for (var i = 1; i < sorted.length; i++) {
    final gap = DateTime.utc(sorted[i].year, sorted[i].month, sorted[i].day)
        .difference(
          DateTime.utc(sorted[i - 1].year, sorted[i - 1].month, sorted[i - 1].day),
        )
        .inDays;
    run = gap == 1 ? run + 1 : 1;
    if (run > best) best = run;
  }
  // Current streak: counts back from today (or yesterday if today is empty).
  final today = dayOnly(DateTime.now());
  var cursor = days.contains(today) ? today : today.subtract(const Duration(days: 1));
  var current = 0;
  while (days.contains(cursor)) {
    current++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return (current: current, best: best);
}

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('آمار و پیشرفت')),
        body: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final tasks = appState.tasks;
            final done = tasks.where((t) => t.done).length;
            final rate = tasks.isEmpty ? 0.0 : done / tasks.length;
            final streak = _streaks(tasks);

            // Last 6 Jalali months.
            final now = Jalali.fromDateTime(DateTime.now());
            final months = <({String name, int total, int done})>[];
            for (var i = 5; i >= 0; i--) {
              var y = now.year;
              var mo = now.month - i;
              while (mo < 1) {
                mo += 12;
                y--;
              }
              final first = Jalali(y, mo, 1);
              final start = first.toDateTime();
              final end = Jalali(y, mo, first.monthLength).toDateTime();
              final end1 = DateTime(end.year, end.month, end.day + 1);
              final inMonth = tasks.where(
                (t) => !t.date.isBefore(start) && t.date.isBefore(end1),
              );
              months.add((
                name: first.formatter.mN,
                total: inMonth.length,
                done: inMonth.where((t) => t.done).length,
              ));
            }
            final maxTotal = months.fold<int>(1, (a, b) => b.total > a ? b.total : a);

            // Busiest categories.
            final counts = <String, int>{};
            for (final t in tasks) {
              counts[t.category] = (counts[t.category] ?? 0) + 1;
            }
            final ranked = counts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 84,
                        height: 84,
                        child: CustomPaint(
                          painter: RingPainter(rate, kPrimary, pal(context).track),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${toFa((rate * 100).round())}٪ انجام شده',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${toFa(done)} از ${toFa(tasks.length)} کار',
                              style: const TextStyle(color: kMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 38)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              streak.current == 0
                                  ? 'زنجیره را از امروز شروع کن'
                                  : '${toFa(streak.current)} روز متوالی',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'بهترین زنجیره: ${toFa(streak.best)} روز',
                              style: const TextStyle(color: kMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _motivation(streak.current),
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'روند ماهانه',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _dot(kPrimary.withValues(alpha: 0.25)),
                          const Text(' کل  ', style: TextStyle(fontSize: 12)),
                          _dot(kPrimary),
                          const Text(' انجام‌شده', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final mo in months)
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      toFa(mo.done),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 22,
                                      height: 100 * mo.total / maxTotal + 2,
                                      alignment: Alignment.bottomCenter,
                                      decoration: BoxDecoration(
                                        color: kPrimary.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Container(
                                        height: mo.total == 0
                                            ? 0
                                            : (100 * mo.total / maxTotal + 2) *
                                                mo.done /
                                                mo.total,
                                        decoration: BoxDecoration(
                                          color: kPrimary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      mo.name,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: kMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ranked.isEmpty
                            ? 'پرکارترین دسته'
                            : 'پرکارترین دسته: ${ranked.first.key}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (ranked.isEmpty)
                        const Text('هنوز کاری ثبت نشده', style: TextStyle(color: kMuted)),
                      for (final e in ranked)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70,
                                child: Text(e.key, style: const TextStyle(fontSize: 13)),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: e.value / ranked.first.value,
                                    minHeight: 10,
                                    color: catOf(e.key).color,
                                    backgroundColor: pal(context).track,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(toFa(e.value)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

  static Widget _dot(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
      );

  static String _motivation(int days) {
    if (days == 0) return 'امروز یک کار را تمام کن تا زنجیره شروع شود.';
    if (days < 3) return 'شروع خوبی است، ادامه بده!';
    if (days < 7) return 'عالی! زنجیره‌ات را نشکن.';
    if (days < 30) return 'یک هفته و بیشتر؛ حرفه‌ای شده‌ای 💪';
    return 'باورنکردنی! یک ماه پشت‌سرهم.';
  }
}
