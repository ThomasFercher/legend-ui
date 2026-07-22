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
              // A live LegendNumberField — its stepper-arrow color follows
              // the theme panel's knob (level-3 override).
              const _NumberFieldPreview(),
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
              // A live LegendTooltip — how long you hover before it shows
              // follows the theme panel's delay knob (level-3 override).
              const LegendTooltip(
                message:
                    'The wait before this hint appeared follows the '
                    'tooltip knob in the theme panel.',
                child: LegendCard(child: LegendText('Hover for a tooltip')),
              ),
              // Live badges — their fill follows the theme panel's badge
              // knob (level-3 override).
              Wrap(
                spacing: tokens.sizes.md,
                runSpacing: tokens.sizes.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const LegendBadge('Mainnet'),
                  const LegendBadge.count(120),
                  LegendBadge.dot(
                    semanticLabel: 'Attention',
                    child: LegendSurface(
                      color: tokens.colors.background2,
                      borderRadius: tokens.sizes.borderRadiusMd,
                      child: const SizedBox(width: 32, height: 32),
                    ),
                  ),
                ],
              ),
              // Live LegendAvatars — their shape follows the avatar knob in
              // the theme panel (level-3 override); the seeded pair keeps
              // its deterministic identity colors through every preset.
              Wrap(
                spacing: tokens.sizes.sm,
                children: [
                  const LegendAvatar(initials: 'TF'),
                  const LegendAvatar(seed: 'alice', initials: 'AL'),
                  const LegendAvatar(seed: 'dave', initials: 'DA'),
                  const LegendAvatar(),
                  LegendAvatar(
                    initials: 'TF',
                    badge: LegendSurface(
                      color: tokens.colors.secondary,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: tokens.colors.surface),
                      child: const SizedBox(width: 10, height: 10),
                    ),
                  ),
                ],
              ),
              // A live LegendCheckbox — its checked fill follows the theme
              // panel's knob (level-3 override).
              const _CheckboxPreview(),
              const LegendLoading(),
              // A live LegendBanner — its info strip follows the theme
              // panel's banner knob (level-3 override).
              const LegendBanner(
                title: 'LegendBanner',
                message:
                    'The strip fill follows the banner knob in the theme '
                    'panel.',
              ),
              // A live LegendProgress — its fill color follows the theme
              // panel's knob (level-3 override).
              const LegendProgress.bar(
                value: 0.6,
                semanticLabel: 'Progress preview',
              ),
              // A live LegendTabs — its active indicator follows the
              // theme panel's knob (level-3 override).
              const _TabsPreview(),
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
              // A live LegendSegmented — its thumb color follows the
              // theme panel's knob (level-3 override).
              const _SegmentedPreview(),
              // A live LegendVerticalMenu — its selected color follows the
              // theme panel's knob (level-3 override).
              const SizedBox(width: 260, child: _MenuPreview()),
              // A live LegendList — the selected row's fill follows the
              // theme panel's knob (level-3 override).
              const SizedBox(width: 300, child: _ListPreview()),
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

/// A self-contained live [LegendNumberField] for the playground preview
/// column. Its stepper-arrow color is themed by the panel's level-3
/// override.
class _NumberFieldPreview extends StatefulWidget {
  const _NumberFieldPreview();

  @override
  State<_NumberFieldPreview> createState() => _NumberFieldPreviewState();
}

class _NumberFieldPreviewState extends State<_NumberFieldPreview> {
  double? _value = 2.5;

  @override
  Widget build(BuildContext context) {
    return LegendNumberField(
      title: 'Number field',
      value: _value,
      min: 0,
      max: 100,
      step: 0.5,
      placeholder: '0',
      onChanged: (value) => setState(() => _value = value),
    );
  }
}

/// A self-contained live tristate [LegendCheckbox] for the playground
/// preview column. Its checked fill is themed by the panel's level-3
/// override.
class _CheckboxPreview extends StatefulWidget {
  const _CheckboxPreview();

  @override
  State<_CheckboxPreview> createState() => _CheckboxPreviewState();
}

class _CheckboxPreviewState extends State<_CheckboxPreview> {
  bool? _value = true;

  @override
  Widget build(BuildContext context) {
    return LegendCheckbox(
      value: _value,
      tristate: true,
      label: 'Checkbox — tap to cycle tristate',
      onChanged: (value) => setState(() => _value = value),
    );
  }
}

/// A self-contained live [LegendTabs] for the playground preview column.
/// Its indicator color is themed by the panel's level-3 override.
class _TabsPreview extends StatefulWidget {
  const _TabsPreview();

  @override
  State<_TabsPreview> createState() => _TabsPreviewState();
}

class _TabsPreviewState extends State<_TabsPreview> {
  static const _items = [
    LegendNavItem(label: 'Tokens'),
    LegendNavItem(label: 'NFTs'),
    LegendNavItem(label: 'Activity'),
  ];

  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    return LegendTabs(
      items: _items,
      selectedIndex: _selected,
      onSelected: (index) => setState(() => _selected = index),
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

/// A self-contained live [LegendList] of selectable [LegendListItem]s, for
/// the playground preview column. The selected row's fill is themed by the
/// panel's level-3 override.
class _ListPreview extends StatefulWidget {
  const _ListPreview();

  @override
  State<_ListPreview> createState() => _ListPreviewState();
}

class _ListPreviewState extends State<_ListPreview> {
  static const _tokens = [
    ('Ethereum', 'ETH', r'$3,120.55'),
    ('Bitcoin', 'BTC', r'$67,004.10'),
    ('Solana', 'SOL', r'$142.87'),
  ];

  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    return LegendList(
      header: 'Tokens',
      children: [
        for (final (index, (title, subtitle, value)) in _tokens.indexed)
          LegendListItem(
            title: title,
            subtitle: subtitle,
            trailing: LegendText(value, variant: LegendTextVariant.b3),
            selected: index == _selected,
            onTap: () => setState(() => _selected = index),
          ),
      ],
    );
  }
}

class _SegmentedPreview extends StatefulWidget {
  const _SegmentedPreview();

  @override
  State<_SegmentedPreview> createState() => _SegmentedPreviewState();
}

class _SegmentedPreviewState extends State<_SegmentedPreview> {
  String _timeframe = '1d';

  @override
  Widget build(BuildContext context) {
    return LegendSegmented<String>(
      segments: const [
        LegendSegment(value: '1h', label: '1H'),
        LegendSegment(value: '1d', label: '1D'),
        LegendSegment(value: '1w', label: '1W'),
        LegendSegment(value: '1m', label: '1M'),
        LegendSegment(value: '1y', label: '1Y'),
      ],
      value: _timeframe,
      onChanged: (value) => setState(() => _timeframe = value),
    );
  }
}
