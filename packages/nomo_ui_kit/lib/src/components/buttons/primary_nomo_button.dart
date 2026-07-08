import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/buttons/primary_nomo_button.theme.g.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_interactive.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';
import 'package:nomo_ui_kit/src/tokens/nomo_tokens.dart';

/// The primary action button — first component ported in the rewrite
/// (ROADMAP Phase 0), composed from [NomoInteractive] + [NomoSurface].
@NomoThemeable()
class PrimaryNomoButton extends StatelessWidget {
  const PrimaryNomoButton({
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
    final theme = PrimaryNomoButtonTheme.of(
      context,
      PrimaryNomoButtonThemeNullable(
        background: background,
        foreground: foreground,
        padding: padding,
        borderRadius: borderRadius,
        textStyle: textStyle,
        shadows: shadows,
      ),
    );
    final tokens = NomoTheme.of(context).tokens;

    return NomoInteractive(
      onTap: onPressed,
      enabled: enabled,
      semanticLabel: text,
      builder: (context, states) {
        final background = switch (states) {
          NomoInteractionStates(disabled: true) => tokens.colors.disabled,
          NomoInteractionStates(pressed: true) => Color.alphaBlend(
            theme.foreground.withValues(alpha: 0.16),
            theme.background,
          ),
          NomoInteractionStates(hovered: true) ||
          NomoInteractionStates(focused: true) => Color.alphaBlend(
            theme.foreground.withValues(alpha: 0.08),
            theme.background,
          ),
          _ => theme.background,
        };
        final foreground = states.disabled
            ? tokens.colors.onDisabled
            : theme.foreground;

        return NomoSurface(
          color: background,
          borderRadius: theme.borderRadius,
          shadows: states.disabled ? null : theme.shadows,
          padding: theme.padding,
          duration: const Duration(milliseconds: 120),
          child: _content(foreground, theme, tokens),
        );
      },
    );
  }

  Widget _content(
    Color foreground,
    PrimaryNomoButtonTheme theme,
    NomoTokens tokens,
  ) {
    if (child != null) return child!;
    final label = text == null
        ? null
        : Text(text!, style: theme.textStyle.copyWith(color: foreground));
    final glyph = icon == null
        ? null
        : Icon(icon, color: foreground, size: tokens.sizes.iconMd);
    final parts = [
      if (textFirst) ...[label, glyph] else ...[glyph, label],
    ].nonNulls.toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.sizes.sm,
      children: parts,
    );
  }
}
