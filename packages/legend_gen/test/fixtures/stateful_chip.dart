import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

part 'stateful_chip.style.g.dart';
part 'stateful_chip.theme.g.dart';

/// Golden-test fixture for a custom `@Style()` value class (RFC-002 R6
/// amendment 7) declared in the same file as the stateful widget whose
/// field is typed with it — member-wise merge/lerp through the class's
/// generated members, dot-path docs entries, and the State-class
/// detection (RFC-002 R13).
@Style()
class ChipAccent with _$ChipAccent {
  const ChipAccent({this.fill, this.outline, this.weight});

  /// Fill behind the chip label.
  final Color? fill;

  /// Outline drawn around the fill.
  final Color? outline;

  /// Stroke weight of the outline.
  final double? weight;

  /// Member-wise lerp (generated, RFC-002 R6 amendment 7).
  static ChipAccent? lerp(ChipAccent? a, ChipAccent? b, double t) =>
      _$ChipAccentLerp(a, b, t);
}

@LegendThemeable()
class StatefulChip extends StatefulWidget {
  const StatefulChip({super.key, this.accent, this.label});

  /// Accent styling of the chip; every member is individually
  /// overridable at every resolution level.
  @Style<ChipAccent>.resolve(_accent, lerp: true)
  final ChipAccent? accent;
  static ChipAccent _accent(LegendTokens t) =>
      ChipAccent(fill: t.colors.primary);

  /// Label color (steps on theme animation).
  @Style<Color>.resolve(_label)
  final Color? label;
  static Color _label(LegendTokens t) => t.colors.onPrimary;

  @override
  State<StatefulChip> createState() => _StatefulChipState();
}

class _StatefulChipState extends State<StatefulChip> {
  @override
  Widget build(BuildContext context) {
    final theme = widget._theme(context);
    return ColoredBox(color: theme.accent.fill ?? theme.label);
  }
}
