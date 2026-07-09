import 'package:example/docs/doc_page.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class ButtonsPage extends StatelessWidget {
  const ButtonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    void noop() {}
    return DocPage(
      title: 'Buttons',
      intro:
          'Three variants on one shared LegendButtonCore chassis: primary '
          '(filled), secondary (outlined), and text (transparent). Disabled '
          'buttons are genuinely inert — no hit-testing, no keyboard '
          'activation — and every button activates with Enter or Space.',
      children: [
        DocSection(
          title: 'Variants',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            runSpacing: tokens.sizes.sm,
            children: [
              PrimaryLegendButton(text: 'Primary', onPressed: noop),
              SecondaryLegendButton(text: 'Secondary', onPressed: noop),
              LegendTextButton(text: 'Text button', onPressed: noop),
            ],
          ),
          code: '''
PrimaryLegendButton(text: 'Primary', onPressed: save)
SecondaryLegendButton(text: 'Secondary', onPressed: share)
LegendTextButton(text: 'Text button', onPressed: dismiss)''',
        ),
        DocSection(
          title: 'With icons',
          description: 'Any IconData; textFirst flips the order.',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            runSpacing: tokens.sizes.sm,
            children: [
              PrimaryLegendButton(
                text: 'Save',
                icon: Icons.save_outlined,
                textFirst: false,
                onPressed: noop,
              ),
              SecondaryLegendButton(
                text: 'Share',
                icon: Icons.ios_share,
                onPressed: noop,
              ),
            ],
          ),
          code: '''
PrimaryLegendButton(
  text: 'Save',
  icon: Icons.save_outlined,
  textFirst: false,
  onPressed: save,
)''',
        ),
        DocSection(
          title: 'States and inline overrides',
          description:
              'Constructor parameters are resolution level 1 — they beat '
              'every theme. Disabled text buttons stay transparent instead '
              'of growing a grey slab.',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            runSpacing: tokens.sizes.sm,
            children: [
              PrimaryLegendButton(
                text: 'Disabled',
                enabled: false,
                onPressed: noop,
              ),
              LegendTextButton(
                text: 'Disabled text',
                enabled: false,
                onPressed: noop,
              ),
              PrimaryLegendButton(
                text: 'Custom',
                background: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(24),
                onPressed: noop,
              ),
            ],
          ),
          code: '''
PrimaryLegendButton(
  text: 'Custom',
  background: const Color(0xFF8B5CF6),   // level 1: beats every theme
  borderRadius: BorderRadius.circular(24),
  onPressed: submit,
)''',
        ),
        const DocSection(
          title: 'PrimaryLegendButton theme surface',
          description:
              'Overridable per constructor, subtree, or the app components '
              'map. Secondary and text buttons expose the same set (plus '
              'border for secondary).',
          demo: PropsTable(
            rows: [
              (
                name: 'background',
                type: 'Color',
                defaultsTo: 't.colors.primary',
              ),
              (
                name: 'foreground',
                type: 'Color',
                defaultsTo: 't.colors.onPrimary',
              ),
              (
                name: 'padding',
                type: 'EdgeInsetsGeometry',
                defaultsTo:
                    'EdgeInsets.symmetric(h: t.sizes.md, v: t.sizes.sm)',
              ),
              (
                name: 'borderRadius',
                type: 'BorderRadius',
                defaultsTo: 't.sizes.borderRadiusMd',
              ),
              (
                name: 'textStyle',
                type: 'TextStyle',
                defaultsTo: 't.typography.b2',
              ),
              (
                name: 'shadows',
                type: 'List<BoxShadow>',
                defaultsTo: 't.shadows.none',
              ),
            ],
          ),
        ),
        const DocSection(
          title: 'Build your own variant',
          description:
              'LegendButtonCore is public: interaction states, surface '
              'styling, and the content row are the chassis — bring your '
              'own resolved theme.',
          code: '''
LegendButtonCore(
  onPressed: onPressed,
  background: myTheme.background,
  foreground: myTheme.foreground,
  padding: myTheme.padding,
  borderRadius: myTheme.borderRadius,
  textStyle: myTheme.textStyle,
  text: 'Danger',
)''',
        ),
      ],
    );
  }
}
