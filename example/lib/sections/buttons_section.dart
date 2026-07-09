import 'package:example/main.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

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
                PrimaryNomoButton(text: 'Primary', onPressed: noop),
                SecondaryNomoButton(text: 'Secondary', onPressed: noop),
                NomoTextButton(text: 'Text button', onPressed: noop),
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
                PrimaryNomoButton(
                  text: 'Save',
                  icon: Icons.save_outlined,
                  textFirst: false,
                  onPressed: noop,
                ),
                SecondaryNomoButton(
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
                PrimaryNomoButton(
                  text: 'Disabled',
                  enabled: false,
                  onPressed: noop,
                ),
                // Level-1 override: constructor params beat every theme level.
                PrimaryNomoButton(
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
            PrimaryNomoButtonThemeOverride(
              data: const PrimaryNomoButtonThemeNullable(
                background: Color(0xFF0D9488),
              ),
              child: Wrap(
                spacing: 12,
                children: [
                  PrimaryNomoButton(text: 'Overridden', onPressed: noop),
                  PrimaryNomoButton(text: 'Also overridden', onPressed: noop),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
