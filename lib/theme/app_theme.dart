import 'package:flutter/material.dart';

extension AppContextExtension on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color scaffold;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color brand;
  final Color accent;
  final Color success;
  final Color danger;

  const AppColors({
    required this.scaffold,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.brand,
    required this.accent,
    required this.success,
    required this.danger,
  });

  static const light = AppColors(
    scaffold: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    brand: Color(0xFF032B5E),
    accent: Color(0xFF3B82F6),
    success: Color(0xFF10B981),
    danger: Color(0xFFEF4444),
  );

  static const dark = AppColors(
    scaffold: Color(0xFF0B1220),
    surface: Color(0xFF1A2436),
    surfaceVariant: Color(0xFF233045),
    border: Color(0xFF2A3650),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    brand: Color(0xFF3B82F6),
    accent: Color(0xFF3B82F6),
    success: Color(0xFF10B981),
    danger: Color(0xFFEF4444),
  );

  @override
  AppColors copyWith({
    Color? scaffold,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? brand,
    Color? accent,
    Color? success,
    Color? danger,
  }) =>
      AppColors(
        scaffold: scaffold ?? this.scaffold,
        surface: surface ?? this.surface,
        surfaceVariant: surfaceVariant ?? this.surfaceVariant,
        border: border ?? this.border,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        brand: brand ?? this.brand,
        accent: accent ?? this.accent,
        success: success ?? this.success,
        danger: danger ?? this.danger,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

class AppTheme {
  static const _brand = Color(0xFF032B5E);
  static const _brandDark = Color(0xFF3B82F6);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.light.scaffold,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brand,
          primary: _brand,
        ),
        extensions: const [AppColors.light],
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.dark.scaffold,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandDark,
          brightness: Brightness.dark,
        ),
        extensions: const [AppColors.dark],
      );
}
