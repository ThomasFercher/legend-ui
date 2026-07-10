import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_divider.theme.g.dart';

/// A thin rule separating content, horizontal ([Axis.horizontal], the
/// default) or vertical.
///
/// Composes [LegendSurface] for the line itself.
///
/// [spacing] is the outer margin on both sides of the line — vertical
/// margin for a horizontal divider, horizontal margin for a vertical one.
///
/// Deliberately offers no border radius: legacy's divider accepted one but
/// silently ignored it on one axis (legacy-docs 01 §4.2). A hairline gains
/// nothing from rounding, so the option is dropped rather than half-honored.
///
/// A vertical divider needs a bounded height from its parent (same
/// contract as Flutter's `VerticalDivider`).
@LegendThemeable()
class LegendDivider extends StatelessWidget {
  const LegendDivider({
    super.key,
    this.axis = Axis.horizontal,
    this.color,
    this.thickness,
    this.spacing,
  });

  /// The direction the line runs in.
  final Axis axis;

  /// Color of the line.
  @Style<Color>.resolve(ColorRef.background3)
  final Color? color;

  /// Stroke width of the line.
  @Style<double>.resolve(SizeRef.borderWidth)
  final double? thickness;

  /// Outer margin on both sides of the line.
  @Style<double>.resolve(SizeRef.md)
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final horizontal = axis == Axis.horizontal;
    return Padding(
      padding: horizontal
          ? EdgeInsets.symmetric(vertical: theme.spacing)
          : EdgeInsets.symmetric(horizontal: theme.spacing),
      child: SizedBox(
        width: horizontal ? double.infinity : theme.thickness,
        height: horizontal ? theme.thickness : double.infinity,
        child: LegendSurface(color: theme.color),
      ),
    );
  }
}
