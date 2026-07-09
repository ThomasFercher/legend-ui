import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

part 'fancy_box.theme.g.dart';

/// Golden-test fixture: covers a `.resolve` private tear-off (Color,
/// lerp), a typed const default (double, lerp), a non-lerp `.resolve`
/// (EdgeInsetsGeometry), and a genuinely optional `@Style<T>(null)` field.
@LegendThemeable()
class FancyBox extends StatelessWidget {
  const FancyBox({
    super.key,
    this.background,
    this.gap,
    this.padding,
    this.outline,
  });

  /// Fill behind the child.
  @Style<Color>.resolve(_background, lerp: true)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.surface;

  /// Space between children.
  @Style<double>(8.0, lerp: true)
  final double? gap;

  /// Inner padding.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
  static EdgeInsetsGeometry _padding(LegendTokens t) =>
      EdgeInsets.all(t.sizes.md);

  /// Optional outline color; nothing is drawn when unset at every level.
  @Style<Color>(null, lerp: true)
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    return Container(color: theme.background, padding: theme.padding);
  }
}
