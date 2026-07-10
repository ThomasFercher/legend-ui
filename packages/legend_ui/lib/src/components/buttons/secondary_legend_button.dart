import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_button_core.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'secondary_legend_button.theme.g.dart';

/// The secondary (tinted, outlined) action button.
///
/// Composes [LegendButtonCore].
///
/// Unlike legacy, its themed padding actually applies (legacy passed raw
/// constructor padding, silently killing the themed default).
@LegendThemeable()
class SecondaryLegendButton extends StatelessWidget {
  /// The [background]/[foreground] colors lift into the `normal` member of
  /// the per-state theme fields (RFC-002 R6) — pass a sparse
  /// [InteractiveColors] via the theme levels to restyle individual
  /// states.
  SecondaryLegendButton({
    required this.onPressed,
    super.key,
    this.text,
    this.icon,
    this.child,
    this.textFirst = true,
    this.enabled = true,
    Color? background,
    Color? foreground,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.textStyle,
  }) : background = background == null
           ? null
           : InteractiveColors(normal: background),
       foreground = foreground == null
           ? null
           : InteractiveColors(normal: foreground),
       assert(
         text != null || icon != null || child != null,
         'Provide text, an icon, or a child.',
       );

  final VoidCallback? onPressed;
  final String? text;
  final IconData? icon;

  /// Fully custom content; replaces [text]/[icon] when set.
  final Widget? child;

  /// Whether [text] renders before [icon].
  final bool textFirst;

  final bool enabled;

  /// Tinted fill behind the label, per interaction state — hover/press
  /// blend the foreground over the container tint (8%/16%), disabled
  /// swaps to the token disabled fill.
  @Style<InteractiveColors>.resolve(_background, lerp: true)
  final InteractiveColors? background;

  /// Color of the label and icon, per interaction state (steady except
  /// while disabled).
  @Style<InteractiveColors>.resolve(_foreground, lerp: true)
  final InteractiveColors? foreground;

  /// Color of the outline (dropped entirely while disabled).
  @Style<Color>.resolve(ColorRef.primary)
  final Color? borderColor;

  /// Per-instance padding; when null the shared button surface applies
  /// ([LegendButtonCore]'s themed padding, RFC-002 R7.2).
  final EdgeInsetsGeometry? padding;

  /// Per-instance corner rounding; when null the shared button surface
  /// applies ([LegendButtonCore]'s themed radius, RFC-002 R7.2).
  final BorderRadius? borderRadius;

  /// Text style of the [text] label (its color comes from [foreground]).
  @Style<TextStyle>.resolve(TextRef.b2)
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    return LegendButtonCore(
      onPressed: onPressed,
      text: text,
      icon: icon,
      textFirst: textFirst,
      enabled: enabled,
      background: theme.background,
      foreground: theme.foreground,
      border: Border.all(
        color: theme.borderColor,
        width: tokens.sizes.borderWidth,
      ),
      padding: padding,
      borderRadius: borderRadius,
      textStyle: theme.textStyle,
      child: child,
    );
  }
}

InteractiveColors _background(LegendTokens t) => InteractiveColors(
  normal: t.colors.primaryContainer,
  hovered: Color.alphaBlend(
    t.colors.primary.withValues(alpha: 0.08),
    t.colors.primaryContainer,
  ),
  pressed: Color.alphaBlend(
    t.colors.primary.withValues(alpha: 0.16),
    t.colors.primaryContainer,
  ),
  focused: Color.alphaBlend(
    t.colors.primary.withValues(alpha: 0.08),
    t.colors.primaryContainer,
  ),
  disabled: t.colors.disabled,
);

InteractiveColors _foreground(LegendTokens t) => InteractiveColors(
  normal: t.colors.primary,
  hovered: t.colors.primary,
  pressed: t.colors.primary,
  focused: t.colors.primary,
  disabled: t.colors.onDisabled,
);
