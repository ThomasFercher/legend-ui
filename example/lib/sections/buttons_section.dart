import 'package:example/main.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class ButtonsSection extends StatelessWidget {
  const ButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        DemoGroup(
          title: 'Variants',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                PrimaryLegendButton(text: 'Primary', onPressed: noop),
                SecondaryLegendButton(text: 'Secondary', onPressed: noop),
                LegendTextButton(text: 'Text button', onPressed: noop),
              ],
            ),
          ],
        ),
        DemoGroup(
          title: 'With icons',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
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
          ],
        ),
        DemoGroup(
          title: 'States',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                PrimaryLegendButton(
                  text: 'Disabled',
                  enabled: false,
                  onPressed: noop,
                ),
                // Level-1 override: constructor params beat every theme level.
                PrimaryLegendButton(
                  text: 'Custom',
                  background: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(24),
                  onPressed: noop,
                ),
              ],
            ),
          ],
        ),
        DemoGroup(
          title: 'Subtree override (level 2)',
          children: [
            PrimaryLegendButtonThemeOverride(
              data: const PrimaryLegendButtonThemeNullable(
                background: Color(0xFF0D9488),
              ),
              child: Wrap(
                spacing: 12,
                children: [
                  PrimaryLegendButton(text: 'Overridden', onPressed: noop),
                  PrimaryLegendButton(text: 'Also overridden', onPressed: noop),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
