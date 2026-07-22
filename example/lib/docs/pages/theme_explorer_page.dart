import 'package:example/docs/doc_page.dart';
import 'package:example/docs/manifest_registry.dart';
import 'package:example/theme/component_configurator.dart';
import 'package:example/theme/playground_chip.dart';
import 'package:example/theme/theme_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

/// The manifest-driven theme explorer (ROADMAP Phase 2.7): every
/// `@LegendThemeable` widget the kit ships, listed from its committed
/// `*.docs.g.dart` manifest, with a type-dispatched editor per themed
/// field. Edits register sparse level-3 `XThemeNullable` overrides in the
/// open components map — the same mechanism the hand-written playground
/// knobs use, scaled to every component with zero per-field code.
class ThemeExplorerPage extends StatefulWidget {
  const ThemeExplorerPage({required this.controller, super.key});

  final ThemeController controller;

  @override
  State<ThemeExplorerPage> createState() => _ThemeExplorerPageState();
}

class _ThemeExplorerPageState extends State<ThemeExplorerPage> {
  PlaygroundComponent _selected = playgroundComponents.first;
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    final matches = playgroundComponents
        .where(
          (component) =>
              component.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return DocPage(
      title: 'Theme explorer',
      intro:
          'Every themed field of every component, straight from the '
          'generated docs manifests (legend_gen docs): pick a component, '
          'edit a field, and a sparse XThemeNullable override registers in '
          'the components map (level 3) — the whole site restyles live. '
          'The doc text and defaults you read here are extracted from the '
          "widgets' own @Style dartdoc.",
      children: [
        LegendCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.md,
            children: [
              const LegendText('Component', variant: LegendTextVariant.h3),
              LegendTextField(
                placeholder: 'Filter components…',
                onChanged: (query) => setState(() => _query = query),
              ),
              if (matches.isEmpty)
                const LegendText(
                  'No component matches the filter.',
                  variant: LegendTextVariant.b3,
                )
              else
                Wrap(
                  spacing: tokens.sizes.xs,
                  runSpacing: tokens.sizes.xs,
                  children: [
                    for (final component in matches)
                      PlaygroundChip(
                        label: component.name,
                        selected: component.type == _selected.type,
                        onTap: () => setState(() => _selected = component),
                      ),
                  ],
                ),
              const LegendDivider(),
              ComponentConfigurator(
                controller: widget.controller,
                selected: _selected,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
