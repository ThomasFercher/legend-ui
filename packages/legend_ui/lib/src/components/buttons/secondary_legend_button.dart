import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/buttons/secondary_legend_button.theme.g.dart';
import 'package:legend_ui/src/primitives/legend_button_core.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';

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

  @Themed(defaultsTo: 't.colors.primaryContainer', lerp: true)
  final Color? background;

  @Themed(defaultsTo: 't.colors.primary', lerp: true)
  final Color? foreground;

  @Themed(defaultsTo: 't.colors.primary')
  final Color? borderColor;

  @Themed(
    defaultsTo:
        'EdgeInsets.symmetric(horizontal: t.sizes.md, '
        'vertical: t.sizes.sm)',
  )
  final EdgeInsetsGeometry? padding;

  @Themed(defaultsTo: 't.sizes.borderRadiusMd')
  final BorderRadius? borderRadius;

  @Themed(defaultsTo: 't.typography.b2')
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = SecondaryLegendButtonTheme.of(
      context,
      SecondaryLegendButtonThemeNullable(
        background: background,
        foreground: foreground,
        borderColor: borderColor,
        padding: padding,
        borderRadius: borderRadius,
        textStyle: textStyle,
      ),
    );
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
