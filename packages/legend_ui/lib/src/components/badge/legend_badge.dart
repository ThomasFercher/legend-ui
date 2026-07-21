import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/text/legend_text.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_badge.theme.g.dart';

/// A small status marker — a colored dot ([LegendBadge.dot]), a count pill
/// with `max+` overflow ([LegendBadge.count]), or a short label — standalone
/// inline, or anchored over a corner of a [child].
///
/// Composes [LegendSurface] for the pill and [LegendText] for the label.
///
/// Anchoring is plain composition, no overlay engine: give [child] and the
/// badge overhangs the corner picked by [alignment] (a `Stack`, shifted
/// halfway outward). When anchored, a contrast ring ([ringColor] /
/// [ringWidth]) separates the badge from the content underneath — a network
/// badge on a token icon, an unread count on a nav item.
///
/// `LegendBadge.count(0)` renders nothing (just [child], when anchored) —
/// pass the label `'0'` to show an explicit zero. Screen readers announce
/// the label/count text; the label-less dot is silent unless you set
/// [semanticLabel].
@LegendThemeable()
class LegendBadge extends StatelessWidget {
  /// A short status label, e.g. `LegendBadge('Mainnet')`.
  const LegendBadge(
    String this.label, {
    super.key,
    this.child,
    this.alignment = AlignmentDirectional.topEnd,
    this.semanticLabel,
    this.background,
    this.foreground,
    this.dotSize,
    this.padding,
    this.ringColor,
    this.ringWidth,
  }) : count = null,
       max = _defaultMax;

  /// A count pill; values above [max] render as `max+` (e.g. `99+`).
  /// A count of `0` hides the badge.
  const LegendBadge.count(
    int this.count, {
    super.key,
    this.max = _defaultMax,
    this.child,
    this.alignment = AlignmentDirectional.topEnd,
    this.semanticLabel,
    this.background,
    this.foreground,
    this.dotSize,
    this.padding,
    this.ringColor,
    this.ringWidth,
  }) : assert(count >= 0, 'count must be >= 0'),
       assert(max > 0, 'max must be > 0'),
       label = null;

  /// A bare presence dot, no label — "something is here".
  const LegendBadge.dot({
    super.key,
    this.child,
    this.alignment = AlignmentDirectional.topEnd,
    this.semanticLabel,
    this.background,
    this.foreground,
    this.dotSize,
    this.padding,
    this.ringColor,
    this.ringWidth,
  }) : label = null,
       count = null,
       max = _defaultMax;

  static const _defaultMax = 99;

  /// The status text; null for [LegendBadge.count] and [LegendBadge.dot].
  final String? label;

  /// The count; null unless constructed via [LegendBadge.count].
  final int? count;

  /// Overflow ceiling for [count] — larger values render as `max+`.
  final int max;

  /// The content the badge is anchored over; null renders the badge inline.
  final Widget? child;

  /// Which corner of [child] the badge overhangs (anchored form only).
  final AlignmentGeometry alignment;

  /// Announced instead of the visual content — required for a meaningful
  /// [LegendBadge.dot], useful to expand a count ("3 unread messages").
  final String? semanticLabel;

  /// Fill of the badge surface.
  @Style<Color>.resolve(ColorRef.error)
  final Color? background;

  /// Color of the label/count text.
  @Style<Color>.resolve(ColorRef.onError)
  final Color? foreground;

  /// Diameter of the [LegendBadge.dot] fill.
  @Style<double>.resolve(SizeRef.sm)
  final double? dotSize;

  /// Inner padding of the label/count pill.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Color of the contrast ring drawn when anchored over a [child].
  @Style<Color>.resolve(ColorRef.surface)
  final Color? ringColor;

  /// Stroke width of the contrast ring drawn when anchored over a [child].
  @Style<double>.resolve(_ringWidth)
  final double? ringWidth;

  /// The text shown on the pill: the label, the count, or `max+`.
  String? get _text {
    final count = this.count;
    if (count != null) return count > max ? '$max+' : '$count';
    return label;
  }

  Widget _buildBadge(LegendBadgeTheme theme, {required bool anchored}) {
    final text = _text;
    final dot = text == null
        ? SizedBox(width: theme.dotSize, height: theme.dotSize)
        : null;
    Widget badge = LegendSurface(
      color: theme.background,
      // Always a stadium: full rounding at any content size.
      borderRadius: BorderRadius.circular(999),
      border: anchored
          ? Border.all(color: theme.ringColor, width: theme.ringWidth)
          : null,
      padding: dot == null ? theme.padding : null,
      child:
          dot ??
          LegendText(
            text!,
            variant: LegendTextVariant.b3,
            color: theme.foreground,
            maxLines: 1,
          ),
    );
    final semanticLabel = this.semanticLabel;
    if (semanticLabel != null) {
      badge = Semantics(
        label: semanticLabel,
        container: true,
        child: ExcludeSemantics(child: badge),
      );
    }
    return badge;
  }

  @override
  Widget build(BuildContext context) {
    final hidden = count == 0;
    final child = this.child;
    if (child == null) {
      if (hidden) return const SizedBox.shrink();
      return _buildBadge(_theme(context), anchored: false);
    }
    if (hidden) return child;
    final resolved = alignment.resolve(Directionality.of(context));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: resolved,
            child: FractionalTranslation(
              // Shift halfway outward along the anchored corner, so the
              // badge overhangs instead of covering the content.
              translation: Offset(resolved.x / 2, resolved.y / 2),
              child: _buildBadge(_theme(context), anchored: true),
            ),
          ),
        ),
      ],
    );
  }
}

EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.symmetric(
  horizontal: t.sizes.sm * 0.75,
  vertical: t.sizes.xs * 0.5,
);

double _ringWidth(LegendTokens t) => t.sizes.borderWidth * 2;
