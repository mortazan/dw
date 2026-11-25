import 'package:flutter/material.dart';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../quick_add.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../state/pomodoro.dart';
import '../widgets/jalali_calendar.dart' show weekdayLabels;
import '../widgets/media_slider.dart';
import '../widgets/task_tile.dart';
import '../widgets/week_strip.dart';
import 'notifications_page.dart';
import 'pomodoro_page.dart';
import 'add_task_page.dart';
import 'search_page.dart';
import 'stats_page.dart';
import 'tasks_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.onSeeAll, this.controller});

  final VoidCallback onSeeAll;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                child: _Header(),
              ),
              Expanded(
                child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
            children: [
              _Greeting(),
              const SizedBox(height: 12),
              const _QuickAdd(),
              const SizedBox(height: 14),
              _Stats(),
              const SizedBox(height: 12),
              _WeekCard(),
              const SizedBox(height: 12),
              _FocusCard(),
              const SizedBox(height: 12),
              AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('🔥', style: TextStyle(fontSize: 28)),
                  title: const Text('آمار و روند ماهیانه'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatsPage()),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth >= 600) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _WeeklyCard()),
                        const SizedBox(width: 14),
                        Expanded(child: _CategoryCard()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _WeeklyCard(),
                      const SizedBox(height: 14),
                      _CategoryCard(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _TodayCard(onSeeAll: onSeeAll),
            ],
          ),
              ),
            ],
          );
        },
      );
}

class _Header extends StatelessWidget {
  _Header();

  @override
  Widget build(BuildContext context) {
    final badge = appState.overdue.length;
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: GestureDetector(
              onTap: () => showAvatarOptions(context),
              child: UserAvatar(size: 46),
            ),
          ),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary, Color(0xFF9B83F5)],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.timelapse_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'مدیریت زمان',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 96,
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
  _Greeting();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'سلام ${appState.userName}! 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month, color: kBlue, size: 18),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jalaliWeekday(now),
                        style: const TextStyle(fontSize: 10.5, color: kMuted),
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
            ),
          ],
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => editGreeting(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  appState.greeting,
                  style: const TextStyle(color: kMuted, fontSize: 13),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_outlined, size: 13, color: kMuted),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MediaSlider(),
      ],
    );
  }
}

void _openList(
  BuildContext context,
  String title,
  bool Function(Task) filter,
) =>
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskListScreen(title: title, filter: filter),
      ),
    );

class _Stats extends StatelessWidget {
  _Stats();

