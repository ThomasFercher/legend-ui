import 'package:example/docs/doc_page.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class InputsPage extends StatefulWidget {
  const InputsPage({super.key});

  @override
  State<InputsPage> createState() => _InputsPageState();
}

class _InputsPageState extends State<InputsPage> {
  static const _tokens = [
    LegendComboboxItem(value: 'eth', label: 'Ethereum'),
    LegendComboboxItem(value: 'btc', label: 'Bitcoin'),
    LegendComboboxItem(value: 'sol', label: 'Solana'),
    LegendComboboxItem(value: 'ada', label: 'Cardano'),
    LegendComboboxItem(value: 'dot', label: 'Polkadot'),
    LegendComboboxItem(value: 'avax', label: 'Avalanche'),
  ];

  String? _emailError;
  String? _token;
  final _form = LegendFormController();
  var _submitted = '—';

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return DocPage(
      title: 'Inputs & forms',
      intro:
          'LegendTextField is built directly on EditableText — no '
          'CupertinoTextField fork. Fields participate in a LegendForm by '
          'name: they register on mount, unregister on dispose, and the '
          "form's validity updates live as you type.",
      children: [
        DocSection(
          title: 'Text fields',
          demo: Column(
            spacing: tokens.sizes.sm,
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
          code: '''
LegendTextField(
  title: 'Email',
  placeholder: 'jane@example.com',
  errorText: _error,          // shown below the field
  onChanged: validate,
)''',
        ),
        DocSection(
          title: 'Combobox (typeahead)',
          description:
              'LegendCombobox is the searchable sibling of LegendDropdown: '
              'an editable field whose option panel filters as you type. '
              'Up/Down move the highlight, Enter commits it, Escape closes; '
              'losing focus without a selection reverts the text.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.sm,
            children: [
              LegendCombobox<String>(
                items: _tokens,
                value: _token,
                placeholder: 'Search a token…',
                onChanged: (value) => setState(() => _token = value),
              ),
              LegendText(
                'Selected: ${_token ?? '—'}',
                variant: LegendTextVariant.b3,
              ),
            ],
          ),
          code: '''
LegendCombobox<String>(
  items: const [
    LegendComboboxItem(value: 'eth', label: 'Ethereum'),
    LegendComboboxItem(value: 'btc', label: 'Bitcoin'),
  ],
  value: _token,
  placeholder: 'Search a token…',
  // Default: case-insensitive substring on the label.
  filter: (item, query) => item.label.startsWith(query),
  onChanged: (value) => setState(() => _token = value),
)''',
        ),
        DocSection(
          title: 'Forms and validators',
          description:
              'The submit button listens to controller.isValid. Stock '
              'validators cover the common cases and compose; custom ones '
              'are plain String? Function(String?).',
          demo: LegendForm(
            controller: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.sizes.sm,
              children: [
                LegendTextField(
                  title: 'Username',
                  placeholder: 'At least 3 characters',
                  formField: 'username',
                  validator: LegendValidator.compose([
                    LegendValidator.required,
                    LegendValidator.minLength(3),
                  ]),
                ),
                const LegendTextField(
                  title: 'Email',
                  placeholder: 'you@example.com',
                  formField: 'email',
                  validator: LegendValidator.email,
                ),
                Wrap(
                  spacing: tokens.sizes.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: _form.isValid,
                      builder: (context, valid, _) => PrimaryLegendButton(
                        text: 'Submit',
                        enabled: valid,
                        onPressed: () => setState(
                          () => _submitted = _form.values.toString(),
                        ),
                      ),
                    ),
                    LegendTextButton(text: 'Reset', onPressed: _form.reset),
                    LegendText(
                      'Submitted: $_submitted',
                      variant: LegendTextVariant.b3,
                    ),
                  ],
                ),
              ],
            ),
          ),
          code: '''
LegendForm(
  controller: form,
  child: Column(children: [
    LegendTextField(
      formField: 'username',
      validator: LegendValidator.compose([
        LegendValidator.required,
        LegendValidator.minLength(3),
      ]),
    ),
    ValueListenableBuilder(
      valueListenable: form.isValid,
      builder: (_, valid, _) =>
          PrimaryLegendButton(text: 'Submit', enabled: valid, ...),
    ),
  ]),
)''',
        ),
        const DocSection(
          title: 'Custom inputs join the same form',
          description:
              'LegendFormField<T> gives any widget — yours included — the '
              'same register/validate/reset lifecycle as kit fields.',
          code: '''
LegendFormField<bool>(
  name: 'terms',
  initialValue: false,
  validator: (accepted) =>
      accepted == true ? null : 'You must accept the terms',
  builder: (context, state) => LegendSwitch(
    value: state.value ?? false,
    onChanged: state.didChange,
  ),
)''',
        ),
      ],
    );
  }
}
