import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class SelectionSection extends StatefulWidget {
  const SelectionSection({super.key});

  @override
  State<SelectionSection> createState() => _SelectionSectionState();
}

class _SelectionSectionState extends State<SelectionSection> {
  String? _fruit;
  var _notifications = true;
  var _newsletter = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        DemoGroup(
          title: 'Dropdown',
          children: [
            LegendDropdown<String>(
              placeholder: 'Pick a fruit',
              value: _fruit,
              items: const [
                LegendDropdownItem(value: 'apple', label: 'Apple'),
                LegendDropdownItem(value: 'banana', label: 'Banana'),
                LegendDropdownItem(value: 'cherry', label: 'Cherry'),
              ],
              onChanged: (value) => setState(() => _fruit = value),
            ),
          ],
        ),
        DemoGroup(
          title: 'Switches',
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const LegendText('Notifications'),
                LegendSwitch(
                  value: _notifications,
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
      ],
    );
  }
}
