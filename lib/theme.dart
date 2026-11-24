import 'package:flutter/material.dart';

import 'models/task.dart';

const kPrimary = Color(0xFF6C47E8);
const kPrimarySoft = Color(0xFFEEE9FF);
const kBg = Color(0xFFF7F6FB);
const kText = Color(0xFF1E1B3A);
const kMuted = Color(0xFF8A88A0);
const kGreen = Color(0xFF3CC47C);
const kOrange = Color(0xFFFFA726);
const kBlue = Color(0xFF4C8DF6);
const kPurple = Color(0xFF8E6CF0);

const categoryIcons = <IconData>[
  Icons.person_outline,
  Icons.work_outline,
  Icons.account_balance_outlined,
  Icons.phone_outlined,
  Icons.sms_outlined,
  Icons.more_horiz,
  Icons.shopping_cart_outlined,
  Icons.favorite_border,
  Icons.school_outlined,
  Icons.home_outlined,
  Icons.directions_car_outlined,
  Icons.fitness_center,
  Icons.restaurant_outlined,
  Icons.flight_outlined,
  Icons.pets,
  Icons.code,
];

const categoryColors = <Color>[
  kBlue,
  kGreen,
  kOrange,
  kPurple,
  Color(0xFFF0607A),
  Color(0xFF4FD1C5),
  Color(0xFFE5484D),
  Color(0xFF14B8A6),
  Color(0xFFEAB308),
  Color(0xFF6366F1),
  Color(0xFF8B5CF6),
  Color(0xFF64748B),
];

enum FieldType {
  phone('شماره تلفن'),
  text('متن'),
  link('لینک / برنامه');

  const FieldType(this.label);
  final String label;

  static FieldType parse(Object? value) => FieldType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => FieldType.text,
      );
}

/// An extra input a category asks for when a task is created (for example a
/// phone number for the "calls" category).
class CatField {
  const CatField({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
  });

  final String id;
  final String label;
  final FieldType type;
  final bool required;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        'required': required,
      };

  factory CatField.fromJson(Map<String, dynamic> json) => CatField(
        id: json['id'] as String,
        label: json['label'] as String,
        type: FieldType.parse(json['type']),
        required: (json['required'] ?? false) as bool,
      );
}

class Cat {
  const Cat(this.name, this.color, this.iconIndex, [this.fields = const []]);

  final String name;
  final Color color;
  final int iconIndex;
  final List<CatField> fields;

  IconData get icon => categoryIcons[iconIndex % categoryIcons.length];

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color.toARGB32(),
        'icon': iconIndex,
        'fields': fields.map((f) => f.toJson()).toList(),
      };

  factory Cat.fromJson(Map<String, dynamic> json) => Cat(
        json['name'] as String,
        Color(json['color'] as int),
        (json['icon'] ?? 0) as int,
        ((json['fields'] ?? []) as List<dynamic>)
            .map((e) => CatField.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

const _phoneField = CatField(
  id: 'phone',
  label: 'شماره تلفن',
  type: FieldType.phone,
  required: true,
);

const defaultCategories = [
  Cat('شخصی', kBlue, 0),
  Cat('کار', kGreen, 1),
  Cat('بانکی', kOrange, 2),
  Cat('تماس', kPurple, 3, [_phoneField]),
  Cat('پیامک', Color(0xFFF0607A), 4, [_phoneField]),
  Cat('سایر', Color(0xFF4FD1C5), 5),
];

/// The user's categories. Replaced by [AppState] when settings are loaded.
List<Cat> categories = List.of(defaultCategories);

/// Maps a stored category name (including legacy ones) to a [Cat].
Cat catOf(String name) {
  final normalized = name == 'بانک' ? 'بانکی' : name;
  for (final c in categories) {
    if (c.name == normalized) return c;
  }
  for (final c in categories) {
    if (c.name == 'سایر') return c;
  }
  return categories.isEmpty ? defaultCategories.last : categories.last;
}

Color priorityColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return const Color(0xFFE5484D);
    case TaskPriority.medium:
      return kOrange;
    case TaskPriority.low:
      return kBlue;
    case TaskPriority.none:
      return kMuted;
  }
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
