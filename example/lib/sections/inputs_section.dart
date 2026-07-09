import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

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
            const NomoTextField(title: 'Name', placeholder: 'Jane Doe'),
            NomoTextField(
              title: 'Email',
              placeholder: 'jane@example.com',
              errorText: _emailError,
              onChanged: (value) => setState(
                () => _emailError = value.isEmpty || value.contains('@')
                    ? null
                    : 'Not a valid email address',
              ),
            ),
            const NomoTextField(
              title: 'Password',
              placeholder: '••••••••',
              obscureText: true,
            ),
            const NomoTextField(
              title: 'Disabled',
              placeholder: 'Read only',
              enabled: false,
            ),
            const NomoTextField(
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
