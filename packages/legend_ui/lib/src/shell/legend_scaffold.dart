import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/theme/legend_breakpoints.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_scaffold.theme.g.dart';

/// The page shell: app bar on top, sider on wide tiers, bottom bar on the
/// compact tier — driven by [LegendBreakpoints], NOT by theme swaps
/// (legacy flipped nav chrome by swapping the sizing theme; DESIGN §2.4).
///
/// No Material `Scaffold` underneath.
@LegendThemeable()
class LegendScaffold extends StatelessWidget {
  const LegendScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.sider,
    this.bottomBar,
    this.background,
  });

  final Widget body;
  final Widget? appBar;

  /// Shown at [LegendTier.medium] and above.
  final Widget? sider;

  /// Shown at [LegendTier.compact].
  final Widget? bottomBar;

  /// Fill color behind the page body.
  @Style<Color>.resolve(LegendColorsRef.background1, lerp: true)
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tier = LegendBreakpoints.of(context).tier;
    final compact = tier == LegendTier.compact;
    final showSider = !compact && sider != null;
    final showBottomBar = compact && bottomBar != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      color: theme.background,
      child: Column(
        children: [
          if (appBar != null) appBar!,
          Expanded(
            child: Row(
              children: [
                if (showSider) sider!,
                Expanded(child: body),
              ],
            ),
          ),
          if (showBottomBar) bottomBar!,
        ],
      ),
    );
  }
}
