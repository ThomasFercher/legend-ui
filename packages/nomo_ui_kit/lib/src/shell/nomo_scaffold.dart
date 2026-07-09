import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/shell/nomo_scaffold.theme.g.dart';
import 'package:nomo_ui_kit/src/theme/nomo_breakpoints.dart';

/// The page shell: app bar on top, sider on wide tiers, bottom bar on the
/// compact tier — driven by [NomoBreakpoints], NOT by theme swaps
/// (legacy flipped nav chrome by swapping the sizing theme; DESIGN §2.4).
///
/// No Material `Scaffold` underneath.
@NomoThemeable()
class NomoScaffold extends StatelessWidget {
  const NomoScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.sider,
    this.bottomBar,
    this.background,
  });

  final Widget body;
  final Widget? appBar;

  /// Shown at [NomoTier.medium] and above.
  final Widget? sider;

  /// Shown at [NomoTier.compact].
  final Widget? bottomBar;

  @Themed(defaultsTo: 't.colors.background1', lerp: true)
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = NomoScaffoldTheme.of(
      context,
      NomoScaffoldThemeNullable(background: background),
    );
    final tier = NomoBreakpoints.of(context).tier;
    final compact = tier == NomoTier.compact;
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
