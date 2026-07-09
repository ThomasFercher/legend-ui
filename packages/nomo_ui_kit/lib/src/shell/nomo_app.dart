import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/theme/animated_nomo_theme.dart';
import 'package:nomo_ui_kit/src/theme/nomo_breakpoints.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';

/// The app root: wires `WidgetsApp` (navigator + overlay, no Material)
/// with the animated theme and breakpoint scope. Swap [theme] (e.g.
/// light↔dark tokens) and the change animates implicitly.
class NomoApp extends StatelessWidget {
  const NomoApp({
    required this.theme,
    super.key,
    this.home,
    this.routerConfig,
    this.title = '',
    this.themeAnimationDuration = const Duration(milliseconds: 250),
    this.compactBelow = 600,
    this.expandedFrom = 1080,
    this.navigatorKey,
  }) : assert(
         (home != null) ^ (routerConfig != null),
         'Provide either home or routerConfig.',
       );

  final NomoThemeData theme;
  final Widget? home;

  /// Router integration stays decoupled (DESIGN.md §6) — any
  /// `RouterConfig` works; none is required.
  final RouterConfig<Object>? routerConfig;

  final String title;
  final Duration themeAnimationDuration;
  final double compactBelow;
  final double expandedFrom;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    Widget wrap(BuildContext context, Widget? child) {
      return AnimatedNomoTheme(
        data: theme,
        duration: themeAnimationDuration,
        child: NomoBreakpointScope(
          compactBelow: compactBelow,
          expandedFrom: expandedFrom,
          child: Builder(
            builder: (context) {
              final tokens = NomoTheme.of(context).tokens;
              return DefaultTextStyle(
                style: tokens.typography.b1.copyWith(
                  color: tokens.colors.foreground1,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          ),
        ),
      );
    }

    if (routerConfig != null) {
      return WidgetsApp.router(
        title: title,
        color: theme.tokens.colors.primary,
        routerConfig: routerConfig,
        builder: wrap,
      );
    }
    return WidgetsApp(
      title: title,
      color: theme.tokens.colors.primary,
      navigatorKey: navigatorKey,
      home: home,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        );
      },
      builder: wrap,
    );
  }
}
