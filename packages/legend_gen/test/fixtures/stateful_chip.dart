import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

part 'stateful_chip.theme.g.dart';

/// Golden-test fixture for the `LegendStates<Color>` field category
/// (RFC-002 R6): member-wise merge/lerp and the overlay-derived fill of
/// unset members in `of()`.
@LegendThemeable()
class StatefulChip extends StatelessWidget {
  const StatefulChip({super.key, this.background, this.label});

  /// Fill per interaction state; unset members derive from `normal`
  /// through the token overlays.
  @Style<LegendStates<Color>>.resolve(_background, lerp: true)
  final LegendStates<Color>? background;
  static LegendStates<Color> _background(LegendTokens t) =>
      LegendStates(normal: t.colors.primary);

  /// Label color (steps on theme animation).
  @Style<Color>.resolve(_label)
  final Color? label;
  static Color _label(LegendTokens t) => t.colors.onPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    return ColoredBox(color: theme.background.pick(const LegendStateNormal())!);
  }
}
