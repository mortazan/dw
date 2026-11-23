import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../theme.dart';
import '../utils.dart';

const weekdayLabels = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

/// A month grid for the Jalali (Persian) calendar. Weeks start on Saturday.
class JalaliCalendar extends StatefulWidget {
  const JalaliCalendar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.markerCount,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final int Function(DateTime day)? markerCount;

  @override
  State<JalaliCalendar> createState() => _JalaliCalendarState();
}

class _JalaliCalendarState extends State<JalaliCalendar> {
  late int year;
  late int month;

  @override
  void initState() {
    super.initState();
    final j = Jalali.fromDateTime(widget.selected);
    year = j.year;
    month = j.month;
  }

  void _shift(int delta) {
    var m = month + delta;
    var y = year;
    if (m > 12) {
      m = 1;
      y++;
    } else if (m < 1) {
      m = 12;
      y--;
    }
    setState(() {
      year = y;
      month = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final first = Jalali(year, month, 1);
    final lead = first.weekDay - 1;
    final length = first.monthLength;
    final rows = ((lead + length) / 7).ceil();
    final today = DateTime.now();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _shift(-1),
              icon: const Icon(Icons.chevron_right),
            ),
            Expanded(
              child: Center(
                child: Text(
                  toFa('${first.formatter.mN} $year'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _shift(1),
              icon: const Icon(Icons.chevron_left),
            ),
          ],
        ),
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++) _cell(r * 7 + c - lead + 1, length, today),
            ],
          ),
      ],
    );
  }

  Widget _cell(int day, int length, DateTime today) {
    if (day < 1 || day > length) {
      return const Expanded(child: AspectRatio(aspectRatio: 1, child: SizedBox()));
    }
    final date = Jalali(year, month, day).toDateTime();
    final selected = isSameDay(date, widget.selected);
    final isToday = isSameDay(date, today);
    final markers = widget.markerCount?.call(date) ?? 0;
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: selected ? kPrimary : null,
              shape: BoxShape.circle,
              border: isToday && !selected
                  ? Border.all(color: kPrimary, width: 1.4)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  toFa(day),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? Colors.white : null,
                  ),
                ),
                SizedBox(
                  height: 6,
                  child: markers > 0
                      ? Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : kPrimary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the Jalali calendar in a dialog and returns the chosen day.
Future<DateTime?> pickJalaliDate(BuildContext context, DateTime initial) {
  var selected = initial;
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              JalaliCalendar(
                selected: selected,
                onSelected: (d) => setState(() => selected = d),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('انصراف'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, selected),
                    child: const Text('تأیید'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
