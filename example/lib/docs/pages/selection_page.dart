import 'package:example/docs/doc_page.dart';
import 'package:example/docs/manifest_props_table.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class SelectionPage extends StatefulWidget {
  const SelectionPage({super.key});

  @override
  State<SelectionPage> createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  String? _fruit;
  String? _plan = 'monthly';
  var _notifications = true;
  var _newsletter = false;
  final _networks = {'Ethereum'};
  var _tags = ['Design', 'Engineering', 'Research'];
  var _backup = false;
  bool? _sources = false;
  var _timeframe = '1d';
  var _currency = 'crypto';

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return DocPage(
      title: 'Selection',
      intro:
          'One dropdown with one item model, plus a checkbox, a radio group '
          'and a switch that are honest to assistive tech: each announces '
          'its real role with its state — checkbox with the tristate mixed '
          'value, radio as checked within a mutually exclusive group, '
          'toggle with on/off — never as a button.',
      children: [
        DocSection(
          title: 'Dropdown',
          description:
              'Anchored to its trigger via the overlay engine; long lists '
              'scroll past the themed menuMaxHeight instead of overflowing.',
          demo: LegendDropdown<String>(
            placeholder: 'Pick a fruit',
            value: _fruit,
            items: const [
              LegendDropdownItem(value: 'apple', label: 'Apple'),
              LegendDropdownItem(value: 'banana', label: 'Banana'),
              LegendDropdownItem(value: 'cherry', label: 'Cherry'),
            ],
            onChanged: (value) => setState(() => _fruit = value),
          ),
          code: '''
LegendDropdown<String>(
  placeholder: 'Pick a fruit',
  value: fruit,
  items: const [
    LegendDropdownItem(value: 'apple', label: 'Apple'),
    LegendDropdownItem(value: 'banana', label: 'Banana'),
  ],
  onChanged: (value) => setState(() => fruit = value),
)''',
        ),
        DocSection(
          title: 'Checkbox',
          description:
              'An independent on/off choice on the shared selection-control '
              'base: real checkbox semantics (including the tristate mixed '
              'state), Enter/Space activation, and an inline label that is '
              'part of the tap target.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.sm,
            children: [
              LegendCheckbox(
                value: _backup,
                label: 'I have written down my recovery phrase',
                onChanged: (v) => setState(() => _backup = v ?? false),
              ),
              LegendCheckbox(
                value: _sources,
                tristate: true,
                label: 'Include all sources (tap to cycle tristate)',
                onChanged: (v) => setState(() => _sources = v),
              ),
              const LegendCheckbox(
                value: true,
                label: 'Disabled',
                onChanged: null,
              ),
            ],
          ),
          code: '''
LegendCheckbox(
  value: confirmed,
  label: 'I have written down my recovery phrase',
  onChanged: (v) => setState(() => confirmed = v ?? false),
)

LegendCheckbox(
  value: includeAll,          // bool? — null is the mixed middle
  tristate: true,
  label: 'Include all sources',
  onChanged: (v) => setState(() => includeAll = v),
)''',
        ),
        DocSection(
          title: 'Radio',
          description:
              'An exclusive one-of-N choice on the shared selection-control '
              'base: real radio semantics (checked, in a mutually exclusive '
              'group), a group scope that carries value and onChanged to '
              'every radio, arrow keys that move selection with roving '
              'focus, and Enter/Space to select — tapping the selected '
              'radio never deselects.',
          demo: LegendRadioGroup<String>(
            value: _plan,
            onChanged: (value) => setState(() => _plan = value),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.sizes.sm,
              children: const [
                LegendRadio(value: 'monthly', label: 'Monthly billing'),
                LegendRadio(value: 'yearly', label: 'Yearly billing'),
                LegendRadio(
                  value: 'lifetime',
                  label: 'Lifetime (disabled)',
                  enabled: false,
                ),
              ],
            ),
          ),
          code: '''
LegendRadioGroup<String>(
  value: plan,
  onChanged: (value) => setState(() => plan = value),
  child: Column(
    children: const [
      LegendRadio(value: 'monthly', label: 'Monthly billing'),
      LegendRadio(value: 'yearly', label: 'Yearly billing'),
    ],
  ),
)

// Standalone, without a group:
LegendRadio<String>(
  value: 'monthly',
  groupValue: plan,
  onChanged: (value) => setState(() => plan = value),
)''',
        ),
        const DocSection(
          title: 'LegendRadio theme surface',
          demo: PropsTable(
            rows: [
              (
                name: 'fill',
                type: 'InteractiveColors',
                defaultsTo: 't.colors.primary (+ overlays)',
              ),
              (
                name: 'dotColor',
                type: 'Color',
                defaultsTo: 't.colors.onPrimary',
              ),
              (
                name: 'borderColor',
                type: 'Color',
                defaultsTo: 't.colors.background3',
              ),
              (
                name: 'focusedBorderColor',
                type: 'Color',
                defaultsTo: 't.colors.primary',
              ),
              (name: 'size', type: 'double', defaultsTo: 't.sizes.iconMd'),
              (name: 'borderWidth', type: 'double', defaultsTo: '1.5'),
            ],
          ),
        ),
        DocSection(
          title: 'Switch',
          demo: Column(
            spacing: tokens.sizes.sm,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LegendText('Notifications'),
                  LegendSwitch(
                    value: _notifications,
                    semanticLabel: 'Notifications',
                    onChanged: (v) => setState(() => _notifications = v),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LegendText('Newsletter'),
                  LegendSwitch(
                    value: _newsletter,
                    semanticLabel: 'Newsletter',
                    onChanged: (v) => setState(() => _newsletter = v),
                  ),
                ],
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LegendText('Disabled'),
                  LegendSwitch(value: true, onChanged: null),
                ],
              ),
            ],
          ),
          code: '''
LegendSwitch(
  value: enabled,
  semanticLabel: 'Notifications',   // what the switch controls
  onChanged: (v) => setState(() => enabled = v),
)''',
        ),
        DocSection(
          title: 'Chip',
          description:
              'A compact labeled token in three modes, driven by the '
              'callbacks: onSelected makes a toggling filter chip '
              '(announced with selected state), onTap a plain action chip '
              '(a citation or suggested question), onDismissed adds a '
              'trailing remove affordance. Disabled chips are genuinely '
              'inert, the remove affordance included.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.sm,
            children: [
              Wrap(
                spacing: tokens.sizes.xs,
                runSpacing: tokens.sizes.xs,
                children: [
                  for (final network in const ['Ethereum', 'Polygon', 'Base'])
                    LegendChip(
                      label: network,
                      selected: _networks.contains(network),
                      onSelected: (value) => setState(() {
                        if (value) {
                          _networks.add(network);
                        } else {
                          _networks.remove(network);
                        }
                      }),
                    ),
                ],
              ),
              Wrap(
                spacing: tokens.sizes.xs,
                runSpacing: tokens.sizes.xs,
                children: [
                  for (final tag in _tags)
                    LegendChip(
                      label: tag,
                      dismissLabel: 'Remove $tag',
                      onDismissed: () =>
                          setState(() => _tags = [..._tags]..remove(tag)),
                    ),
                  if (_tags.length < 3)
                    LegendChip(
                      label: 'Restore',
                      onTap: () => setState(
                        () => _tags = ['Design', 'Engineering', 'Research'],
                      ),
                    ),
                ],
              ),
              Wrap(
                spacing: tokens.sizes.xs,
                runSpacing: tokens.sizes.xs,
                children: [
                  for (final citation in const ['1', '2', '3'])
                    LegendChip(label: citation, onTap: () {}),
                  const LegendChip(label: 'Static tag'),
                  const LegendChip(label: 'Disabled', enabled: false),
                ],
              ),
            ],
          ),
          code: '''
LegendChip(
  label: 'Ethereum',
  selected: selected,                      // filter chip
  onSelected: (v) => setState(() => selected = v),
)

LegendChip(
  label: 'Design',
  dismissLabel: 'Remove Design',           // what the ✕ announces
  onDismissed: () => removeTag('Design'),  // dismissible chip
)

LegendChip(label: '3', onTap: openCitation)  // compact action chip''',
        ),
        const DocSection(
          title: 'LegendChip theme surface',
          demo: PropsTable(
            rows: [
              (
                name: 'background',
                type: 'InteractiveColors',
                defaultsTo: 't.colors.background2 (+ overlays)',
              ),
              (
                name: 'selectedBackground',
                type: 'InteractiveColors',
                defaultsTo: 't.colors.primaryContainer (+ overlays)',
              ),
              (
                name: 'foreground',
                type: 'Color',
                defaultsTo: 't.colors.foreground1',
              ),
              (
                name: 'selectedForeground',
                type: 'Color',
                defaultsTo: 't.colors.onPrimaryContainer',
              ),
              (
                name: 'borderRadius',
                type: 'BorderRadius',
                defaultsTo: 'BorderRadius.circular(999)',
              ),
              (
                name: 'padding',
                type: 'EdgeInsetsGeometry',
                defaultsTo:
                    'EdgeInsets.symmetric(h: t.sizes.sm, v: t.sizes.xs)',
              ),
              (
                name: 'textStyle',
                type: 'TextStyle',
                defaultsTo: 't.typography.b3',
              ),
            ],
          ),
        ),
        const DocSection(
          title: 'LegendDropdown theme surface',
          demo: PropsTable(
            rows: [
              (
                name: 'menuBackground',
                type: 'Color',
                defaultsTo: 't.colors.surface',
              ),
              (
                name: 'menuBorderRadius',
                type: 'BorderRadius',
                defaultsTo: 't.sizes.borderRadiusMd',
              ),
              (
                name: 'menuShadows',
                type: 'List<BoxShadow>',
                defaultsTo: 't.shadows.medium',
              ),
              (name: 'menuMaxHeight', type: 'double', defaultsTo: '320.0'),
              (
                name: 'itemPadding',
                type: 'EdgeInsetsGeometry',
                defaultsTo:
                    'EdgeInsets.symmetric(h: t.sizes.md, v: t.sizes.sm)',
              ),
              (
                name: 'textStyle',
                type: 'TextStyle',
                defaultsTo: 't.typography.b2',
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Segmented',
          description:
              'An exclusive one-of-N choice as joined equal-width segments '
              'with a sliding thumb. Each segment announces selected-state '
              'semantics; arrow keys move focus between segments and '
              'Enter/Space selects — tapping the selected segment never '
              'deselects.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.sm,
            children: [
              LegendSegmented<String>(
                segments: const [
                  LegendSegment(value: '1h', label: '1H'),
                  LegendSegment(value: '1d', label: '1D'),
                  LegendSegment(value: '1w', label: '1W'),
                  LegendSegment(value: '1m', label: '1M'),
                  LegendSegment(value: '1y', label: '1Y'),
                ],
                value: _timeframe,
                onChanged: (value) => setState(() => _timeframe = value),
              ),
              LegendSegmented<String>(
                segments: const [
                  LegendSegment(value: 'crypto', label: 'Crypto'),
                  LegendSegment(value: 'fiat', label: 'Fiat'),
                ],
                value: _currency,
                onChanged: (value) => setState(() => _currency = value),
              ),
              LegendSegmented<String>(
                segments: const [
                  LegendSegment(value: 'crypto', label: 'Crypto'),
                  LegendSegment(value: 'fiat', label: 'Fiat'),
                ],
                value: _currency,
                enabled: false,
                onChanged: (_) {},
              ),
            ],
          ),
          code: '''
LegendSegmented<String>(
  segments: const [
    LegendSegment(value: '1h', label: '1H'),
    LegendSegment(value: '1d', label: '1D'),
    LegendSegment(value: '1w', label: '1W'),
  ],
  value: timeframe,
  onChanged: (value) => setState(() => timeframe = value),
)''',
        ),
        const DocSection(
          title: 'LegendSegmented theme surface',
          demo: PropsTable(
            rows: [
              (
                name: 'background',
                type: 'Color',
                defaultsTo: 't.colors.background2',
              ),
              (
                name: 'thumb',
                type: 'InteractiveColors',
                defaultsTo: 'normal: t.colors.surface',
              ),
              (
                name: 'labelStyle',
                type: 'TextStyle',
                defaultsTo: 't.typography.b3 in foreground2',
              ),
              (
                name: 'selectedLabelStyle',
                type: 'TextStyle',
                defaultsTo: 't.typography.b3 w600 in foreground1',
              ),
              (
                name: 'borderRadius',
                type: 'BorderRadius',
                defaultsTo: 't.sizes.borderRadiusMd',
              ),
              (
                name: 'padding',
                type: 'EdgeInsetsGeometry',
                defaultsTo: 'EdgeInsets.all(t.sizes.xs)',
              ),
              (
                name: 'segmentPadding',
                type: 'EdgeInsetsGeometry',
                defaultsTo:
                    'EdgeInsets.symmetric(h: t.sizes.sm, v: t.sizes.xs)',
              ),
            ],
          ),
        ),
        const ThemeSurfaceSection(component: LegendCheckbox),
        const ThemeSurfaceSection(component: LegendSwitch),
      ],
    );
  }
}
