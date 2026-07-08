import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

import 'balance_card.theme.g.dart';

/// Consumer-workflow rehearsal (ROADMAP Phase 0): this widget stands in
/// for one written by a *dependent* of the kit — it uses only the public
/// barrel, the same decorators, and the same generator command
/// (`dart run nomo_gen themes test/consumer`). If this file ever needs
/// kit-internal imports, the consumer story is broken.
@NomoThemeable()
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.amount,
    super.key,
    this.background,
    this.accent,
    this.padding,
  });

  final String amount;

  @Themed(defaultsTo: 't.colors.surface', lerp: true)
  final Color? background;

  @Themed(defaultsTo: 't.colors.secondary')
  final Color? accent;

  @Themed(defaultsTo: 'EdgeInsets.all(t.sizes.lg)')
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = BalanceCardTheme.of(
      context,
      BalanceCardThemeNullable(
        background: background,
        accent: accent,
        padding: padding,
      ),
    );
    final tokens = NomoTheme.of(context).tokens;
    return NomoSurface(
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
