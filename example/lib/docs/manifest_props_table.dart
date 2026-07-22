import 'package:example/docs/doc_page.dart';
import 'package:example/docs/manifest_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

/// A component's `@Style` surface rendered straight from its generated
/// docs manifest (RFC-002 R9): property, declared type, and the
/// token-derived default expression — always in sync with the widget
/// source, unlike a hand-written [PropsTable]. Dot-path state members
/// fold into their base row; every row is overridable at all four
/// resolution levels.
class ManifestPropsTable extends StatelessWidget {
  const ManifestPropsTable({required this.component, super.key});

  /// The widget type, resolved through the theme-explorer registry.
  final Type component;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    final mono = tokens.typography.b3.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Courier'],
    );
    final entries = playgroundComponentByType[component]!.entries.where(
      (entry) => !entry.name.contains('.'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.xs,
      children: [
        const LegendText('Themed properties', variant: LegendTextVariant.b3),
        for (final entry in entries)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.name,
                  style: mono.copyWith(color: tokens.colors.foreground1),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  entry.type.endsWith('?')
                      ? entry.type.substring(0, entry.type.length - 1)
                      : entry.type,
                  style: mono.copyWith(color: tokens.colors.foreground3),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  entry.defaultDescription,
                  style: mono.copyWith(color: tokens.colors.foreground2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// A ready-made `<X> theme surface` docs section over [ManifestPropsTable]
/// — one line per widget on its docs page, mirroring the hand-written
/// sections the older pages carry.
class ThemeSurfaceSection extends StatelessWidget {
  const ThemeSurfaceSection({required this.component, super.key});

  /// The widget type, resolved through the theme-explorer registry.
  final Type component;

  @override
  Widget build(BuildContext context) {
    return DocSection(
      title: '${playgroundComponentByType[component]!.name} theme surface',
      description:
          'Extracted from the @Style dartdoc in the widget source '
          '(legend_gen docs). Overridable per constructor, subtree, or '
          'the app components map — edit it live in the Theme explorer.',
      demo: ManifestPropsTable(component: component),
    );
  }
}
