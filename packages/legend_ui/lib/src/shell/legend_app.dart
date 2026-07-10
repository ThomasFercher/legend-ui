import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/theme/animated_legend_theme.dart';
import 'package:legend_ui/src/theme/legend_breakpoints.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';

/// The app root: wires `WidgetsApp` (navigator + overlay, no Material)
/// with the animated theme and breakpoint scope. Swap [theme] (e.g.
/// light↔dark tokens) and the change animates implicitly.
///
/// Rebuild behavior (2026-07-10 audit): while a theme switch animates,
/// every theme dependent — including every [Text], via the root
/// [DefaultTextStyle] derived from the animating tokens — rebuilds once
/// per frame. That is semantically necessary while text color animates
/// and correctly inert at rest; keep page subtrees `const`-heavy and pass
/// a **stable** [home] instance (build it once, not inside a listenable
/// builder) so per-frame rebuilds stay shallow.
///
/// On Android, Material apps default to predictive-back page transitions
/// since Flutter 3.38; the kit's fade page transition does not
/// participate in predictive back yet (tracked in ROADMAP audit
/// follow-ups).
class LegendApp extends StatelessWidget {
  const LegendApp({
    required this.theme,
    super.key,
    this.home,
    this.routerConfig,
    this.title = '',
    this.themeAnimationDuration = const Duration(milliseconds: 250),
    this.compactBelow = 600,
    this.expandedFrom = 1080,
    this.navigatorKey,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales = const [Locale('en', 'US')],
    this.onGenerateTitle,
    this.restorationScopeId,
    this.shortcuts,
    this.actions,
    this.debugShowCheckedModeBanner = true,
  }) : assert(
         (home != null) ^ (routerConfig != null),
         'Provide either home or routerConfig.',
       ),
       assert(
         navigatorKey == null || routerConfig == null,
         'navigatorKey is owned by the router when routerConfig is set — '
         'pass the key to your router instead.',
       );

  final LegendThemeData theme;
  final Widget? home;

  /// Router integration stays decoupled (DESIGN.md §6) — any
  /// `RouterConfig` works; none is required.
  final RouterConfig<Object>? routerConfig;

  final String title;
  final Duration themeAnimationDuration;
  final double compactBelow;
  final double expandedFrom;
  final GlobalKey<NavigatorState>? navigatorKey;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final Iterable<Locale> supportedLocales;
  final GenerateAppTitle? onGenerateTitle;

  /// State-restoration scope for the whole app (`WidgetsApp` passthrough).
  final String? restorationScopeId;

  /// App-wide keyboard shortcuts; null keeps `WidgetsApp` defaults.
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// App-wide actions; null keeps `WidgetsApp` defaults.
  final Map<Type, Action<Intent>>? actions;

  /// Hides the debug banner when false (`WidgetsApp` passthrough).
  final bool debugShowCheckedModeBanner;

  @override
  Widget build(BuildContext context) {
    Widget wrap(BuildContext context, Widget? child) {
      return AnimatedLegendTheme(
        data: theme,
        duration: themeAnimationDuration,
        child: LegendBreakpointScope(
          compactBelow: compactBelow,
          expandedFrom: expandedFrom,
          child: Builder(
            builder: (context) {
              final tokens = LegendTheme.of(context).tokens;
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
        onGenerateTitle: onGenerateTitle,
        color: theme.tokens.colors.primary,
        routerConfig: routerConfig,
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        restorationScopeId: restorationScopeId,
        shortcuts: shortcuts,
        actions: actions,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        builder: wrap,
      );
    }
    return WidgetsApp(
      title: title,
      onGenerateTitle: onGenerateTitle,
      color: theme.tokens.colors.primary,
      navigatorKey: navigatorKey,
      home: home,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      restorationScopeId: restorationScopeId,
      shortcuts: shortcuts,
      actions: actions,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
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
