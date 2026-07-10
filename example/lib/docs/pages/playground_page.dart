import 'package:example/docs/doc_page.dart';
import 'package:example/theme/theme_controller.dart';
import 'package:example/theme/theme_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

/// The full-page configurator: theme controls plus a live preview of
/// representative components. On wide screens the same panel is also
/// available site-wide from the app bar.
class PlaygroundPage extends StatelessWidget {
  const PlaygroundPage({required this.controller, super.key});

  final ThemeController controller;

  static String _hex(Color? color) => color == null
      ? '/* unset */'
      : 'Color(0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()})';

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    void noop() {}
    return DocPage(
      title: 'Playground',
      intro:
          'Everything here goes through the public theming API — token '
          'copyWith for the global knobs and the open components map for '
          'the per-component override. The whole site restyles as you edit; '
          'changes animate through AnimatedLegendTheme.',
      children: [
        LegendCard(child: ThemePanel(controller: controller)),
        DocSection(
          title: 'Live preview',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.md,
            children: [
              Wrap(
                spacing: tokens.sizes.sm,
                runSpacing: tokens.sizes.sm,
                children: [
                  PrimaryLegendButton(text: 'Primary', onPressed: noop),
                  SecondaryLegendButton(text: 'Secondary', onPressed: noop),
                  LegendTextButton(text: 'Text', onPressed: noop),
                ],
              ),
              const LegendTextField(
                title: 'Text field',
                placeholder: 'Type here',
              ),
              LegendDropdown<int>(
                placeholder: 'Dropdown',
                items: const [
                  LegendDropdownItem(value: 1, label: 'Option one'),
                  LegendDropdownItem(value: 2, label: 'Option two'),
                ],
                onChanged: (_) {},
              ),
              const LegendCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LegendText('Card', variant: LegendTextVariant.h3),
                    LegendText('Radius and density follow the theme panel.'),
                  ],
                ),
              ),
              const LegendLoading(),
              LegendSurface(
                color: tokens.colors.background1,
                borderRadius: tokens.sizes.borderRadiusMd,
                // A live LegendBody — its centered reading column follows
                // the panel's maxContentWidth knob (level-3 override).
                child: const SizedBox(
                  height: 180,
                  child: LegendBody(
                    children: [
                      LegendText('LegendBody', variant: LegendTextVariant.h3),
                      LegendText(
                        'The reading column narrows and widens with the '
                        'maxContentWidth knob in the theme panel.',
                        variant: LegendTextVariant.b2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'What the override emits',
          description:
              'The component-override section registers this in your '
              'LegendThemeData — sparse, typed, and identical to how your '
              'own generated widget themes plug in:',
          code:
              '''
LegendThemeData(
  tokens: tokens,
  components: {
    PrimaryLegendButtonThemeNullable: PrimaryLegendButtonThemeNullable(
      background: ${controller.buttonBackground == null ? '/* unset */' : 'InteractiveColors(normal: ${_hex(controller.buttonBackground)})'},
    ),
    // shared button surface (RFC-002 R7.2)
    LegendButtonCore: LegendButtonCoreThemeNullable(
      borderRadius: ${controller.buttonRadius == null ? '/* unset */' : 'BorderRadius.circular(${controller.buttonRadius})'},
    ),
  },
)''',
        ),
      ],
    );
  }
}
