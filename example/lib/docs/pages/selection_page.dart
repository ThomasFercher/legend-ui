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
