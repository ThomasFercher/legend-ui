import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_button_core.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'primary_legend_button.theme.g.dart';

/// The primary action button — first component ported in the rewrite
/// (ROADMAP Phase 0), composed on [LegendButtonCore].
@LegendThemeable()
class PrimaryLegendButton extends StatelessWidget {
  const PrimaryLegendButton({
    required this.onPressed,
    super.key,
    this.text,
    this.icon,
    this.child,
    this.textFirst = true,
    this.enabled = true,
    this.background,
    this.foreground,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.shadows,
  }) : assert(
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

  @Style<Color>.resolve(_background, lerp: true)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.primary;

  @Style<Color>.resolve(_foreground, lerp: true)
  final Color? foreground;
  static Color _foreground(LegendTokens t) => t.colors.onPrimary;

  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
  static EdgeInsetsGeometry _padding(LegendTokens t) =>
      EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);

  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;
  static BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

  @Style<TextStyle>.resolve(_textStyle)
  final TextStyle? textStyle;
  static TextStyle _textStyle(LegendTokens t) => t.typography.b2;

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
