import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        const DemoGroup(
          title: 'Scale',
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
        DemoGroup(
          title: 'Color tokens',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (name, color) in [
                  ('primary', tokens.colors.primary),
                  ('secondary', tokens.colors.secondary),
                  ('surface', tokens.colors.surface),
                  ('background1', tokens.colors.background1),
                  ('background2', tokens.colors.background2),
                  ('background3', tokens.colors.background3),
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
          ],
        ),
      ],
    );
  }
}
