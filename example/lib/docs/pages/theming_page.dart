import 'package:example/docs/doc_page.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

/// Interactive proof of nearest-wins resolution: one target button under
/// four overlapping sources, each level toggleable.
class _ResolutionLadder extends StatefulWidget {
  const _ResolutionLadder();

  @override
  State<_ResolutionLadder> createState() => _ResolutionLadderState();
}

class _ResolutionLadderState extends State<_ResolutionLadder> {
  var _constructor = false;
  var _subtree = false;
  var _midTree = false;

  static const _constructorColor = Color(0xFF8B5CF6); // violet
  static const _subtreeColor = Color(0xFFD97706); // amber
  static const _midTreeColor = Color(0xFF0D9488); // teal

  @override
  Widget build(BuildContext context) {
    final appData = LegendTheme.of(context);
    final tokens = appData.tokens;
    final appOverride = appData
        .component<PrimaryLegendButtonThemeNullable>()
        ?.background;

    Widget target = PrimaryLegendButton(
      text: 'Resolved',
      background: _constructor ? _constructorColor : null,
      onPressed: () {},
    );
    if (_subtree) {
      target = PrimaryLegendButtonThemeOverride(
        data: const PrimaryLegendButtonThemeNullable(
          background: LegendStates(normal: _subtreeColor),
        ),
        child: target,
      );
    }
    if (_midTree) {
      target = LegendTheme(
        data: appData.copyWith(
          components: {
            ...appData.components,
            // RFC-002 R3: keyed by the widget type (wins over a legacy
            // Nullable-type entry when both are present).
            PrimaryLegendButton: const PrimaryLegendButtonThemeNullable(
              background: LegendStates(normal: _midTreeColor),
            ),
          },
        ),
        child: target,
      );
    }

    final winner = _constructor
        ? 'level 1 — constructor param (violet)'
        : _subtree
        ? 'level 2 — subtree override (amber)'
        : _midTree
        ? 'level 3 — mid-tree LegendTheme (teal, nearest)'
        : appOverride != null
        ? 'level 3 — app-level components map (theme panel)'
        : 'level 4 — token default (t.colors.primary)';

    Widget rung(
      String label,
      Color color,
      Key key,
      ValueChanged<bool> onChanged, {
      required bool value,
    }) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: tokens.sizes.xs,
            children: [
              LegendSurface(
                color: color,
                borderRadius: BorderRadius.circular(999),
                child: const SizedBox.square(dimension: 12),
              ),
              LegendText(label, variant: LegendTextVariant.b2),
            ],
          ),
          LegendSwitch(
            key: key,
            value: value,
            semanticLabel: label,
            onChanged: onChanged,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.sm,
      children: [
        rung(
          'Constructor param (level 1)',
          _constructorColor,
          const ValueKey('ladder-constructor'),
          (v) => setState(() => _constructor = v),
          value: _constructor,
        ),
        rung(
          'Subtree override (level 2)',
          _subtreeColor,
          const ValueKey('ladder-subtree'),
          (v) => setState(() => _subtree = v),
          value: _subtree,
        ),
        rung(
          'Mid-tree LegendTheme (level 3)',
          _midTreeColor,
          const ValueKey('ladder-midtree'),
          (v) => setState(() => _midTree = v),
          value: _midTree,
        ),
        const LegendDivider(),
        Row(
          spacing: tokens.sizes.md,
          children: [
            target,
            Expanded(
              child: LegendText(
                'Winner: $winner',
                variant: LegendTextVariant.b3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
                  background: LegendStates(normal: Color(0xFF0D9488)),
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
    // per-state container: name only what you restyle (RFC-002 R6)
    background: LegendStates(normal: Color(0xFF0D9488)),
  ),
  child: PrimaryLegendButton(text: 'Subtree override', ...),
)''',
        ),
        const DocSection(
          title: 'Declaring a themed component',
          description:
              'One var + one annotation, run legend_gen, done. The generator '
              'enforces the contract: themed fields must be nullable with '
              'null constructor defaults, so theme values are always '
              'reachable. Defaults are typed Dart — a const value, or a '
              'tear-off relating the field to the tokens.',
          code: '''
part 'balance_card.theme.g.dart';

@LegendThemeable()
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, this.background, this.padding});

  /// Fill behind the card content.
  @Style<Color>.resolve(_background, lerp: true)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.surface;

  /// Inner padding around the content.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
  static EdgeInsetsGeometry _padding(LegendTokens t) =>
      EdgeInsets.all(t.sizes.md);

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context); // generated, in-library
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
    // reskin a kit component, keyed by the widget type
    // (sparse — only what you set)
    PrimaryLegendButton: const PrimaryLegendButtonThemeNullable(
      background: LegendStates(normal: brand),
    ),
    // and your own component, exactly the same way
    BalanceCard: const BalanceCardThemeNullable(padding: EdgeInsets.all(24)),
  },
)''',
        ),
        const DocSection(
          title: 'Try it: the resolution ladder',
          description:
              'One button, every level stacked. Toggle the levels and watch '
              'the nearest enabled one win — turn them all off and the '
              'button falls back to the token default. The app-level rung '
              'is live too: set "Primary button background" in the theme '
              'panel and it slots in below the mid-tree theme.',
          demo: _ResolutionLadder(),
          code: '''
// level 1 — constructor param on the widget itself
PrimaryLegendButton(background: violet, ...)

// level 2 — subtree override widget
PrimaryLegendButtonThemeOverride(
  data: PrimaryLegendButtonThemeNullable(background: amber),
  child: ...,
)

// level 3 — a LegendTheme anywhere up the tree (nearest wins);
// LegendApp's theme is just the outermost one of these
LegendTheme(
  data: appData.copyWith(components: {
    ...appData.components,
    // keyed by the widget type (the Nullable type still works too)
    PrimaryLegendButton:
        PrimaryLegendButtonThemeNullable(background: teal),
  }),
  child: ...,
)

// level 4 — @Style<Color>.resolve(_background) on the widget''',
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
