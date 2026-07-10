import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

part 'rebuild_probe.theme.g.dart';

/// R12 rebuild probe (consumer-workflow fixture, like `balance_card.dart`):
/// a themed widget with one listened field and one `listen: false` field,
/// plus an observer callback so tests can count builds.
@LegendThemeable()
class ProbeBox extends StatelessWidget {
  const ProbeBox({super.key, this.onBuild, this.tint, this.gap});

  /// Build observer for rebuild-count tests (not themed).
  final VoidCallback? onBuild;

  /// Listened fill — a resolved-value change rebuilds the widget.
  @Style<Color>.resolve(ColorRef.primary)
  final Color? tint;

  /// Latched spacing: `listen: false` (RFC-002 R12.2) — resolved fresh on
  /// every build, never a rebuild source by itself.
  @Style<double>.value(8, listen: false)
  final double? gap;

  @override
  Widget build(BuildContext context) {
    onBuild?.call();
    final theme = _theme(context);
    return Padding(
      padding: EdgeInsets.all(theme.gap),
      child: ColoredBox(color: theme.tint),
    );
  }
}

/// Second widget type: registry changes for it must never rebuild
/// [ProbeBox] dependents (the R12 audit regression scenario).
@LegendThemeable()
class OtherBox extends StatelessWidget {
  const OtherBox({super.key, this.onBuild, this.fill});

  /// Build observer for rebuild-count tests (not themed).
  final VoidCallback? onBuild;

  /// Fill of the other box.
  @Style<Color>.resolve(ColorRef.secondary)
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    onBuild?.call();
    return ColoredBox(color: _theme(context).fill);
  }
}

/// Consumes exactly ONE themed property through the generated per-field
/// accessor (RFC-002 R12.3) — only that field's aspect is registered.
@LegendThemeable()
class TintOnlyBox extends StatelessWidget {
  const TintOnlyBox({super.key, this.onBuild, this.tint, this.gap});

  /// Build observer for rebuild-count tests (not themed).
  final VoidCallback? onBuild;

  /// Listened fill — the only property this widget's build consumes.
  @Style<Color>.resolve(ColorRef.primary)
  final Color? tint;

  /// A second themed field the build never reads: its changes must not
  /// rebuild this widget.
  @Style<double>(8)
  final double? gap;

  @override
  Widget build(BuildContext context) {
    onBuild?.call();
    return ColoredBox(color: _tint(context));
  }
}
