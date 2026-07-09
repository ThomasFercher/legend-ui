import 'dart:ui';

import 'package:legend_ui/src/annotations/annotations.dart';

part 'legend_colors.tokens.g.dart';

/// The semantic color palette — the only place colors live.
///
/// Component defaults reference these via `@Style<T>.resolve` tear-offs
/// (`(t) => t.colors.…`).
@LegendTokenData()
class LegendColors with _$LegendColors {
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

  /// Member-wise lerp (generated, RFC-002 R5).
  static LegendColors lerp(LegendColors a, LegendColors b, double t) =>
      _$LegendColorsLerp(a, b, t);
}
