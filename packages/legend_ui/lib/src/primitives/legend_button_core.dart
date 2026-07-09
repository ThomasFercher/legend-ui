import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

/// Shared button chassis: interaction states → surface styling → content
/// row. Every button variant is this plus a resolved theme — no
/// copy-pasted layout arms (legacy had 4× per variant), and consumers can
/// build their own variants on it.
class LegendButtonCore extends StatelessWidget {
  const LegendButtonCore({
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.padding,
    required this.borderRadius,
    required this.textStyle,
    super.key,
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

  final Color background;
  final Color foreground;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final TextStyle textStyle;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return LegendInteractive(
      onTap: onPressed,
      enabled: enabled,
      semanticLabel: text,
      builder: (context, states) {
        final effectiveBackground = switch (states) {
          // A transparent variant (text button) must stay transparent when
          // disabled — a grey slab would invent a shape it never had.
          LegendInteractionStates(disabled: true) =>
            background.a == 0 ? background : tokens.colors.disabled,
          LegendInteractionStates(pressed: true) => Color.alphaBlend(
            foreground.withValues(alpha: 0.16),
            background,
          ),
          LegendInteractionStates(hovered: true) ||
          LegendInteractionStates(
            focused: true,
          ) => Color.alphaBlend(foreground.withValues(alpha: 0.08), background),
          _ => background,
        };
        final effectiveForeground = states.disabled
            ? tokens.colors.onDisabled
            : foreground;

        return LegendSurface(
          color: effectiveBackground,
          borderRadius: borderRadius,
          border: states.disabled ? null : border,
          shadows: states.disabled ? null : shadows,
          padding: padding,
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
