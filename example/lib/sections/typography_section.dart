import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = NomoTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        const DemoGroup(
          title: 'Scale',
          children: [
            NomoText('Heading 1', variant: NomoTextVariant.h1),
            NomoText('Heading 2', variant: NomoTextVariant.h2),
            NomoText('Heading 3', variant: NomoTextVariant.h3),
            NomoText('Body 1 — the default reading size.'),
            NomoText(
              'Body 2 — secondary content.',
              variant: NomoTextVariant.b2,
            ),
            NomoText(
              'Body 3 — captions and labels.',
              variant: NomoTextVariant.b3,
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
                      NomoSurface(
                        color: color,
                        borderRadius: tokens.sizes.borderRadiusSm,
                        border: Border.all(color: tokens.colors.background3),
                        child: const SizedBox.square(dimension: 48),
                      ),
                      NomoText(name, variant: NomoTextVariant.b3),
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
