import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_caret.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_stat.theme.g.dart';

/// Which way a [LegendStat]'s delta points — and which color it takes.
enum LegendStatDirection {
  /// The metric went up — arrow up, [LegendStat.positiveColor].
  up,

  /// The metric went down — arrow down, [LegendStat.negativeColor].
  down,

  /// The metric is unchanged — no arrow, [LegendStat.neutralColor].
  flat;

  /// The direction of a signed [change] — [up] above zero, [down] below,
  /// [flat] at zero (or NaN).
  static LegendStatDirection fromChange(double change) {
    if (change > 0) return up;
    if (change < 0) return down;
    return flat;
  }
}

/// An emphasized KPI display — a small muted [label] over a large [value],
/// with an optional colored [delta] (arrow + change), [caption] line, and
/// free-form [leading] slot: wallet balances, prices, counters.
///
/// Purely presentational token-styled layout; composes [LegendCaret] for
/// the painted delta arrow — no interactive primitives.
///
/// [delta] is a preformatted string (e.g. `'4.2%'`); formatting and locale
/// stay with the caller. [deltaDirection] picks the arrow and color —
/// derive it from a signed change with [LegendStatDirection.fromChange].
/// The [caption] renders muted after the delta ("vs last week") or alone
/// on that line when there is no delta.
///
/// There is no group container: lay several stats out with a `Wrap` (or a
/// `Row` of `Expanded`s) and they align by their top edge.
///
/// Screen readers announce the stat as one merged node — "Balance,
/// $12,480.30, up 4.2%, vs last week" — with the arrow spoken as
/// "up"/"down" instead of being invisible.
@LegendThemeable()
class LegendStat extends StatelessWidget {
  const LegendStat({
    required this.label,
    required this.value,
    super.key,
    this.delta,
    this.deltaDirection = LegendStatDirection.flat,
    this.caption,
    this.leading,
    this.labelStyle,
    this.valueStyle,
    this.captionStyle,
    this.positiveColor,
    this.negativeColor,
    this.neutralColor,
    this.spacing,
  });

  /// What the metric is ("Balance", "24h volume").
  final String label;

  /// The metric itself, preformatted ("$12,480.30").
  final String value;

  /// Optional preformatted change ("4.2%"), colored by [deltaDirection].
  final String? delta;

  /// Which way [delta] points; defaults to [LegendStatDirection.flat].
  final LegendStatDirection deltaDirection;

  /// Optional muted line after the delta ("vs last week").
  final String? caption;

  /// Optional slot before the texts (icon, token avatar).
  final Widget? leading;

  /// Text style of the [label] (small, muted).
  @Style<TextStyle>.resolve(_labelStyle)
  final TextStyle? labelStyle;

  /// Text style of the [value] (large, emphasized).
  @Style<TextStyle>.resolve(_valueStyle)
  final TextStyle? valueStyle;

  /// Text style of the [caption] (small, faint).
  @Style<TextStyle>.resolve(_captionStyle)
  final TextStyle? captionStyle;

  /// Color of an upward [delta].
  @Style<Color>.resolve(ColorRef.secondary)
  final Color? positiveColor;

  /// Color of a downward [delta].
  @Style<Color>.resolve(ColorRef.error)
  final Color? negativeColor;

  /// Color of a flat [delta].
  @Style<Color>.resolve(ColorRef.foreground2)
  final Color? neutralColor;

  /// Vertical gap between the stacked lines.
  @Style<double>.resolve(SizeRef.xs)
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    final delta = this.delta;
    final caption = this.caption;

    final deltaColor = switch (deltaDirection) {
      LegendStatDirection.up => theme.positiveColor,
      LegendStatDirection.down => theme.negativeColor,
      LegendStatDirection.flat => theme.neutralColor,
    };

    Widget stat = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.spacing,
      children: [
        Text(label, style: theme.labelStyle),
        Text(value, style: theme.valueStyle),
        if (delta != null || caption != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.spacing,
            children: [
              if (delta != null) _delta(delta, deltaColor, tokens),
              if (caption != null)
                Flexible(child: Text(caption, style: theme.captionStyle)),
            ],
          ),
      ],
    );

    final leading = this.leading;
    if (leading != null) {
      stat = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.sizes.sm,
        children: [
          leading,
          Flexible(child: stat),
        ],
      );
    }
    // One node per stat: "label, value, up 4.2%, caption" — the delta row
    // below contributes the spoken direction the painted arrow can't.
    return MergeSemantics(child: stat);
  }

  /// The colored change: a painted [LegendCaret] arrow (up when the metric
  /// rose, down when it fell, none when flat) beside the [delta] text. The
  /// arrow is announced as "up"/"down" through a semantics label replacing
  /// the row's visual content.
  Widget _delta(String delta, Color color, LegendTokens tokens) {
    final spoken = switch (deltaDirection) {
      LegendStatDirection.up => 'up $delta',
      LegendStatDirection.down => 'down $delta',
      LegendStatDirection.flat => delta,
    };
    return Semantics(
      label: spoken,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.sizes.xs / 2,
          children: [
            if (deltaDirection != LegendStatDirection.flat)
              LegendCaret(
                color: color,
                open: deltaDirection == LegendStatDirection.up,
                size: const Size(8, 5),
              ),
            Text(
              delta,
              style: tokens.typography.b3.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _labelStyle(LegendTokens t) =>
    t.typography.b3.copyWith(color: t.colors.foreground2);

TextStyle _valueStyle(LegendTokens t) =>
    t.typography.h2.copyWith(color: t.colors.foreground1);

TextStyle _captionStyle(LegendTokens t) =>
    t.typography.b3.copyWith(color: t.colors.foreground3);
