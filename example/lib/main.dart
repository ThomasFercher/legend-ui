import 'package:example/docs/pages/buttons_page.dart';
import 'package:example/docs/pages/feedback_page.dart';
import 'package:example/docs/pages/getting_started_page.dart';
import 'package:example/docs/pages/inputs_page.dart';
import 'package:example/docs/pages/layout_page.dart';
import 'package:example/docs/pages/overlays_page.dart';
import 'package:example/docs/pages/playground_page.dart';
import 'package:example/docs/pages/selection_page.dart';
import 'package:example/docs/pages/shell_page.dart';
import 'package:example/docs/pages/theming_page.dart';
import 'package:example/docs/pages/typography_page.dart';
import 'package:example/theme/theme_controller.dart';
import 'package:example/theme/theme_panel.dart';
import 'package:flutter/material.dart'
    show DefaultMaterialLocalizations, Icons, SelectionArea;
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

void main() {
  // A docs site should be born accessible: force the semantics tree on so
  // screen readers (and UI-driving tools) see every widget without the
  // "enable accessibility" bootstrap tap Flutter web otherwise requires.
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(const DocsApp());
}

/// The Legend UI documentation site + playground. It is itself a Legend UI
/// consumer app: public barrel only, themed live by [ThemeController].
class DocsApp extends StatefulWidget {
  const DocsApp({super.key});

  @override
  State<DocsApp> createState() => _DocsAppState();
}

class _DocsAppState extends State<DocsApp> {
  final _theme = ThemeController();

  // The reference rebuild pattern (2026-07-10 audit): the home subtree is
  // built ONCE and reused, so a controller tick rebuilds only LegendApp
  // and actual theme dependents — not the whole tree. Rebuilding children
  // inline under the root ListenableBuilder rebuilt every widget 17× per
  // theme toggle (measured).
  late final Widget _home = _DocsShell(controller: _theme);

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _theme,
      builder: (context, _) => LegendApp(
        title: 'Legend UI',
        theme: _theme.data,
        // SelectionArea (Material's selection wrapper) needs
        // MaterialLocalizations; LegendApp is WidgetsApp-based, so a consumer
        // supplies the delegate through the localizations passthrough.
        localizationsDelegates: const [DefaultMaterialLocalizations.delegate],
        home: _home,
      ),
    );
  }
}

/// The docs shell: app bar, sider, page switcher, theme side panel. Kept
/// stable across theme changes (see [_DocsAppState]); it rebuilds only as
/// a theme/breakpoint dependent.
class _DocsShell extends StatefulWidget {
  const _DocsShell({required this.controller});

  final ThemeController controller;

  @override
  State<_DocsShell> createState() => _DocsShellState();
}

class _DocsShellState extends State<_DocsShell> {
  var _page = 0;
  var _panelOpen = false;

  static const _nav = [
    LegendNavItem(label: 'Start', icon: Icons.rocket_launch_outlined),
    LegendNavItem(label: 'Theming', icon: Icons.palette_outlined),
    LegendNavItem(label: 'Buttons', icon: Icons.smart_button),
    LegendNavItem(label: 'Typography', icon: Icons.text_fields),
    LegendNavItem(label: 'Inputs', icon: Icons.edit_outlined),
    LegendNavItem(label: 'Selection', icon: Icons.check_circle_outline),
    LegendNavItem(label: 'Overlays', icon: Icons.layers_outlined),
    LegendNavItem(label: 'Layout', icon: Icons.dashboard_outlined),
    LegendNavItem(label: 'Feedback', icon: Icons.hourglass_empty),
    LegendNavItem(label: 'Shell', icon: Icons.web_asset),
    LegendNavItem(label: 'Playground', icon: Icons.tune),
  ];

  Widget _buildPage(int index) => switch (index) {
    0 => const GettingStartedPage(),
    1 => const ThemingPage(),
    2 => const ButtonsPage(),
    3 => const TypographyPage(),
    4 => const InputsPage(),
    5 => const SelectionPage(),
    6 => const OverlaysPage(),
    7 => const LayoutPage(),
    8 => const FeedbackPage(),
    9 => const ShellPage(),
    _ => PlaygroundPage(controller: widget.controller),
  };

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    final compact = LegendBreakpoints.tierOf(context) == LegendTier.compact;
    // SelectionArea makes all doc prose selectable on web (CanvasKit paints
    // text to a canvas, so nothing is selectable without it).
    final content = SelectionArea(
      child: SingleChildScrollView(
        key: ValueKey(_page),
        padding: EdgeInsets.all(tokens.sizes.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: _buildPage(_page),
        ),
      ),
    );

    return LegendScaffold(
      appBar: LegendAppBar(
        title: compact ? _nav[_page].label : 'Legend UI — ${_nav[_page].label}',
        leading: compact
            ? Semantics(
                label: 'Navigation',
                child: LegendTextButton(
                  icon: Icons.menu,
                  onPressed: () => _openCompactNav(context),
                ),
              )
            : null,
        actions: [
          const LegendText('Dark', variant: LegendTextVariant.b3),
          // The shell is deliberately not rebuilt per controller tick, so
          // the switch listens on its own (narrowest-listener pattern).
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => LegendSwitch(
              value: widget.controller.dark,
              semanticLabel: 'Dark mode',
              onChanged: (v) => widget.controller.setDark(value: v),
            ),
          ),
          if (!compact)
            LegendTextButton(
              icon: Icons.tune,
              text: 'Customize',
              onPressed: () => setState(() => _panelOpen = !_panelOpen),
            ),
        ],
      ),
      sider: LegendSider(
        items: _nav,
        selectedIndex: _page,
        onSelected: (i) => setState(() => _page = i),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: content),
          if (_panelOpen && !compact)
            LegendSurface(
              color: tokens.colors.surface,
              child: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(tokens.sizes.md),
                  child: ThemePanel(controller: widget.controller),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Compact-tier navigation: a bottom sheet instead of squeezing eleven
  /// items into a bottom bar.
  void _openCompactNav(BuildContext context) {
    showLegendModal<void>(
      context: context,
      alignment: Alignment.bottomCenter,
      builder: (sheetContext) {
        final tokens = LegendTheme.of(sheetContext).tokens;
        return LegendSurface(
          color: tokens.colors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.sizes.radiusLg),
          ),
          padding: EdgeInsets.all(tokens.sizes.sm),
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, item) in _nav.indexed)
                    LegendInteractive(
                      semanticLabel: item.label,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        setState(() => _page = index);
                      },
                      builder: (context, states) => LegendSurface(
                        color: index == _page
                            ? tokens.colors.primaryContainer
                            : states.hovered
                            ? tokens.colors.background2
                            : tokens.colors.surface,
                        borderRadius: tokens.sizes.borderRadiusSm,
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.sizes.md,
                          vertical: tokens.sizes.sm,
                        ),
                        child: Text(
                          item.label,
                          style: tokens.typography.b2.copyWith(
                            color: tokens.colors.foreground1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
