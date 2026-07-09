import 'package:example/docs/doc_page.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class ThemingPage extends StatelessWidget {
  const ThemingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    void noop() {}
    return DocPage(
      title: 'Theming',
      intro:
          'One immutable LegendTokens object is the only global theme: 17 '
          'semantic colors, a spacing/radius/icon scale, six text styles, '
          'and one shadow system. Component themes derive from it and stay '
          'overridable at four levels — nearest wins.',
      children: [
        DocSection(
          title: 'The four resolution levels',
          description:
              '1. Constructor parameter\n'
              '2. Subtree override (XThemeOverride inherited widget)\n'
              '3. App theme — LegendThemeData.components[Type]\n'
              '4. Token-derived annotation defaults (the kit defaults)\n\n'
              'The two buttons below are identical widgets: the first '
              'resolves from tokens, the second sits under a subtree '
              'override.',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            runSpacing: tokens.sizes.sm,
            children: [
              PrimaryLegendButton(text: 'Token default', onPressed: noop),
              PrimaryLegendButtonThemeOverride(
                data: const PrimaryLegendButtonThemeNullable(
                  background: Color(0xFF0D9488),
                ),
                child: PrimaryLegendButton(
                  text: 'Subtree override',
                  onPressed: noop,
                ),
              ),
            ],
          ),
          code: '''
PrimaryLegendButtonThemeOverride(
  data: const PrimaryLegendButtonThemeNullable(
    background: Color(0xFF0D9488),
  ),
  child: PrimaryLegendButton(text: 'Subtree override', ...),
)''',
        ),
        const DocSection(
          title: 'Declaring a themed component',
          description:
              'Annotate the widget, run legend_gen, done. The generator '
              'enforces the contract: themed fields must be nullable with '
              'null constructor defaults, so theme values are always '
              'reachable. Defaults are expressions over the tokens (t).',
          code: '''
@LegendThemeable()
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, this.background, this.padding});

  @Themed(defaultsTo: 't.colors.surface', lerp: true)
  final Color? background;

  @Themed(defaultsTo: 'EdgeInsets.all(t.sizes.md)')
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = BalanceCardTheme.of(
      context,
      BalanceCardThemeNullable(background: background, padding: padding),
    );
    ...
  }
}''',
        ),
        const DocSection(
          title: 'Your widgets are first-class citizens',
          description:
              'LegendThemeData.components is an open, Type-keyed map. Your '
              "generated theme registers next to the kit's own entries — "
              'same declaration, same artifacts, same resolution. No '
              'registration lists, no naming conventions.',
          code: '''
LegendThemeData(
  tokens: LegendTokens.light,
  components: {
    // reskin a kit component (sparse — only what you set)
    PrimaryLegendButtonThemeNullable:
        const PrimaryLegendButtonThemeNullable(background: brand),
    // and your own component, exactly the same way
    BalanceCardThemeNullable:
        const BalanceCardThemeNullable(padding: EdgeInsets.all(24)),
  },
)''',
        ),
        const DocSection(
          title: 'Animated theme switches',
          description:
              'LegendApp animates token changes implicitly (250 ms default). '
              'The whole switch costs one LegendTokens lerp; component '
              'themes re-derive from the animating tokens. Try it: flip the '
              'presets in the theme panel.',
          code: '''
LegendApp(
  theme: LegendThemeData(tokens: dark ? LegendTokens.dark : LegendTokens.light),
  themeAnimationDuration: const Duration(milliseconds: 250),
  ...
)''',
        ),
      ],
    );
  }
}
