import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class InputsSection extends StatefulWidget {
  const InputsSection({super.key});

  @override
  State<InputsSection> createState() => _InputsSectionState();
}

class _InputsSectionState extends State<InputsSection> {
  String? _emailError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        DemoGroup(
          title: 'Text fields',
          children: [
            const LegendTextField(title: 'Name', placeholder: 'Jane Doe'),
            LegendTextField(
              title: 'Email',
              placeholder: 'jane@example.com',
              errorText: _emailError,
              onChanged: (value) => setState(
                () => _emailError = value.isEmpty || value.contains('@')
                    ? null
                    : 'Not a valid email address',
              ),
            ),
            const LegendTextField(
              title: 'Password',
              placeholder: '••••••••',
              obscureText: true,
            ),
            const LegendTextField(
              title: 'Disabled',
              placeholder: 'Read only',
              enabled: false,
            ),
            const LegendTextField(
              title: 'Notes (multiline)',
              placeholder: 'Write something…',
              maxLines: 4,
            ),
          ],
        ),
      ],
    );
  }
}
