import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/steps/legend_steps.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_timeline.theme.g.dart';

/// One entry of [LegendTimeline] — a titled event with optional
/// supporting copy, a trailing timestamp, a custom indicator, and a
/// free-form content slot.
class LegendTimelineEntry {
  const LegendTimelineEntry({
    required this.title,
    this.description,
    this.timestamp,
    this.indicator,
    this.child,
  });

  /// The one-line event name ("Sent 0.4 ETH").
  final String title;

  /// Optional supporting copy under the [title].
  final String? description;

  /// Optional timestamp rendered trailing on the title row ("2 min ago").
  final String? timestamp;

  /// Custom indicator replacing the themed dot — e.g. a status glyph or a
  /// small avatar. Centered in the rail; icons come from the consumer.
  final Widget? indicator;

  /// Free-form content below the texts (an amount row, an expandable
  /// receipt, a button) — the entry's body is not limited to strings.
  final Widget? child;
}

/// An event-history display: a vertical dot-and-line list for transaction
/// histories and activity feeds, newest-first or oldest-first as the
/// caller orders [entries].
///
/// Composes [LegendSurface] for the dot indicators and connector rail and
/// token-styled text for the labels. Purely presentational — it has no
/// gestures of its own; interactive rows go in an entry's
/// [LegendTimelineEntry.child] slot.
///
/// Shares its painting vocabulary with [LegendSteps] (connector line
/// style, circular indicators); Steps is the *forward-looking* linear
/// flow with completion states, Timeline the *backward-looking* event
/// log — no per-entry status here.
///
/// Each entry is one plain merged semantics node (title, timestamp,
/// description read together); a custom indicator's semantics merge in
/// too.
@LegendThemeable()
class LegendTimeline extends StatelessWidget {
  LegendTimeline({
    required this.entries,
    super.key,
    this.indicatorSize,
    this.indicatorColor,
    this.connectorColor,
    this.connectorThickness,
    this.titleStyle,
    this.descriptionStyle,
    this.timestampStyle,
    this.spacing,
    this.entrySpacing,
  }) : assert(entries.isNotEmpty, 'entries must not be empty.');

  /// The events, in display order (the caller decides the sort).
  final List<LegendTimelineEntry> entries;

  /// Diameter of the default dot indicator — also the rail width a custom
  /// indicator centers in.
  @Style<double>(10)
  final double? indicatorSize;

  /// Fill of the default dot indicator.
  @Style<Color>.resolve(ColorRef.primary)
  final Color? indicatorColor;

  /// Color of the connector line between entries.
  @Style<Color>.resolve(ColorRef.background3)
  final Color? connectorColor;

  /// Stroke width of the connector line.
  @Style<double>.resolve(SizeRef.borderWidth)
  final double? connectorThickness;

  /// Text style of entry titles.
  @Style<TextStyle>.resolve(_titleStyle)
  final TextStyle? titleStyle;

  /// Text style of entry descriptions.
  @Style<TextStyle>.resolve(_descriptionStyle)
  final TextStyle? descriptionStyle;

  /// Text style of the trailing timestamps (most muted).
  @Style<TextStyle>.resolve(_timestampStyle)
  final TextStyle? timestampStyle;

  /// Gap between the indicator rail and an entry's content.
  @Style<double>.resolve(SizeRef.sm)
  final double? spacing;

  /// Vertical gap between consecutive entries (the connector spans it).
  @Style<double>.resolve(SizeRef.md)
  final double? entrySpacing;

  Widget _indicator(LegendTimelineTheme theme, LegendTimelineEntry entry) {
    final custom = entry.indicator;
    if (custom != null) return Center(child: custom);
    return LegendSurface(
      color: theme.indicatorColor,
      borderRadius: BorderRadius.circular(theme.indicatorSize),
      child: SizedBox.square(dimension: theme.indicatorSize),
    );
  }

  Widget _entry(LegendTimelineTheme theme, LegendTokens tokens, int index) {
    final entry = entries[index];
    final last = index == entries.length - 1;
    return MergeSemantics(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: theme.indicatorSize,
              child: Column(
                children: [
                  _indicator(theme, entry),
                  if (!last)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: tokens.sizes.xs,
                        ),
                        child: SizedBox(
                          width: theme.connectorThickness,
                          child: LegendSurface(color: theme.connectorColor),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: theme.spacing),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : theme.entrySpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(entry.title, style: theme.titleStyle),
                        ),
                        if (entry.timestamp != null)
                          Text(entry.timestamp!, style: theme.timestampStyle),
                      ],
                    ),
                    if (entry.description != null)
                      Text(entry.description!, style: theme.descriptionStyle),
                    if (entry.child != null)
                      Padding(
                        padding: EdgeInsets.only(top: tokens.sizes.xs),
                        child: entry.child,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < entries.length; i++) _entry(theme, tokens, i),
      ],
    );
  }
}

TextStyle _titleStyle(LegendTokens t) => t.typography.b2.copyWith(
  fontWeight: FontWeight.w600,
  color: t.colors.foreground1,
);

TextStyle _descriptionStyle(LegendTokens t) =>
    t.typography.b3.copyWith(color: t.colors.foreground2);

TextStyle _timestampStyle(LegendTokens t) =>
    t.typography.b3.copyWith(color: t.colors.foreground3);
