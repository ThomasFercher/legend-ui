import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_button_core.theme.g.dart';

/// Shared button chassis: interaction states → surface styling → content
/// row. Every button variant is this plus a resolved theme — no
/// copy-pasted layout arms (legacy had 4× per variant), and consumers can
/// build their own variants on it.
///
/// Composes [LegendInteractive] (input handling) + [LegendSurface]
/// (decoration).
///
/// The genuinely shared button surface — [padding] and [borderRadius] —
/// is themed HERE (RFC-002 R7.2): override `LegendButtonCore` in the
/// components map (or with [LegendButtonCoreThemeOverride]) and every
/// variant that doesn't opt out follows. **Variant-level values win over
/// core-level ones**: a variant passes its own resolved value as a
/// constructor param (level 1 of the core's resolution), so
/// `LegendTextButton`'s tighter padding/radius and any per-variant
/// override always beat a core-level theme entry. Colors and text style
/// stay variant-level — the variants ARE the color decisions.
///
/// [background] and [foreground] are per-state [InteractiveColors]
/// bundles (RFC-002 R6 amendment 7): the core selects the single
/// effective value via `states.effective` — no color math happens here.
/// Both must carry at least a `normal` value.
@LegendThemeable()
class LegendButtonCore extends StatelessWidget {
  const LegendButtonCore({
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.textStyle,
    super.key,
    this.padding,
    this.borderRadius,
    this.text,
    this.icon,
    this.child,
    this.textFirst = true,
    this.enabled = true,
    this.border,
    this.shadows,
  }) : assert(
         text != null || icon != null || child != null,
         'Provide text, an icon, or a child.',
       );

  final VoidCallback? onPressed;
  final String? text;
  final IconData? icon;
  final Widget? child;
  final bool textFirst;
  final bool enabled;

  /// Surface fill per interaction state (`normal` is required).
  final InteractiveColors background;

  /// Label/icon color per interaction state (`normal` is required).
  final InteractiveColors foreground;

  /// Inner padding around the button content, shared by every variant
  /// that doesn't set its own.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Corner rounding of the button surface, shared by every variant that
  /// doesn't set its own.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Text style of the [text] label (its color comes from [foreground]).
  final TextStyle textStyle;

  /// Outline around the surface; hidden while disabled.
  final BoxBorder? border;

  /// Drop shadow under the surface; hidden while disabled.
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    return LegendInteractive(
      onTap: onPressed,
      enabled: enabled,
      semanticLabel: text,
      builder: (context, states) {
        final state = states.effective;
        final effectiveBackground = background.pick(state)!;
        final effectiveForeground = foreground.pick(state)!;

        return LegendSurface(
          color: effectiveBackground,
          borderRadius: theme.borderRadius,
          border: states.disabled ? null : border,
          shadows: states.disabled ? null : shadows,
          padding: theme.padding,
          duration: const Duration(milliseconds: 120),
          child: _content(effectiveForeground, tokens),
        );
      },
    );
  }

  Widget _content(Color foreground, LegendTokens tokens) {
    if (child != null) return child!;
    final label = text == null
        ? null
        : Text(text!, style: textStyle.copyWith(color: foreground));
    final glyph = icon == null
        ? null
        : Icon(icon, color: foreground, size: tokens.sizes.iconMd);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.sizes.sm,
      children: [
        if (textFirst) ...[?label, ?glyph] else ...[?glyph, ?label],
      ],
    );
  }
}

EdgeInsetsGeometry _padding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;
