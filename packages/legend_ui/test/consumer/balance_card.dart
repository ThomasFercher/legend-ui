import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

part 'balance_card.style.g.dart';
part 'balance_card.theme.g.dart';

/// Consumer-defined `@Style()` value class (RFC-002 R6 amendment 7) — the
/// custom-class half of the consumer workflow proof: same annotation,
/// same generator command, member-wise merge/lerp/== generated into
/// `balance_card.style.g.dart`.
@Style()
class BalanceAccent with _$BalanceAccent {
  const BalanceAccent({this.amount, this.caption});

  /// Color of the amount text.
  final Color? amount;

  /// Color of the caption line under the amount.
  final Color? caption;

  /// Member-wise lerp (generated).
  static BalanceAccent? lerp(BalanceAccent? a, BalanceAccent? b, double t) =>
      _$BalanceAccentLerp(a, b, t);
}

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
  @Style<Color>.resolve(ColorRef.surface, lerp: true)
  final Color? background;

  /// Accent colors of the texts — a consumer-defined style value class:
  /// each member is individually overridable at every theme level.
  @Style<BalanceAccent>.resolve(_accent)
  final BalanceAccent? accent;

  /// Inner padding around the amount.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    return LegendSurface(
      color: theme.background,
      borderRadius: tokens.sizes.borderRadiusLg,
      shadows: tokens.shadows.low,
      padding: theme.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            amount,
            style: tokens.typography.h2.copyWith(color: theme.accent.amount),
          ),
          Text(
            'Balance',
            style: tokens.typography.b3.copyWith(color: theme.accent.caption),
          ),
        ],
      ),
    );
  }
}

EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.all(t.sizes.lg);

BalanceAccent _accent(LegendTokens t) =>
    BalanceAccent(amount: t.colors.secondary, caption: t.colors.foreground2);
