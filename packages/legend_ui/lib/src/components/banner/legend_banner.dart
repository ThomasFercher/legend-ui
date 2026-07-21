import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_banner.theme.g.dart';

/// Severity of a [LegendBanner] — picks the tinted background and the
/// accent foreground (`primary` = info, `secondary` = success, a derived
/// amber = warning, `error` = error).
enum LegendBannerSeverity { info, success, warning, error }

/// A persistent inline alert strip — the non-transient sibling of
/// [LegendToast]: it sits in the page until the condition clears or the
/// user dismisses it, instead of timing out.
///
/// Composes [LegendSurface] for the tinted strip and [LegendInteractive]
/// for the dismiss affordance; announced as an assistive-tech live region
/// so it is read out when it appears or its message changes.
///
/// The leading [icon] and trailing [action] are consumer slots (icons come
/// from the consumer — the kit ships none). A non-null [onDismissed] shows
/// the dismiss affordance; the banner itself stays stateless — hide it in
/// response to the callback.
@LegendThemeable()
class LegendBanner extends StatelessWidget {
  const LegendBanner({
    required this.message,
    super.key,
    this.severity = LegendBannerSeverity.info,
    this.title,
    this.icon,
    this.action,
    this.onDismissed,
    this.dismissLabel,
    this.infoBackground,
    this.infoForeground,
    this.successBackground,
    this.successForeground,
    this.warningBackground,
    this.warningForeground,
    this.errorBackground,
    this.errorForeground,
    this.padding,
    this.borderRadius,
    this.iconSize,
  });

  /// The alert body text.
  final String message;

  final LegendBannerSeverity severity;

  /// Optional emphasized headline above [message].
  final String? title;

  /// Optional leading icon slot, centered in an [iconSize] square.
  final Widget? icon;

  /// Optional trailing widget (e.g. a "Review" button).
  final Widget? action;

  /// Called when the dismiss affordance is activated; non-null shows it.
  final VoidCallback? onDismissed;

  /// What dismissing does (e.g. 'Dismiss warning') — announced for the
  /// dismiss affordance, never a hard-coded English label.
  final String? dismissLabel;

  /// Strip fill for [LegendBannerSeverity.info].
  @Style<Color>.resolve(_infoBackground)
  final Color? infoBackground;

  /// Icon/title accent for [LegendBannerSeverity.info].
  @Style<Color>.resolve(ColorRef.primary)
  final Color? infoForeground;

  /// Strip fill for [LegendBannerSeverity.success].
  @Style<Color>.resolve(_successBackground)
  final Color? successBackground;

  /// Icon/title accent for [LegendBannerSeverity.success].
  @Style<Color>.resolve(ColorRef.secondary)
  final Color? successForeground;

  /// Strip fill for [LegendBannerSeverity.warning].
  @Style<Color>.resolve(_warningBackground)
  final Color? warningBackground;

  /// Icon/title accent for [LegendBannerSeverity.warning].
  @Style<Color>.resolve(_warningForeground)
  final Color? warningForeground;

  /// Strip fill for [LegendBannerSeverity.error].
  @Style<Color>.resolve(_errorBackground)
  final Color? errorBackground;

  /// Icon/title accent for [LegendBannerSeverity.error].
  @Style<Color>.resolve(ColorRef.error)
  final Color? errorForeground;

  /// Inner padding around icon, texts, action and dismiss affordance.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Corner rounding of the strip.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Side length of the square the [icon] slot is centered in.
  @Style<double>.resolve(SizeRef.iconMd)
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    final (background, foreground) = switch (severity) {
      LegendBannerSeverity.info => (theme.infoBackground, theme.infoForeground),
      LegendBannerSeverity.success => (
        theme.successBackground,
        theme.successForeground,
      ),
      LegendBannerSeverity.warning => (
        theme.warningBackground,
        theme.warningForeground,
      ),
      LegendBannerSeverity.error => (
        theme.errorBackground,
        theme.errorForeground,
      ),
    };

    return LegendSurface(
      color: background,
      borderRadius: theme.borderRadius,
      padding: theme.padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.sizes.sm,
        children: [
          if (icon != null)
            SizedBox.square(
              dimension: theme.iconSize,
              child: Center(child: icon),
            ),
          Expanded(
            // The live region wraps the content only (the SnackBar idiom):
            // assistive tech re-announces the texts when they appear or
            // change, while the action and dismiss stay separate nodes
            // instead of merging the whole strip into one button.
            child: Semantics(
              container: true,
              liveRegion: true,
              onDismiss: onDismissed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.sizes.xs,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: tokens.typography.b1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  Text(
                    message,
                    style: tokens.typography.b2.copyWith(
                      color: tokens.colors.foreground1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (action != null) action!,
          if (onDismissed != null)
            LegendInteractive(
              semanticLabel: dismissLabel,
              onTap: onDismissed,
              builder: (context, states) => Padding(
                padding: EdgeInsets.all(tokens.sizes.xs),
                child: CustomPaint(
                  size: const Size.square(10),
                  painter: _DismissPainter(
                    states.hovered ? tokens.colors.foreground1 : foreground,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The dismiss cross, painted like the `LegendCaret` chevron — no icon
/// font (the kit ships no icons).
class _DismissPainter extends CustomPainter {
  const _DismissPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, size.height), paint)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_DismissPainter oldDelegate) => color != oldDelegate.color;
}

/// A severity strip is its hue tinted 12% over the surface token, so every
/// severity adapts to light/dark through the same derivation.
Color _tint(Color hue, LegendTokens t) =>
    Color.alphaBlend(hue.withValues(alpha: 0.12), t.colors.surface);

Color _infoBackground(LegendTokens t) => _tint(t.colors.primary, t);

Color _successBackground(LegendTokens t) => _tint(t.colors.secondary, t);

Color _warningBackground(LegendTokens t) => _tint(_warningForeground(t), t);

Color _errorBackground(LegendTokens t) => _tint(t.colors.error, t);

/// The token palette carries no warning hue (primary/secondary/error only),
/// so warning falls back to a fixed amber pair picked by the palette's
/// brightness — dark surfaces get the lighter amber, mirroring how the
/// palettes lighten `error`.
Color _warningForeground(LegendTokens t) =>
    t.colors.surface.computeLuminance() > 0.5
    ? const Color(0xFFD97706)
    : const Color(0xFFFBBF24);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

EdgeInsetsGeometry _padding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);
