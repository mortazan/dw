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

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Vazirmatn',
      colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
      scaffoldBackgroundColor: kBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: kBg,
        foregroundColor: kText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
