import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

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
            NomoDropdown<String>(
              placeholder: 'Pick a fruit',
              value: _fruit,
              items: const [
                NomoDropdownItem(value: 'apple', label: 'Apple'),
                NomoDropdownItem(value: 'banana', label: 'Banana'),
                NomoDropdownItem(value: 'cherry', label: 'Cherry'),
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
                const NomoText('Notifications'),
                NomoSwitch(
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const NomoText('Newsletter'),
                NomoSwitch(
                  value: _newsletter,
                  onChanged: (v) => setState(() => _newsletter = v),
                ),
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NomoText('Disabled'),
                NomoSwitch(value: true, onChanged: null),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
