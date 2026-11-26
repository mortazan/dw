import 'package:shamsi_date/shamsi_date.dart';

import 'theme.dart';
import 'utils.dart';

/// The result of reading a quick-add sentence such as
/// «فردا ساعت ۵ تماس با علی».
class QuickResult {
  const QuickResult({
    required this.title,
    required this.date,
    required this.category,
    required this.important,
    required this.hasDate,
    required this.hasTime,
  });

  final String title;
  final DateTime date;
  final String category;
  final bool important;
  final bool hasDate;
  final bool hasTime;
}

const _l = r'(?<![؀-ۿ])';
const _r = r'(?![؀-ۿ])';

const _months = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

// Dart's DateTime.weekday: Monday = 1 ... Sunday = 7.
final _weekdays = <(String, int)>[
  ('یکشنبه', DateTime.sunday),
  ('دوشنبه', DateTime.monday),
  ('سه ?شنبه', DateTime.tuesday),
  ('چهار ?شنبه', DateTime.wednesday),
  ('پنج ?شنبه', DateTime.thursday),
  ('جمعه', DateTime.friday),
  ('شنبه', DateTime.saturday),
];

const _numWords = <String, int>{
  'یک': 1,
  'دو': 2,
  'سه': 3,
  'چهار': 4,
  'پنج': 5,
  'شش': 6,
  'شیش': 6,
  'هفت': 7,
  'هشت': 8,
  'نه': 9,
  'ده': 10,
  'یازده': 11,
  'دوازده': 12,
};

/// Voice input spells numbers out («ساعت پنج»); turn the common ones into digits.
String _wordsToDigits(String s) {
  final names = _numWords.keys.join('|');
  return s
      .replaceAllMapped(
        RegExp('${_l}ساعت ($names)$_r'),
        (m) => 'ساعت ${_numWords[m[1]]}',
      )
      .replaceAllMapped(
        RegExp('$_l($names) (?=روز (?:دیگر|بعد|دیگه))'),
        (m) => '${_numWords[m[1]]} ',
      )
      .replaceAllMapped(
        RegExp('$_l($names) (?=(?:صبح|ظهر|عصر|شب)$_r)'),
        (m) => '${_numWords[m[1]]} ',
      );
}

String _strip(String s, Match m) =>
    '${s.substring(0, m.start)} ${s.substring(m.end)}';

String _guessCategory(String text) {
  bool has(String p) => RegExp(p).hasMatch(text);
  String? pick;
  if (has('پیامک|اس ?ام ?اس')) {
    pick = 'پیامک';
  } else if (has('تماس|زنگ|تلفن')) {
    pick = 'تماس';
  } else if (has('بانک|قبض|وام|پرداخت|قسط')) {
    pick = 'بانکی';
  } else if (has('جلسه|پروژه|گزارش|ایمیل|ارائه')) {
    pick = 'کار';
  }
  if (pick != null && categories.any((c) => c.name == pick)) return pick;
  if (categories.any((c) => c.name == 'شخصی')) return 'شخصی';
  return categories.first.name;
}

