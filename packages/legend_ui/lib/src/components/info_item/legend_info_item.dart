import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_info_item.theme.g.dart';

/// A label/value row for detail lists — label on the left, value on the
/// right, with optional [leading] and [trailing] widgets on the outside.
///
/// Plain token-styled layout; composes no interactive primitives.
///
/// (Correctly spelled `trailing` this time — legacy shipped `trailling`
/// as public API, legacy-docs 01 §4.2.)
@LegendThemeable()
class LegendInfoItem extends StatelessWidget {
  const LegendInfoItem({
    required this.label,
    required this.value,
    super.key,
    this.leading,
    this.trailing,
    this.labelStyle,
    this.valueStyle,
    this.padding,
  });

  final String label;
  final String value;

  /// Shown before the label.
  final Widget? leading;

  /// Shown after the value.
  final Widget? trailing;

  /// Text style of the [label] (muted, smaller than the value).
  @Style<TextStyle>.resolve(_labelStyle)
  final TextStyle? labelStyle;

  /// Text style of the [value].
  @Style<TextStyle>.resolve(_valueStyle)
  final TextStyle? valueStyle;

  /// Outer padding around the row.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    return Padding(
      padding: theme.padding,
      child: Row(
        spacing: tokens.sizes.sm,
        children: [
          if (leading != null) leading!,
          Text(label, style: theme.labelStyle),
          Expanded(
            child: Text(
              value,
              style: theme.valueStyle,
              textAlign: TextAlign.end,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

TextStyle _labelStyle(LegendTokens t) =>
    t.typography.b3.copyWith(color: t.colors.foreground2);

TextStyle _valueStyle(LegendTokens t) =>
    t.typography.b2.copyWith(color: t.colors.foreground1);

EdgeInsetsGeometry _padding(LegendTokens t) =>
    EdgeInsets.symmetric(vertical: t.sizes.xs);
