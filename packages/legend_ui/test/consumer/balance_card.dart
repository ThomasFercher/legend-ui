import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

part 'balance_card.theme.g.dart';

/// Consumer-workflow rehearsal (ROADMAP Phase 0): this widget stands in
/// for one written by a *dependent* of the kit — it uses only the public
/// barrel, the same decorators, and the same generator command
/// (`dart run legend_gen themes test/consumer`). If this file ever needs
/// kit-internal imports, the consumer story is broken.
@LegendThemeable()
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.amount,
    super.key,
    this.background,
    this.accent,
    this.padding,
  });

  final String amount;

  /// Fill color of the card surface.
  @Style<Color>.resolve(_background, lerp: true)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.surface;

  /// Color of the amount text.
  @Style<Color>.resolve(_accent)
  final Color? accent;
  static Color _accent(LegendTokens t) => t.colors.secondary;

  /// Inner padding around the amount.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
  static EdgeInsetsGeometry _padding(LegendTokens t) =>
      EdgeInsets.all(t.sizes.lg);

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    return LegendSurface(
      color: theme.background,
      borderRadius: tokens.sizes.borderRadiusLg,
      shadows: tokens.shadows.low,
      padding: theme.padding,
      child: Text(
        amount,
        style: tokens.typography.h2.copyWith(color: theme.accent),
      ),
    );
  }
}
