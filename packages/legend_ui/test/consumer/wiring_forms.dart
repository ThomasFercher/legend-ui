import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

part 'wiring_forms.theme.g.dart';

// R13 wiring rehearsal (consumer-workflow fixture): the four supported
// forms, one widget each. The HOOK form (`final theme = _theme(context);`
// in a plain StatelessWidget.build) is the default used by BalanceCard
// and most kit widgets, so it is not repeated here.

/// Form 2 — auto-detected State getter: a plain State, zero visible
/// wiring; the generated extension on [_AutoGetterChipState] provides
/// `theme`.
@LegendThemeable()
class AutoGetterChip extends StatefulWidget {
  const AutoGetterChip({super.key, this.fill});

  /// Fill of the chip.
  @Style<Color>.resolve(ColorRef.primary)
  final Color? fill;

  @override
  State<AutoGetterChip> createState() => _AutoGetterChipState();
}

class _AutoGetterChipState extends State<AutoGetterChip> {
  @override
  Widget build(BuildContext context) => ColoredBox(color: theme.fill);
}

/// Form 3 — the explicit mixin: `with _$MixinChipThemeState` makes
/// `theme` a real, overridable inherited member. Its State ALSO matches
/// the auto-detection, so this fixture doubles as the coexistence proof
/// (the instance member from the mixin wins over the extension).
@LegendThemeable()
class MixinChip extends StatefulWidget {
  const MixinChip({super.key, this.fill});

  /// Fill of the chip.
  @Style<Color>.resolve(ColorRef.secondary)
  final Color? fill;

  @override
  State<MixinChip> createState() => _MixinChipState();
}

class _MixinChipState extends State<MixinChip> with _$MixinChipThemeState {
  @override
  Widget build(BuildContext context) => ColoredBox(color: theme.fill);
}

/// Form 4 — the opt-in base (RFC-002 R13, opt-in base): `extends
/// _$BaseChipBase` swaps StatelessWidget for the two-argument
/// `build(context, theme)`; themed fields implement the generated
/// abstract getters, so they carry `@override`.
@LegendThemeable()
class BaseChip extends _$BaseChipBase {
  const BaseChip({super.key, this.fill});

  /// Fill of the chip.
  @override
  @Style<Color>.resolve(ColorRef.surface)
  final Color? fill;

  @override
  Widget build(BuildContext context, BaseChipTheme theme) =>
      ColoredBox(color: theme.fill);
}
