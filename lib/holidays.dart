import 'package:shamsi_date/shamsi_date.dart';

/// A holiday or occasion on the Persian calendar.
class Occasion {
  const Occasion(this.title, {this.holiday = false, this.approx = false});

  final String title;
  final bool holiday;

  /// Lunar (Hijri) events depend on moon sighting, so the date may be off
  /// by a day.
  final bool approx;
}

const _solar = <(int, int), Occasion>{
  (1, 1): Occasion('جشن نوروز', holiday: true),
  (1, 2): Occasion('عید نوروز', holiday: true),
  (1, 3): Occasion('عید نوروز', holiday: true),
  (1, 4): Occasion('عید نوروز', holiday: true),
  (1, 12): Occasion('روز جمهوری اسلامی', holiday: true),
  (1, 13): Occasion('روز طبیعت (سیزده‌به‌در)', holiday: true),
  (2, 1): Occasion('روز بزرگداشت سعدی'),
  (2, 12): Occasion('روز معلم'),
  (2, 25): Occasion('روز بزرگداشت فردوسی'),
  (2, 28): Occasion('روز بزرگداشت خیام'),
  (3, 14): Occasion('رحلت امام خمینی', holiday: true),
  (3, 15): Occasion('قیام ۱۵ خرداد', holiday: true),
  (7, 8): Occasion('روز بزرگداشت مولوی'),
  (7, 20): Occasion('روز بزرگداشت حافظ'),
  (8, 13): Occasion('روز دانش‌آموز'),
  (9, 16): Occasion('روز دانشجو'),
  (11, 22): Occasion('پیروزی انقلاب اسلامی', holiday: true),
  (12, 29): Occasion('ملی شدن صنعت نفت', holiday: true),
};

const _lunar = <(int, int), String>{
  (1, 9): 'تاسوعای حسینی',
  (1, 10): 'عاشورای حسینی',
  (2, 20): 'اربعین حسینی',
  (2, 28): 'رحلت پیامبر و شهادت امام حسن',
  (2, 30): 'شهادت امام رضا',
  (3, 17): 'میلاد پیامبر و امام صادق',
  (6, 3): 'شهادت حضرت فاطمه',
  (7, 13): 'ولادت امام علی',
  (7, 27): 'مبعث پیامبر',
  (8, 15): 'ولادت امام زمان',
  (9, 21): 'شهادت امام علی',
  (10, 1): 'عید سعید فطر',
  (10, 2): 'تعطیل به مناسبت عید فطر',
  (10, 25): 'شهادت امام صادق',
  (12, 10): 'عید سعید قربان',
  (12, 18): 'عید سعید غدیر خم',
};

/// Tabular (Kuwaiti algorithm) Gregorian -> Hijri conversion.
({int year, int month, int day}) hijriOf(DateTime date, [int offset = 0]) {
  final utc = DateTime.utc(date.year, date.month, date.day + offset);
  final jdn = utc.millisecondsSinceEpoch ~/ 86400000 + 2440588;
  var days = jdn - 1948440 + 10632;
  final n = (days - 1) ~/ 10631;
  days = days - 10631 * n + 354;
  final j = ((10985 - days) ~/ 5316) * ((50 * days) ~/ 17719) +
      (days ~/ 5670) * ((43 * days) ~/ 15238);
  days = days -
      ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) +
      29;
  final m = (24 * days) ~/ 709;
  final d = days - (709 * m) ~/ 24;
  final y = 30 * n + j - 30;
  return (year: y, month: m, day: d);
}

/// All holidays and occasions on [date].
List<Occasion> occasionsOn(DateTime date, {int hijriOffset = 0}) {
  final out = <Occasion>[];
  final j = Jalali.fromDateTime(date);
  final s = _solar[(j.month, j.day)];
  if (s != null) out.add(s);

  final h = hijriOf(date, hijriOffset);
  var title = _lunar[(h.month, h.day)];
  if (title == null && h.month == 2 && h.day == 29) {
    // Safar with 29 days: the "30th" event falls on the last day.
    final next = hijriOf(date.add(const Duration(days: 1)), hijriOffset);
    if (next.day == 1) title = _lunar[(2, 30)];
  }
  if (title != null) {
    out.add(Occasion(title, holiday: true, approx: true));
  }
  return out;
}

/// True for official holidays and Fridays.
bool isHolidayDate(DateTime date, {int hijriOffset = 0}) =>
    date.weekday == DateTime.friday ||
    occasionsOn(date, hijriOffset: hijriOffset).any((o) => o.holiday);
