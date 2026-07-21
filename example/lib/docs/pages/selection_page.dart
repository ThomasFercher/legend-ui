import 'package:example/docs/doc_page.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class SelectionPage extends StatefulWidget {
  const SelectionPage({super.key});

  @override
  State<SelectionPage> createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  String? _fruit;
  var _notifications = true;
  var _newsletter = false;
  final _networks = {'Ethereum'};
  var _tags = ['Design', 'Engineering', 'Research'];

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return DocPage(
      title: 'Selection',
      intro:
          'One dropdown with one item model, and a switch that is honest to '
          'assistive tech: it announces as a toggle with its state, never as '
          'a button, and mirrors correctly under right-to-left layouts.',
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
      ],
    );
  }
}
