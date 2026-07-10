import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_button_core.dart';
import 'package:legend_ui/src/theme/legend_states.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'legend_text_button.theme.g.dart';

/// A borderless, backgroundless button (hover/press tint comes from
/// blending the foreground over transparency).
///
/// Composes [LegendButtonCore].
@LegendThemeable()
class LegendTextButton extends StatelessWidget {
  /// The [foreground] color lifts into the `normal` member of the
  /// per-state theme field (RFC-002 R6); the hover/press tint follows it.
  LegendTextButton({
    required this.onPressed,
    super.key,
    this.text,
    this.icon,
    this.child,
    this.textFirst = true,
    this.enabled = true,
    Color? foreground,
    this.padding,
    this.borderRadius,
    this.textStyle,
  }) : foreground = foreground?.states,
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

  /// Color of the label and icon, per interaction state — also the source
  /// of the hover/press tint (steady except while disabled).
  @Style<LegendStates<Color>>.resolve(_foreground, lerp: true)
  final LegendStates<Color>? foreground;

  /// Inner padding around the button content — tighter than the filled
  /// variants, so this variant keeps its own themed value instead of the
  /// shared [LegendButtonCore] surface (variant wins, RFC-002 R7.2).
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Corner rounding of the hover/press tint area — smaller than the
  /// filled variants, so this variant keeps its own themed value instead
  /// of the shared [LegendButtonCore] surface (variant wins, RFC-002
  /// R7.2).
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Text style of the [text] label (its color comes from [foreground]).
  @Style<TextStyle>.resolve(TextRef.b2)
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    const transparent = Color(0x00000000);
    // The tint derives from the RESOLVED foreground (not from tokens), so
    // a foreground override at any level restyles the hover/press tint
    // with it — exactly the pre-R6 blend behavior.
    final tint = theme.foreground.normal ?? transparent;
    return LegendButtonCore(
      onPressed: onPressed,
      text: text,
      icon: icon,
      textFirst: textFirst,
      enabled: enabled,
      background: LegendStates(
        normal: transparent,
        hovered: Color.alphaBlend(tint.withValues(alpha: 0.08), transparent),
        pressed: Color.alphaBlend(tint.withValues(alpha: 0.16), transparent),
        focused: Color.alphaBlend(tint.withValues(alpha: 0.08), transparent),
        // A transparent variant must stay transparent when disabled — a
        // grey slab would invent a shape it never had.
        disabled: transparent,
      ),
      foreground: theme.foreground,
      padding: theme.padding,
      borderRadius: theme.borderRadius,
      textStyle: theme.textStyle,
      child: child,
    );
  }
}

LegendStates<Color> _foreground(LegendTokens t) => LegendStates(
  normal: t.colors.primary,
  hovered: t.colors.primary,
  pressed: t.colors.primary,
  focused: t.colors.primary,
  disabled: t.colors.onDisabled,
);

EdgeInsetsGeometry _padding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.sm, vertical: t.sizes.xs);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusSm;
