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
  final Color warning;
  final Color purple;
  final Color textTertiary;
  // Semantik arkaplan tonları (rozet/ikon arkaplanları) — her temada uyumlu.
  final Color successBg;
  final Color dangerBg;
  final Color accentBg;
  final Color warningBg;
  final Color purpleBg;

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
    required this.warning,
    required this.purple,
    required this.textTertiary,
    required this.successBg,
    required this.dangerBg,
    required this.accentBg,
    required this.warningBg,
    required this.purpleBg,
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
    warning: Color(0xFFF59E0B),
    purple: Color(0xFF8B5CF6),
    textTertiary: Color(0xFF94A3B8),
    successBg: Color(0xFFF0FDF4),
    dangerBg: Color(0xFFFEF2F2),
    accentBg: Color(0xFFEFF6FF),
    warningBg: Color(0xFFFFF7ED),
    purpleBg: Color(0xFFF5F3FF),
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
    warning: Color(0xFFF59E0B),
    purple: Color(0xFF8B5CF6),
    textTertiary: Color(0xFF64748B),
    // Koyu temada düşük-alfa tonlar (önceden hesaplanmış ARGB, ~%15).
    successBg: Color(0x2610B981),
    dangerBg: Color(0x26EF4444),
    accentBg: Color(0x263B82F6),
    warningBg: Color(0x26F59E0B),
    purpleBg: Color(0x268B5CF6),
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
    Color? warning,
    Color? purple,
    Color? textTertiary,
    Color? successBg,
    Color? dangerBg,
    Color? accentBg,
    Color? warningBg,
    Color? purpleBg,
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
        warning: warning ?? this.warning,
        purple: purple ?? this.purple,
        textTertiary: textTertiary ?? this.textTertiary,
        successBg: successBg ?? this.successBg,
        dangerBg: dangerBg ?? this.dangerBg,
        accentBg: accentBg ?? this.accentBg,
        warningBg: warningBg ?? this.warningBg,
        purpleBg: purpleBg ?? this.purpleBg,
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
      warning: Color.lerp(warning, other.warning, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      accentBg: Color.lerp(accentBg, other.accentBg, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      purpleBg: Color.lerp(purpleBg, other.purpleBg, t)!,
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