  @override
  Widget build(BuildContext context) {
    final all = appState.tasks;
    final now = DateTime.now();
    final today = appState.forDay(now);
    final importantTotal = all.where((t) => t.important).length;
    final importantPending = all.where((t) => t.important && !t.done).length;
    final upcoming = today.where((t) => !t.done && t.date.isAfter(now)).length;

    final cards = [
      _StatCard(
        icon: Icons.check_circle,
        color: kGreen,
        value: today.where((t) => t.done).length,
        suffix: 'از ${toFa(today.length)} کار',
        label: 'کارهای امروز',
        onTap: () => _openList(
          context,
          'کارهای امروز',
          (t) => isSameDay(t.date, DateTime.now()),
        ),
      ),
      _StatCard(
        icon: Icons.schedule,
        color: kPurple,
        value: appState.overdue.length,
        suffix: 'کار',
        label: 'عقب‌افتاده',
        onTap: () => _openList(
          context,
          'کارهای به تعویق افتاده',
          (t) => !t.done && t.date.isBefore(dayOnly(DateTime.now())),
        ),
      ),
      _StatCard(
        icon: Icons.flag,
        color: kOrange,
        value: importantPending,
        suffix: 'از ${toFa(importantTotal)} کار',
        label: 'کارهای مهم',
        onTap: () => _openList(context, 'کارهای مهم', (t) => t.important),
      ),
      _StatCard(
        icon: Icons.event_available,
        color: kBlue,
        value: upcoming,
        suffix: 'از ${toFa(today.length)} کار',
        label: 'پیش‌رو امروز',
        onTap: () => _openList(
          context,
          'کارهای پیش‌رو امروز',
          (t) =>
              !t.done &&
              isSameDay(t.date, DateTime.now()) &&
              t.date.isAfter(DateTime.now()),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 600 ? 4 : 2;
        const gap = 10.0;
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

/// A compact card: icon, then the main number (large) with its context beside
/// it, and the title underneath.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.suffix,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String suffix;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            toFa(value),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              suffix,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: kMuted),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _WeekCard extends StatelessWidget {
  _WeekCard();

  @override
  Widget build(BuildContext context) {
    final today = dayOnly(DateTime.now());
    final start = weekStart(today);
    // Today and the rest of the week (the week ends on Friday).
    final days = [
      for (var i = 0; i < 7; i++) DateTime(start.year, start.month, start.day + i),
    ].where((d) => !d.isBefore(today)).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'روزهای باقی‌مانده هفته',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          WeekStrip(
            days: days,
            onTap: (d) => _openList(
              context,
              jalaliLong(d),
              (t) => isSameDay(t.date, d),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  _FocusCard();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: pomodoro,
        builder: (context, _) {
          final m = pomodoro.remaining.inMinutes.toString().padLeft(2, '0');
          final s = (pomodoro.remaining.inSeconds % 60).toString().padLeft(2, '0');
          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PomodoroPage()),
            ),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.timer_outlined, color: kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تایمر تمرکز',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          pomodoro.running
                              ? '${pomodoro.isFocus ? 'تمرکز' : 'استراحت'} در حال اجرا · ${toFa('$m:$s')}'
                              : '${toFa(pomodoro.focusMinutes)} دقیقه تمرکز، ${toFa(pomodoro.breakMinutes)} دقیقه استراحت',
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    pomodoro.running ? Icons.pause_circle : Icons.play_circle_fill,
                    color: kPrimary,
                    size: 32,
                  ),
                ],
              ),
            ),
          );
        },
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

/// One-line quick add: «فردا ساعت ۵ تماس با علی».
class _QuickAdd extends StatefulWidget {
  const _QuickAdd();

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  final controller = TextEditingController();
  final _speech = SpeechToText();
  bool listening = false;

  Future<void> _listen() async {
    if (listening) {
      await _speech.stop();
      if (mounted) setState(() => listening = false);
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() => listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => listening = false);
      },
    );
    if (!ok) {
      messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('تشخیص گفتار در این دستگاه در دسترس نیست')),
      );
      return;
    }
    setState(() => listening = true);
    await _speech.listen(
      localeId: 'fa_IR',
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (r) {
        controller.value = TextEditingValue(
          text: r.recognizedWords,
          selection: TextSelection.collapsed(offset: r.recognizedWords.length),
        );
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final r = parseQuick(controller.text);
    if (r == null) return;
    final task = Task(
      id: const Uuid().v4(),
      title: r.title,
      date: r.date,
      category: r.category,
      important: r.important,
      priority: r.important ? TaskPriority.high : TaskPriority.none,
    );
    controller.clear();
    setState(() {});
    final needsFields = catOf(r.category).fields.any((f) => f.required);
    if (needsFields) {
      await openTaskEditor(context, prefill: task);
    } else {
      await appState.add(task);
      messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('«${r.title}» اضافه شد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = controller.text.trim().isEmpty ? null : parseQuick(controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'ثبت سریع: فردا ساعت ۵ تماس با علی',
            prefixIcon: Icon(Icons.bolt, color: kPrimary),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'ثبت صوتی',
                  icon: Icon(
                    listening ? Icons.mic : Icons.mic_none,
                    color: listening ? const Color(0xFFE5484D) : kPrimary,
                  ),
                  onPressed: _listen,
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: kPrimary),
                  onPressed: _submit,
                ),
              ],
            ),
            filled: true,
            fillColor: pal(context).card,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (r != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Text(
              '${r.title} • ${jalaliShort(r.date)} ${timeText(r.date)} • ${r.category}${r.important ? ' • مهم' : ''}',
              style: const TextStyle(color: kMuted, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}
