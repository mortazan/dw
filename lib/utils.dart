import 'package:shamsi_date/shamsi_date.dart';

import 'models/task.dart';

const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// Converts any digits in [value] to Persian digits.
String toFa(Object value) => value
    .toString()
    .replaceAllMapped(RegExp(r'[0-9]'), (m) => _faDigits[int.parse(m[0]!)]);

String _two(int n) => n.toString().padLeft(2, '0');

String timeText(DateTime d) => toFa('${_two(d.hour)}:${_two(d.minute)}');

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String jalaliLong(DateTime d) {
  final f = Jalali.fromDateTime(d).formatter;
  return toFa('${f.wN}، ${f.d} ${f.mN} ${f.yyyy}');
}

String jalaliShort(DateTime d) {
  final f = Jalali.fromDateTime(d).formatter;
  return toFa('${f.yyyy}/${f.mm}/${f.dd}');
}

String jalaliWeekday(DateTime d) => Jalali.fromDateTime(d).formatter.wN;

String jalaliDayMonthYear(DateTime d) {
  final f = Jalali.fromDateTime(d).formatter;
  return toFa('${f.d} ${f.mN} ${f.yyyy}');
}

/// The next date after [date] for a repeating task, keeping the time of day.
/// Monthly repeats follow the Jalali calendar.
DateTime nextOccurrence(DateTime date, Repeat repeat) {
  switch (repeat) {
    case Repeat.daily:
      return DateTime(date.year, date.month, date.day + 1, date.hour, date.minute);
    case Repeat.weekly:
      return DateTime(date.year, date.month, date.day + 7, date.hour, date.minute);
    case Repeat.monthly:
      final j = Jalali.fromDateTime(date);
      final y = j.month == 12 ? j.year + 1 : j.year;
      final m = j.month == 12 ? 1 : j.month + 1;
      final d = j.day > Jalali(y, m, 1).monthLength
          ? Jalali(y, m, 1).monthLength
          : j.day;
      final g = Jalali(y, m, d).toDateTime();
      return DateTime(g.year, g.month, g.day, date.hour, date.minute);
    case Repeat.none:
      return date;
  }
}

/// The Saturday that starts the (Persian) week containing [d].
DateTime weekStart(DateTime d) {
  // DateTime.weekday: Mon=1 ... Sat=6, Sun=7.
  final offset = (d.weekday + 1) % 7;
  return DateTime(d.year, d.month, d.day - offset);
}

int jalaliDay(DateTime d) => Jalali.fromDateTime(d).day;

String jalaliMonthKey(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${j.year}-${j.month}';
}

/// Unifies Arabic/Persian letter variants, digits and ZWNJ for matching.
String normalizeFa(String input) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final r in input.runes) {
    var c = String.fromCharCode(r);
    final i = fa.indexOf(c);
    final j = ar.indexOf(c);
    if (i >= 0) {
      c = '$i';
    } else if (j >= 0) {
      c = '$j';
    } else if (c == 'ي') {
      c = 'ی';
    } else if (c == 'ك') {
      c = 'ک';
    } else if (c == '\u200c') {
      c = ' ';
    }
    b.write(c);
  }
  return b.toString().toLowerCase();
}
