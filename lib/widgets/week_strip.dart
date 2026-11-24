import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import 'jalali_calendar.dart' show weekdayLabels;

/// A row of days (weekday letter, Jalali day number and the number of open
/// tasks). Tapping a day calls [onTap].
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.days,
    required this.onTap,
    this.selected,
  });

  final List<DateTime> days;
  final DateTime? selected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Row(
      children: [
        for (final d in days)
          Expanded(child: _cell(context, d, isSameDay(d, today))),
      ],
    );
  }

  Widget _cell(BuildContext context, DateTime d, bool isToday) {
    final isSelected = selected != null && isSameDay(d, selected!);
    final open = appState.forDay(d).where((t) => !t.done).length;
    final total = appState.forDay(d).length;
    final active = isSelected || (selected == null && isToday);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(d),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? kPrimary : pal(context).tile,
          borderRadius: BorderRadius.circular(16),
          border: isToday && !active ? Border.all(color: kPrimary, width: 1.2) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekdayLabels[(d.weekday + 1) % 7],
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white70 : kMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              toFa(jalaliDay(d)),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: open > 0
                    ? (active ? Colors.white : kPrimary)
                    : (active ? Colors.white24 : pal(context).border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                toFa(open > 0 ? open : total),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: open > 0
                      ? (active ? kPrimary : Colors.white)
                      : (active ? Colors.white : kMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
