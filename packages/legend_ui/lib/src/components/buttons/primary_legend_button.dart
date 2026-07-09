import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_button_core.dart';
import 'package:legend_ui/src/theme/legend_states.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'primary_legend_button.theme.g.dart';

/// The primary (filled) action button — the first component ported in the
/// rewrite (ROADMAP Phase 0).
///
/// Composes [LegendButtonCore] (which stacks `LegendInteractive` +
/// `LegendSurface`).
@LegendThemeable()
class PrimaryLegendButton extends StatelessWidget {
  /// The [background]/[foreground] colors lift into the `normal` member of
  /// the per-state theme fields (RFC-002 R6) — pass a sparse
  /// [LegendStates] via the theme levels to restyle individual states.
  PrimaryLegendButton({
    required this.onPressed,
    super.key,
    this.text,
    this.icon,
    this.child,
    this.textFirst = true,
    this.enabled = true,
    Color? background,
    Color? foreground,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.shadows,
  }) : background = background?.states,
       foreground = foreground?.states,
       assert(
         text != null || icon != null || child != null,
         'Provide text, an icon, or a child.',
       );

  final VoidCallback? onPressed;
  final String? text;
  final IconData? icon;

  /// Fully custom content; replaces [text]/[icon] when set.
  final Widget? child;

  /// Whether [text] renders before [icon] (legacy commit ba010a3, minus
  /// the four copy-pasted switch arms).
  final bool textFirst;

  final bool enabled;

  /// Fill behind the label, per interaction state — hover/press blend the
  /// foreground over the fill (8%/16%), disabled swaps to the token
  /// disabled fill.
  @Style<LegendStates<Color>>.resolve(_background, lerp: true)
  final LegendStates<Color>? background;
  static LegendStates<Color> _background(LegendTokens t) => LegendStates(
    normal: t.colors.primary,
    hovered: Color.alphaBlend(
      t.colors.onPrimary.withValues(alpha: 0.08),
      t.colors.primary,
    ),
    pressed: Color.alphaBlend(
      t.colors.onPrimary.withValues(alpha: 0.16),
      t.colors.primary,
    ),
    focused: Color.alphaBlend(
      t.colors.onPrimary.withValues(alpha: 0.08),
      t.colors.primary,
    ),
    disabled: t.colors.disabled,
  );

  /// Color of the label and icon, per interaction state (steady except
  /// while disabled).
  @Style<LegendStates<Color>>.resolve(_foreground, lerp: true)
  final LegendStates<Color>? foreground;
  static LegendStates<Color> _foreground(LegendTokens t) => LegendStates(
    normal: t.colors.onPrimary,
    hovered: t.colors.onPrimary,
    pressed: t.colors.onPrimary,
    focused: t.colors.onPrimary,
    disabled: t.colors.onDisabled,
  );

  /// Inner padding around the button content.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
  static EdgeInsetsGeometry _padding(LegendTokens t) =>
      EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);

  /// Corner rounding of the button surface.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;
  static BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

  /// Text style of the [text] label (its color comes from [foreground]).
  @Style<TextStyle>.resolve(_textStyle)
  final TextStyle? textStyle;
  static TextStyle _textStyle(LegendTokens t) => t.typography.b2;

  /// Drop shadow under the button (flat by default).
  @Style<List<BoxShadow>>.resolve(_shadows)
  final List<BoxShadow>? shadows;
  static List<BoxShadow> _shadows(LegendTokens t) => t.shadows.none;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    return LegendButtonCore(
      onPressed: onPressed,
      text: text,
      icon: icon,
      textFirst: textFirst,
      enabled: enabled,
      background: theme.background,
      foreground: theme.foreground,
      padding: theme.padding,
      borderRadius: theme.borderRadius,
      textStyle: theme.textStyle,
      shadows: theme.shadows,
      child: child,
    );
  }
}
