import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/divider/legend_divider.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_list.theme.g.dart';

/// A vertical group of list rows — typically `LegendListItem`s — with an
/// optional section [header] above them and either token spacing or
/// [LegendDivider] rules between them.
///
/// Plain token-styled layout; composes [LegendDivider] between rows when
/// [dividers] is set, and no interactive primitives itself (each row owns
/// its own interaction). Sectioned screens stack one [LegendList] per
/// section, each with its own [header].
@LegendThemeable()
class LegendList extends StatelessWidget {
  const LegendList({
    required this.children,
    super.key,
    this.header,
    this.dividers = false,
    this.headerStyle,
    this.headerPadding,
    this.spacing,
  });

  /// The rows, top to bottom.
  final List<Widget> children;

  /// Optional section header rendered above the rows.
  final String? header;

  /// Renders a [LegendDivider] between consecutive rows instead of the
  /// [spacing] gap.
  final bool dividers;

  /// Text style of the section [header] (muted, smaller than row titles).
  @Style<TextStyle>.resolve(_headerStyle)
  final TextStyle? headerStyle;

  /// Padding around the section [header] — its horizontal inset lines the
  /// header up with row content.
  @Style<EdgeInsetsGeometry>.resolve(_headerPadding)
  final EdgeInsetsGeometry? headerPadding;

  /// Vertical gap between rows (unused while [dividers] is set).
  @Style<double>.resolve(SizeRef.xs)
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null)
          Padding(
            padding: theme.headerPadding,
            child: Text(header!, style: theme.headerStyle),
          ),
        for (final (index, child) in children.indexed) ...[
          if (index > 0)
            if (dividers)
              const LegendDivider()
            else
              SizedBox(height: theme.spacing),
          child,
        ],
      ],
    );
  }
}

TextStyle _headerStyle(LegendTokens t) =>
    t.typography.b3.copyWith(color: t.colors.foreground2);

EdgeInsetsGeometry _headerPadding(LegendTokens t) =>
    EdgeInsets.only(left: t.sizes.md, right: t.sizes.md, bottom: t.sizes.xs);
