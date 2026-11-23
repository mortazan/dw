import 'package:flutter/material.dart';

const kPrimary = Color(0xFF6C47E8);
const kPrimarySoft = Color(0xFFEEE9FF);
const kBg = Color(0xFFF7F6FB);
const kText = Color(0xFF1E1B3A);
const kMuted = Color(0xFF8A88A0);
const kGreen = Color(0xFF3CC47C);
const kOrange = Color(0xFFFFA726);
const kBlue = Color(0xFF4C8DF6);
const kPurple = Color(0xFF8E6CF0);

class Cat {
  const Cat(this.name, this.color, this.icon);
  final String name;
  final Color color;
  final IconData icon;
}

const categories = [
  Cat('شخصی', kBlue, Icons.person_outline),
  Cat('کار', kGreen, Icons.work_outline),
  Cat('بانکی', kOrange, Icons.account_balance_outlined),
  Cat('تماس', kPurple, Icons.phone_outlined),
  Cat('پیامک', Color(0xFFF0607A), Icons.sms_outlined),
  Cat('سایر', Color(0xFF4FD1C5), Icons.more_horiz),
];

/// Maps a stored category name (including legacy ones) to a [Cat].
Cat catOf(String name) {
  final normalized = name == 'بانک' ? 'بانکی' : name;
  for (final c in categories) {
    if (c.name == normalized) return c;
  }
  return categories.last;
}

/// Colors that differ between the light and dark theme.
class Pal {
  const Pal({
    required this.bg,
    required this.card,
    required this.tile,
    required this.border,
    required this.primarySoft,
    required this.track,
    required this.inactive,
  });

  final Color bg;
  final Color card;
  final Color tile;
  final Color border;
  final Color primarySoft;
  final Color track;
  final Color inactive;
}

const _light = Pal(
  bg: kBg,
  card: Colors.white,
  tile: Color(0xFFF7F6FC),
  border: Color(0xFFECEAF5),
  primarySoft: kPrimarySoft,
  track: Color(0xFFEDEBF3),
  inactive: Color(0xFFB9B7C9),
);

const _dark = Pal(
  bg: Color(0xFF121118),
  card: Color(0xFF1C1A26),
  tile: Color(0xFF25222F),
  border: Color(0xFF2E2B3A),
  primarySoft: Color(0xFF2D2650),
  track: Color(0xFF33303F),
  inactive: Color(0xFF6E6B80),
);

Pal pal(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? _dark : _light;

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? _dark : _light;
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Vazirmatn',
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: p.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
