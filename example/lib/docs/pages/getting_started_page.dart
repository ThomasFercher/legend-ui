import 'package:example/docs/doc_page.dart';
import 'package:flutter/widgets.dart';

class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DocPage(
      title: 'Getting started',
      intro:
          'Legend UI is a Material-free Flutter component kit built on '
          'design tokens, decorator-declared component themes, and the '
          'legend_gen codegen CLI. This site is itself a Legend UI app — '
          'every page you see is built from the public API, and the theme '
          'panel restyles it live.',
      children: [
        DocSection(
          title: 'Install',
          description:
              'Add the kit and the generator to your app (the generator is '
              'a dev dependency — it only runs at development time).',
          code: '''
dependencies:
  legend_ui: ^1.0.0

dev_dependencies:
  legend_gen: ^0.1.0''',
        ),
        DocSection(
          title: 'Bootstrap the app',
          description:
              'LegendApp wires WidgetsApp with the animated theme and the '
              'breakpoint scope. Swap the theme (for example light to dark '
              'tokens) and the change animates implicitly — one token lerp, '
              'not one per component.',
          code: '''
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LegendApp(
      title: 'My app',
      theme: LegendThemeData(tokens: LegendTokens.light),
      home: const HomeScreen(),
    );
  }
}''',
        ),
        DocSection(
          title: 'Routers welcome',
          description:
              'Navigation stays decoupled: pass any RouterConfig (go_router, '
              'auto_route, hand-rolled) instead of home. The kit never owns '
              'your navigation.',
          code: '''
LegendApp.router:  // any RouterConfig works
LegendApp(theme: myTheme, routerConfig: goRouter)''',
        ),
        DocSection(
          title: 'Generate themes',
          description:
              'Component themes are declared with decorators on the widget '
              'and generated next to the source. Run once, check the output '
              'in, and let CI keep it fresh.',
          code: '''
dart run legend_gen themes lib          # generate
dart run legend_gen themes lib --check  # CI freshness gate
dart run legend_gen themes lib --watch  # regenerate on save
dart run legend_gen create LegendBadge  # scaffold a new component
dart run legend_gen doctor              # find stale/orphaned output''',
        ),
      ],
    );
  }
}
