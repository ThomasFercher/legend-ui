import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_button_core.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'secondary_legend_button.theme.g.dart';

/// The secondary (tinted, outlined) action button on [LegendButtonCore].
/// Unlike legacy, its themed padding actually applies (legacy passed raw
/// constructor padding, silently killing the themed default).
@LegendThemeable()
class SecondaryLegendButton extends StatelessWidget {
  const SecondaryLegendButton({
    required this.onPressed,
    super.key,
    this.text,
    this.icon,
    this.child,
    this.textFirst = true,
    this.enabled = true,
    this.background,
    this.foreground,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.textStyle,
  });

  final VoidCallback? onPressed;
  final String? text;
  final IconData? icon;
  final Widget? child;
  final bool textFirst;
  final bool enabled;

  @Style<Color>.resolve(_background, lerp: true)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.primaryContainer;

  @Style<Color>.resolve(_foreground, lerp: true)
  final Color? foreground;
  static Color _foreground(LegendTokens t) => t.colors.primary;

  @Style<Color>.resolve(_borderColor)
  final Color? borderColor;
  static Color _borderColor(LegendTokens t) => t.colors.primary;

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
      padding: theme.padding,
      borderRadius: theme.borderRadius,
      textStyle: theme.textStyle,
      child: child,
    );
  }
}
