import 'dart:ui';

/// The semantic color palette — the only place colors live.
///
/// Component defaults reference these via `@Themed(defaultsTo: 't.colors.…')`.
class LegendColors {
  const LegendColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.background1,
    required this.background2,
    required this.background3,
    required this.surface,
    required this.onSurface,
    required this.error,
    required this.onError,
    required this.disabled,
    required this.onDisabled,
    required this.foreground1,
    required this.foreground2,
    required this.foreground3,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color background1;
  final Color background2;
  final Color background3;
  final Color surface;
  final Color onSurface;
  final Color error;
  final Color onError;
  final Color disabled;
  final Color onDisabled;
  final Color foreground1;
  final Color foreground2;
  final Color foreground3;

  /// Placeholder light palette; the real brand palette lands with the
  /// example app (ROADMAP Phase 3).
  static const light = LegendColors(
    primary: Color(0xFF1A80F4),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD6E8FD),
    secondary: Color(0xFF10B981),
    onSecondary: Color(0xFFFFFFFF),
    background1: Color(0xFFF6F7F9),
    background2: Color(0xFFEDEFF3),
    background3: Color(0xFFE2E5EB),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF17181C),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    disabled: Color(0xFFD1D5DB),
    onDisabled: Color(0xFF6B7280),
    foreground1: Color(0xFF17181C),
    foreground2: Color(0xFF4B5563),
    foreground3: Color(0xFF9CA3AF),
  );

  /// Placeholder dark palette.
  static const dark = LegendColors(
    primary: Color(0xFF3B94F6),
    onPrimary: Color(0xFF0B1220),
    primaryContainer: Color(0xFF10305B),
    secondary: Color(0xFF34D399),
    onSecondary: Color(0xFF07130D),
    background1: Color(0xFF0F1115),
    background2: Color(0xFF16181D),
    background3: Color(0xFF1D2026),
    surface: Color(0xFF23262D),
    onSurface: Color(0xFFF3F4F6),
    error: Color(0xFFF87171),
    onError: Color(0xFF1B0A0A),
    disabled: Color(0xFF3A3F47),
    onDisabled: Color(0xFF8B919B),
    foreground1: Color(0xFFF3F4F6),
    foreground2: Color(0xFFB6BCC6),
    foreground3: Color(0xFF7A8290),
  );

  LegendColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? background1,
    Color? background2,
    Color? background3,
    Color? surface,
    Color? onSurface,
    Color? error,
    Color? onError,
    Color? disabled,
    Color? onDisabled,
    Color? foreground1,
    Color? foreground2,
    Color? foreground3,
  }) {
    return LegendColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      background1: background1 ?? this.background1,
      background2: background2 ?? this.background2,
      background3: background3 ?? this.background3,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      disabled: disabled ?? this.disabled,
      onDisabled: onDisabled ?? this.onDisabled,
      foreground1: foreground1 ?? this.foreground1,
      foreground2: foreground2 ?? this.foreground2,
      foreground3: foreground3 ?? this.foreground3,
    );
  }

  static LegendColors lerp(LegendColors a, LegendColors b, double t) {
    return LegendColors(
      primary: Color.lerp(a.primary, b.primary, t)!,
      onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t)!,
      primaryContainer: Color.lerp(a.primaryContainer, b.primaryContainer, t)!,
      secondary: Color.lerp(a.secondary, b.secondary, t)!,
      onSecondary: Color.lerp(a.onSecondary, b.onSecondary, t)!,
      background1: Color.lerp(a.background1, b.background1, t)!,
      background2: Color.lerp(a.background2, b.background2, t)!,
      background3: Color.lerp(a.background3, b.background3, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      onSurface: Color.lerp(a.onSurface, b.onSurface, t)!,
      error: Color.lerp(a.error, b.error, t)!,
      onError: Color.lerp(a.onError, b.onError, t)!,
      disabled: Color.lerp(a.disabled, b.disabled, t)!,
      onDisabled: Color.lerp(a.onDisabled, b.onDisabled, t)!,
      foreground1: Color.lerp(a.foreground1, b.foreground1, t)!,
      foreground2: Color.lerp(a.foreground2, b.foreground2, t)!,
      foreground3: Color.lerp(a.foreground3, b.foreground3, t)!,
    );
  }
}
