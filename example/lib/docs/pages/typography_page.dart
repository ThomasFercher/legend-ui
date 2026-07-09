import 'package:example/docs/doc_page.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class TypographyPage extends StatelessWidget {
  const TypographyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return DocPage(
      title: 'Typography & tokens',
      intro:
          'LegendText renders the six token text styles with the right '
          'foreground color by default. The color swatches below read the '
          'live token values — switch presets in the theme panel and watch '
          'them move.',
      children: [
        const DocSection(
          title: 'Type scale',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              LegendText('Heading 1', variant: LegendTextVariant.h1),
              LegendText('Heading 2', variant: LegendTextVariant.h2),
              LegendText('Heading 3', variant: LegendTextVariant.h3),
              LegendText('Body 1 — the default reading size.'),
              LegendText(
                'Body 2 — secondary content.',
                variant: LegendTextVariant.b2,
              ),
              LegendText(
                'Body 3 — captions and labels.',
                variant: LegendTextVariant.b3,
              ),
            ],
          ),
          code: '''
LegendText('Heading 1', variant: LegendTextVariant.h1)
LegendText('Body 1 — the default reading size.')''',
        ),
        DocSection(
          title: 'Color tokens (live)',
          description:
              'The 17 semantic colors in LegendColors. Components never '
              'hard-code colors; they reference these through their theme '
              'defaults.',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            runSpacing: tokens.sizes.sm,
            children: [
              for (final (name, color) in [
                ('primary', tokens.colors.primary),
                ('onPrimary', tokens.colors.onPrimary),
                ('primaryContainer', tokens.colors.primaryContainer),
                ('secondary', tokens.colors.secondary),
                ('surface', tokens.colors.surface),
                ('background1', tokens.colors.background1),
                ('background2', tokens.colors.background2),
                ('background3', tokens.colors.background3),
                ('foreground1', tokens.colors.foreground1),
                ('foreground2', tokens.colors.foreground2),
                ('foreground3', tokens.colors.foreground3),
                ('error', tokens.colors.error),
                ('disabled', tokens.colors.disabled),
              ])
                Column(
                  spacing: 4,
                  children: [
                    LegendSurface(
                      color: color,
                      borderRadius: tokens.sizes.borderRadiusSm,
                      border: Border.all(color: tokens.colors.background3),
                      child: const SizedBox.square(dimension: 48),
                    ),
                    LegendText(name, variant: LegendTextVariant.b3),
                  ],
                ),
            ],
          ),
        ),
        DocSection(
          title: 'Size tokens (live)',
          description:
              'Spacing scale, radii, and icon sizes — the density and '
              'radius controls in the theme panel edit exactly these.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.xs,
            children: [
              for (final (name, value) in [
                ('xs', tokens.sizes.xs),
                ('sm', tokens.sizes.sm),
                ('md', tokens.sizes.md),
                ('lg', tokens.sizes.lg),
                ('xl', tokens.sizes.xl),
                ('xxl', tokens.sizes.xxl),
              ])
                Row(
                  spacing: tokens.sizes.sm,
                  children: [
                    SizedBox(
                      width: 56,
                      child: LegendText(
                        '$name ${value.toStringAsFixed(0)}',
                        variant: LegendTextVariant.b3,
                      ),
                    ),
                    LegendSurface(
                      color: tokens.colors.primary,
                      borderRadius: tokens.sizes.borderRadiusSm,
                      child: SizedBox(width: value * 4, height: 10),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