/// Parses a simple Persian sentence into a task. Returns null when no title
/// is left after removing dates and times.
QuickResult? parseQuick(String input, [DateTime? clock]) {
  final now = clock ?? DateTime.now();
  final today = dayOnly(now);
  var s = ' ${_wordsToDigits(normalizeFa(input))} ';

  DateTime? day;

  // --- date -----------------------------------------------------------
  Match? m = RegExp('${_l}پس ?فردا$_r').firstMatch(s);
  if (m != null) {
    day = today.add(const Duration(days: 2));
    s = _strip(s, m);
  }
  if (day == null) {
    m = RegExp('${_l}فردا$_r').firstMatch(s);
    if (m != null) {
      day = today.add(const Duration(days: 1));
      s = _strip(s, m);
    }
  }
  if (day == null) {
    m = RegExp('${_l}امروز$_r').firstMatch(s);
    if (m != null) {
      day = today;
      s = _strip(s, m);
    }
  }
  if (day == null) {
    m = RegExp('(\\d{1,3}) ?روز (?:دیگر|بعد|دیگه)$_r').firstMatch(s);
    if (m != null) {
      day = today.add(Duration(days: int.parse(m[1]!)));
      s = _strip(s, m);
    }
  }
  if (day == null) {
    m = RegExp('${_l}هفته (?:بعد|آینده|دیگر|دیگه)$_r').firstMatch(s);
    if (m != null) {
      day = today.add(const Duration(days: 7));
      s = _strip(s, m);
    }
  }
  if (day == null) {
    final names = _months.join('|');
    m = RegExp('(\\d{1,2}) ?($names)$_r(?: (\\d{4}))?').firstMatch(s);
    if (m != null) {
      final jd = int.parse(m[1]!);
      final jm = _months.indexOf(m[2]!) + 1;
      final jNow = Jalali.fromDateTime(today);
      var jy = m[3] != null ? int.parse(m[3]!) : jNow.year;
      try {
        var cand = Jalali(jy, jm, jd).toDateTime();
        if (m[3] == null && cand.isBefore(today)) {
          jy++;
          cand = Jalali(jy, jm, jd).toDateTime();
        }
        day = cand;
        s = _strip(s, m);
      } catch (_) {}
    }
  }
  if (day == null) {
    m = RegExp(r'(?<!\d)(\d{4})/(\d{1,2})/(\d{1,2})(?!\d)').firstMatch(s);
    if (m != null) {
      final y = int.parse(m[1]!);
      final mo = int.parse(m[2]!);
      final d = int.parse(m[3]!);
      try {
        day = y < 1700 ? Jalali(y, mo, d).toDateTime() : DateTime(y, mo, d);
        s = _strip(s, m);
      } catch (_) {}
    }
  }
  if (day == null) {
    for (final w in _weekdays) {
      m = RegExp('${_l}${w.$1}$_r').firstMatch(s);
      if (m != null) {
        var diff = (w.$2 - today.weekday) % 7;
        if (diff == 0) diff = 7;
        day = today.add(Duration(days: diff));
        s = _strip(s, m);
        break;
      }
    }
  }

  // --- time -----------------------------------------------------------
  const periodPattern = '(صبح|ظهر|عصر|بعد ?از ?ظهر|شب)';
  final periodRe = RegExp('$_l$periodPattern$_r');
  int? hour;
  var minute = 0;
  String? period;

  m = RegExp(
    '${_l}ساعت ?(\\d{1,2})(?::(\\d{2}))?(?: ?و ?(نیم|ربع|\\d{1,2} ?دقیقه))?',
  ).firstMatch(s);
  if (m != null) {
    hour = int.parse(m[1]!);
    minute = m[2] != null ? int.parse(m[2]!) : 0;
    final extra = m[3];
    if (extra == 'نیم') {
      minute = 30;
    } else if (extra == 'ربع') {
      minute = 15;
    } else if (extra != null) {
      minute = int.parse(RegExp(r'\d+').firstMatch(extra)![0]!);
    }
    s = _strip(s, m);
  } else {
    m = RegExp(r'(?<!\d)(\d{1,2}):(\d{2})(?!\d)').firstMatch(s);
    if (m != null) {
      hour = int.parse(m[1]!);
      minute = int.parse(m[2]!);
      s = _strip(s, m);
    } else {
      m = RegExp('(?<!\\d)(\\d{1,2}) ?$periodPattern$_r').firstMatch(s);
      if (m != null) {
        hour = int.parse(m[1]!);
        period = m[2];
        s = _strip(s, m);
      }
    }
  }
  if (hour != null) {
    final pm = periodRe.firstMatch(s);
    if (pm != null) {
      period ??= pm[1];
      s = _strip(s, pm);
    }
    if (hour > 23 || minute > 59) {
      hour = null;
    } else if (period != null) {
      final p = period.replaceAll(' ', '');
      if (p == 'صبح') {
        if (hour == 12) hour = 0;
      } else if (p == 'ظهر') {
        if (hour < 6) hour += 12;
      } else if (p == 'شب') {
        if (hour == 12) {
          hour = 0;
        } else if (hour < 12) {
          hour += 12;
        }
      } else if (hour < 12) {
        hour += 12; // عصر / بعدازظهر
      }
    } else if (hour >= 1 && hour <= 6) {
      hour += 12;
    }
  }

  // --- importance -------------------------------------------------------
  var important = false;
  final im = RegExp('$_l(?:مهم|فوری|ضروری)$_r').firstMatch(s);
  if (im != null) {
    important = true;
    s = _strip(s, im);
  }

  // --- title ------------------------------------------------------------
  var title = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  title = title
      .replaceFirst(RegExp(r'^(?:در|برای|به|تا|و) '), '')
      .replaceFirst(RegExp(r' (?:در|برای|به|تا|و)$'), '')
      .trim();
  if (title.isEmpty) return null;

  // --- final date -------------------------------------------------------
  final hasDate = day != null;
  final hasTime = hour != null;
  late DateTime when;
  if (hasTime) {
    when = DateTime(
      (day ?? today).year,
      (day ?? today).month,
      (day ?? today).day,
      hour,
      minute,
    );
    if (!hasDate && when.isBefore(now)) {
      when = when.add(const Duration(days: 1));
    }
  } else {
    final base = day ?? today;
    final isToday = isSameDay(base, today);
    final h = isToday ? (now.hour + 1).clamp(0, 23).toInt() : 9;
    when = DateTime(base.year, base.month, base.day, h);
  }

  return QuickResult(
    title: toFa(title),
    date: when,
    category: _guessCategory(title),
    important: important,
    hasDate: hasDate,
    hasTime: hasTime,
  );
}
