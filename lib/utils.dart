import 'package:shamsi_date/shamsi_date.dart';

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
