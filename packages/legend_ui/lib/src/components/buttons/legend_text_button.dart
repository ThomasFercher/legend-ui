import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_button_core.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_text_button.theme.g.dart';

/// A borderless, backgroundless button on [LegendButtonCore] (hover/press
/// tint comes from blending the foreground over transparency).
@LegendThemeable()
class LegendTextButton extends StatelessWidget {
  const LegendTextButton({
    required this.onPressed,
    super.key,
    this.text,
    this.icon,
    this.child,
    this.textFirst = true,
    this.enabled = true,
    this.foreground,
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

  @Style<Color>.resolve(_foreground, lerp: true)
  final Color? foreground;
  static Color _foreground(LegendTokens t) => t.colors.primary;

  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
  static EdgeInsetsGeometry _padding(LegendTokens t) =>
      EdgeInsets.symmetric(horizontal: t.sizes.sm, vertical: t.sizes.xs);

  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;
  static BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusSm;

  @Style<TextStyle>.resolve(_textStyle)
  final TextStyle? textStyle;
  static TextStyle _textStyle(LegendTokens t) => t.typography.b2;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    return LegendButtonCore(
      onPressed: onPressed,
      text: text,
      icon: icon,
      textFirst: textFirst,
      enabled: enabled,
      background: const Color(0x00000000),
      foreground: theme.foreground,
      padding: theme.padding,
      borderRadius: theme.borderRadius,
      textStyle: theme.textStyle,
      child: child,
    );
  }
}
