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
              // A live LegendPopover — its panel radius follows the theme
              // panel's knob (level-3 override).
              LegendPopover(
                semanticLabel: 'Open popover',
                overlay: (context) => const SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LegendText('Popover', variant: LegendTextVariant.h3),
                      LegendText(
                        'An anchored floating panel. Its corner radius '
                        'follows the popover knob in the theme panel.',
                        variant: LegendTextVariant.b3,
                      ),
                    ],
                  ),
                ),
                child: const LegendCard(child: LegendText('Tap for a popover')),
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
              // Live LegendChips — the selected fill follows the theme
              // panel's knob (level-3 override).
              const _ChipPreview(),
              // A live LegendVerticalMenu — its selected color follows the
              // theme panel's knob (level-3 override).
              const SizedBox(width: 260, child: _MenuPreview()),
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

/// A self-contained row of live [LegendChip]s — a toggling filter chip
/// (whose selected fill is themed by the panel's level-3 override), a
/// dismissible tag, and a number-only citation chip.
class _ChipPreview extends StatefulWidget {
  const _ChipPreview();

  @override
  State<_ChipPreview> createState() => _ChipPreviewState();
}

class _ChipPreviewState extends State<_ChipPreview> {
  var _selected = true;
  var _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return Wrap(
      spacing: tokens.sizes.xs,
      runSpacing: tokens.sizes.xs,
      children: [
        LegendChip(
          label: 'Filter',
          selected: _selected,
          onSelected: (value) => setState(() => _selected = value),
        ),
        if (!_dismissed)
          LegendChip(
            label: 'Dismiss me',
            dismissLabel: 'Remove Dismiss me',
            onDismissed: () => setState(() => _dismissed = true),
          )
        else
          LegendChip(
            label: 'Restore',
            onTap: () => setState(() => _dismissed = false),
          ),
        LegendChip(label: '3', onTap: () {}),
      ],
    );
  }
}

/// A self-contained live [LegendVerticalMenu] with an expandable section,
/// for the playground preview column. Its selected color is themed by the
/// panel's level-3 override.
class _MenuPreview extends StatefulWidget {
  const _MenuPreview();

  @override
  State<_MenuPreview> createState() => _MenuPreviewState();
}

class _MenuPreviewState extends State<_MenuPreview> {
  static const _wallet = LegendNavItem(
    label: 'Wallet',
    children: [
      LegendNavItem(label: 'Balances'),
      LegendNavItem(label: 'History'),
    ],
  );
  static const _items = [
    LegendNavItem(label: 'Dashboard'),
    _wallet,
    LegendNavItem(label: 'Settings'),
  ];

  LegendNavItem _selected = _items.first;

  @override
  Widget build(BuildContext context) {
    return LegendVerticalMenu(
      items: _items,
      selected: _selected,
      initiallyExpanded: const {_wallet},
      onSelected: (item) => setState(() => _selected = item),
    );
  }
}
