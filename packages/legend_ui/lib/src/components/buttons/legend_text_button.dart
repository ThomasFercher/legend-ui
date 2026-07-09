import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/buttons/legend_text_button.theme.g.dart';
import 'package:legend_ui/src/primitives/legend_button_core.dart';

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

  @Themed(defaultsTo: 't.colors.primary', lerp: true)
  final Color? foreground;

  @Themed(
    defaultsTo:
        'EdgeInsets.symmetric(horizontal: t.sizes.sm, '
        'vertical: t.sizes.xs)',
  )
  final EdgeInsetsGeometry? padding;

  @Themed(defaultsTo: 't.sizes.borderRadiusSm')
  final BorderRadius? borderRadius;

  @Themed(defaultsTo: 't.typography.b2')
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = LegendTextButtonTheme.of(
      context,
      LegendTextButtonThemeNullable(
        foreground: foreground,
        padding: padding,
        borderRadius: borderRadius,
        textStyle: textStyle,
      ),
    );
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
