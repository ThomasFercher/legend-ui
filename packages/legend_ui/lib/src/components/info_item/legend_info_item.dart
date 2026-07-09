import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/info_item/legend_info_item.theme.g.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';

/// A label/value row for detail lists — label on the left, value on the
/// right, with optional [leading] and [trailing] widgets on the outside.
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

  @Themed(defaultsTo: 't.typography.b3.copyWith(color: t.colors.foreground2)')
  final TextStyle? labelStyle;

  @Themed(defaultsTo: 't.typography.b2.copyWith(color: t.colors.foreground1)')
  final TextStyle? valueStyle;

  @Themed(defaultsTo: 'EdgeInsets.symmetric(vertical: t.sizes.xs)')
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = LegendInfoItemTheme.of(
      context,
      LegendInfoItemThemeNullable(
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        padding: padding,
      ),
    );
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
