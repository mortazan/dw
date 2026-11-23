import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/jalali_calendar.dart' show weekdayLabels;
import '../widgets/task_tile.dart';
import 'notifications_page.dart';
import 'search_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
            children: [
              const _Header(),
              const SizedBox(height: 18),
              const _Greeting(),
              const SizedBox(height: 18),
              const _Stats(),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth >= 600) {
                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _WeeklyCard()),
                        SizedBox(width: 14),
                        Expanded(child: _CategoryCard()),
                      ],
                    );
                  }
                  return const Column(
                    children: [
                      _WeeklyCard(),
                      SizedBox(height: 14),
                      _CategoryCard(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _TodayCard(onSeeAll: onSeeAll),
            ],
          );
        },
      );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final badge = appState.overdue.length;
    final name = appState.userName.trim();
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [kPrimary, Color(0xFF9B83F5)]),
              ),
              child: Text(
                name.isEmpty ? '؟' : name.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimary, Color(0xFF9B83F5)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'DayFlow',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 104,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _roundButton(
                context,
                Icons.search,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                ),
              ),
              const SizedBox(width: 6),
              Badge(
                isLabelVisible: badge > 0,
                label: Text(toFa(badge)),
                child: _roundButton(
                  context,
                  Icons.notifications_none,
                  () => showNotificationsSheet(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roundButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) =>
      Material(
        color: pal(context).card,
        shape: CircleBorder(side: BorderSide(color: pal(context).border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon)),
        ),
      );
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سلام ${appState.userName}! 👋',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'چه روز خوبی برای انجام کارهای عالیه!',
          style: TextStyle(color: kMuted),
        ),
      ],
    );
    final dateChip = AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month, color: kBlue, size: 20),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jalaliWeekday(now),
                    style: const TextStyle(fontSize: 11, color: kMuted),
                  ),
                  Text(
                    jalaliDayMonthYear(now),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 400) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [greeting, const SizedBox(height: 12), dateChip],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: greeting), const SizedBox(width: 8), dateChip],
        );
      },
    );
  }
}

List<DateTime> _lastDays(int n) {
  final today = dayOnly(DateTime.now());
  return [
    for (var i = n - 1; i >= 0; i--) DateTime(today.year, today.month, today.day - i),
  ];
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    final all = appState.tasks;
    final now = DateTime.now();
    final today = appState.forDay(now);
    final days = _lastDays(7);
    // Newest day first, so the line reads right-to-left like the rest of the UI.
    List<double> series(bool Function(Task) test) => [
          for (final d in days.reversed)
            appState.tasks
                .where((t) => isSameDay(t.date, d) && test(t))
                .length
                .toDouble(),
        ];
    final importantTotal = all.where((t) => t.important).length;
    final importantPending = all.where((t) => t.important && !t.done).length;
    final upcoming = today.where((t) => !t.done && t.date.isAfter(now)).length;

    final cards = [
      _StatCard(
        icon: Icons.check_circle,
        color: kGreen,
        value: today.where((t) => t.done).length,
        label: 'کارهای امروز',
        sub: 'از ${toFa(today.length)}',
        series: series((t) => t.done),
      ),
      _StatCard(
        icon: Icons.schedule,
        color: kPurple,
        value: appState.overdue.length,
        label: 'کارهای به تعویق افتاده',
        sub: 'از ${toFa(all.where((t) => !t.done).length)} کار باز',
        series: series((t) => !t.done),
      ),
      _StatCard(
        icon: Icons.flag,
        color: kOrange,
        value: importantPending,
        label: 'کارهای مهم',
        sub: 'از ${toFa(importantTotal)}',
        series: series((t) => t.important),
      ),
      _StatCard(
        icon: Icons.event_available,
        color: kBlue,
        value: upcoming,
        label: 'کارهای پیش‌رو امروز',
        sub: 'از ${toFa(today.length)}',
        series: series((_) => true),
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 600 ? 4 : 2;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.sub,
    required this.series,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final String sub;
  final List<double> series;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              toFa(value),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            SizedBox(
              height: 34,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 11, color: kMuted)),
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              width: double.infinity,
              child: CustomPaint(painter: SparklinePainter(series, color)),
            ),
          ],
        ),
      );
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard();

  @override
  Widget build(BuildContext context) {
    final today = dayOnly(DateTime.now());
    // Weeks start on Saturday. DateTime.weekday: Mon=1 ... Sat=6, Sun=7.
    final offset = (today.weekday + 1) % 7;
    final start = DateTime(today.year, today.month, today.day - offset);
    final ratios = <double>[];
    var done = 0;
    var total = 0;
    for (var i = 0; i < 7; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      final list = appState.forDay(day);
      final d = list.where((t) => t.done).length;
      done += d;
      total += list.length;
      ratios.add(list.isEmpty ? 0 : d / list.length);
    }
    final percent = total == 0 ? 0.0 : done / total;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'پیشرفت هفتگی',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '٪${toFa((percent * 100).round())}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: kGreen,
                      ),
                    ),
                    const Text(
                      'درصد پیشرفت شما',
                      style: TextStyle(color: kMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: percent),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => CustomPaint(
                          painter: RingPainter(v, kGreen, pal(context).track),
                        ),
                      ),
                    ),
                    const Icon(Icons.emoji_events, color: kGreen, size: 28),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 16,
                          height: 8 + 54 * ratios[i],
                          decoration: BoxDecoration(
                            color: isSameDay(
                              DateTime(start.year, start.month, start.day + i),
                              today,
                            )
                                ? kGreen
                                : kGreen.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          weekdayLabels[i],
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard();

  @override
  Widget build(BuildContext context) {
    final counts = [
      for (final c in categories)
        appState.tasks.where((t) => catOf(t.category).name == c.name).length,
    ];
    final total = counts.fold<int>(0, (a, b) => a + b);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توزیع دسته‌بندی‌ها',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < categories.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: categories[i].color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                categories[i].name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              toFa(counts[i]),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 110,
                height: 110,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => CustomPaint(
                    painter: DonutPainter(
                      [for (final c in counts) c.toDouble()],
                      [for (final c in categories) c.color],
                      pal(context).track,
                      v,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'مجموع: ${toFa(total)} کار',
            style: const TextStyle(color: kMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final today = appState.forDay(DateTime.now());
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'کارهای امروز',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: const Text('مشاهده همه ‹'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (today.isEmpty)
            const EmptyState('برای امروز کاری ثبت نشده است')
          else
            for (final t in today) TaskTile(task: t),
        ],
      ),
    );
  }
}
