import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/buttons/primary_legend_button.theme.g.dart';
import 'package:legend_ui/src/primitives/legend_button_core.dart';

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

  @Themed(defaultsTo: 't.colors.primary', lerp: true)
  final Color? background;

  @Themed(defaultsTo: 't.colors.onPrimary', lerp: true)
  final Color? foreground;

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

  @Themed(defaultsTo: 't.shadows.none')
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final theme = PrimaryLegendButtonTheme.of(
      context,
      PrimaryLegendButtonThemeNullable(
        background: background,
        foreground: foreground,
        padding: padding,
        borderRadius: borderRadius,
        textStyle: textStyle,
        shadows: shadows,
      ),
    );
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
