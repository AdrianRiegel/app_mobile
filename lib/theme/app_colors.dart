import 'package:flutter/material.dart';

/// Paleta do app, registrada no tema como extensão para trocar entre claro e
/// escuro. Nas telas, use `context.colors.text`, `context.colors.accent` etc.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentLight,
    required this.input,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.danger,
    required this.dangerLight,
    required this.neutralLight,
    required this.onAccent,
    required this.onAccentMuted,
  });

  static const light = AppColors(
    background: Color(0xFFF0F1F4),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE2E4E9),
    text: Color(0xFF1B1D22),
    muted: Color(0xFF6B7078),
    accent: Color(0xFF4F5BD5),
    accentLight: Color(0xFFECEEFB),
    input: Color(0xFFFAFAFB),
    success: Color(0xFF1F9D6E),
    successLight: Color(0xFFE4F6ED),
    warning: Color(0xFFB7791F),
    warningLight: Color(0xFFFFF4D6),
    danger: Color(0xFFCC4B4B),
    dangerLight: Color(0xFFFDECEC),
    neutralLight: Color(0xFFEEF0F3),
    onAccent: Color(0xFFFFFFFF),
    onAccentMuted: Color(0xFFE6E6FF),
  );

  static const dark = AppColors(
    background: Color(0xFF111318),
    surface: Color(0xFF1B1E25),
    border: Color(0xFF2E323B),
    text: Color(0xFFE8EAEE),
    muted: Color(0xFF9AA0AA),
    accent: Color(0xFF6B76E8),
    accentLight: Color(0xFF262B4A),
    input: Color(0xFF16181E),
    success: Color(0xFF3CC48E),
    successLight: Color(0xFF16352A),
    warning: Color(0xFFE0A84A),
    warningLight: Color(0xFF3A2E14),
    danger: Color(0xFFE57373),
    dangerLight: Color(0xFF3D1E1F),
    neutralLight: Color(0xFF262931),
    onAccent: Color(0xFFFFFFFF),
    onAccentMuted: Color(0xFFDADCFF),
  );

  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentLight;
  final Color input;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color danger;
  final Color dangerLight;
  final Color neutralLight;

  /// Texto e ícones sobre fundo [accent] (botões, banners, FAB).
  final Color onAccent;
  final Color onAccentMuted;

  /// Paleta do tema atual. Sem extensão registrada (ex.: testes com um
  /// `MaterialApp` simples), usa a paleta do brilho do tema.
  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? text,
    Color? muted,
    Color? accent,
    Color? accentLight,
    Color? input,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? danger,
    Color? dangerLight,
    Color? neutralLight,
    Color? onAccent,
    Color? onAccentMuted,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      input: input ?? this.input,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      danger: danger ?? this.danger,
      dangerLight: dangerLight ?? this.dangerLight,
      neutralLight: neutralLight ?? this.neutralLight,
      onAccent: onAccent ?? this.onAccent,
      onAccentMuted: onAccentMuted ?? this.onAccentMuted,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      border: mix(border, other.border),
      text: mix(text, other.text),
      muted: mix(muted, other.muted),
      accent: mix(accent, other.accent),
      accentLight: mix(accentLight, other.accentLight),
      input: mix(input, other.input),
      success: mix(success, other.success),
      successLight: mix(successLight, other.successLight),
      warning: mix(warning, other.warning),
      warningLight: mix(warningLight, other.warningLight),
      danger: mix(danger, other.danger),
      dangerLight: mix(dangerLight, other.dangerLight),
      neutralLight: mix(neutralLight, other.neutralLight),
      onAccent: mix(onAccent, other.onAccent),
      onAccentMuted: mix(onAccentMuted, other.onAccentMuted),
    );
  }
}

extension AppColorsContext on BuildContext {
  /// Paleta do tema atual (claro ou escuro).
  AppColors get colors => AppColors.of(this);
}
