import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

import 'fancy_box.theme.g.dart';

/// Golden-test fixture: covers Color (lerp), double (lerp), non-lerp
/// EdgeInsetsGeometry, and BorderRadius fields.
@LegendThemeable()
class FancyBox extends StatelessWidget {
  const FancyBox({super.key, this.background, this.gap, this.padding});

  @Themed(defaultsTo: 't.colors.surface', lerp: true)
  final Color? background;

  @Themed(defaultsTo: 't.sizes.sm', lerp: true)
  final double? gap;

  @Themed(defaultsTo: 'EdgeInsets.all(t.sizes.md)')
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = FancyBoxTheme.of(
      context,
      FancyBoxThemeNullable(background: background, gap: gap, padding: padding),
    );
    return Container(color: theme.background, padding: theme.padding);
  }
}
