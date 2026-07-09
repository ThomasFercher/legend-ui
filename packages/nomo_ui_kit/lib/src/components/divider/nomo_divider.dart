import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/divider/nomo_divider.theme.g.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';

/// A thin rule separating content, horizontal ([Axis.horizontal], the
/// default) or vertical.
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
@NomoThemeable()
class NomoDivider extends StatelessWidget {
  const NomoDivider({
    super.key,
    this.axis = Axis.horizontal,
    this.color,
    this.thickness,
    this.spacing,
  });

  /// The direction the line runs in.
  final Axis axis;

  @Themed(defaultsTo: 't.colors.background3')
  final Color? color;

  @Themed(defaultsTo: 't.sizes.borderWidth')
  final double? thickness;

  @Themed(defaultsTo: 't.sizes.md')
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final theme = NomoDividerTheme.of(
      context,
      NomoDividerThemeNullable(
        color: color,
        thickness: thickness,
        spacing: spacing,
      ),
    );
    final horizontal = axis == Axis.horizontal;
    return Padding(
      padding: horizontal
          ? EdgeInsets.symmetric(vertical: theme.spacing)
          : EdgeInsets.symmetric(horizontal: theme.spacing),
      child: SizedBox(
        width: horizontal ? double.infinity : theme.thickness,
        height: horizontal ? theme.thickness : double.infinity,
        child: NomoSurface(color: theme.color),
      ),
    );
  }
}
