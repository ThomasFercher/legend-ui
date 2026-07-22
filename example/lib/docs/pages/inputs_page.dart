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
  double? _amount = 1.5;
  double? _slippage = 0.5;
  var _volume = 0.4;
  var _quality = 50.0;

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
          title: 'Number fields',
          description:
              'LegendNumberField filters typing to a decimal pattern, clamps '
              'to min/max on commit (blur or Enter), and steps via the '
              'trailing buttons (press-and-hold repeats) or the up/down '
              'arrow keys. The steppers disable at the bounds.',
          demo: Column(
            spacing: tokens.sizes.sm,
            children: [
              LegendNumberField(
                title: 'Amount (0 – 100, step 0.5)',
                value: _amount,
                min: 0,
                max: 100,
                step: 0.5,
                placeholder: '0',
                onChanged: (value) => setState(() => _amount = value),
              ),
              LegendNumberField(
                title: 'Slippage % (2 decimals)',
                value: _slippage,
                min: 0,
                max: 5,
                step: 0.1,
                decimals: 2,
                onChanged: (value) => setState(() => _slippage = value),
              ),
              const LegendNumberField(
                title: 'Disabled',
                value: 42,
                enabled: false,
              ),
              LegendText(
                'Amount: ${_amount ?? '—'} · Slippage: ${_slippage ?? '—'}',
                variant: LegendTextVariant.b3,
              ),
            ],
          ),
          code: '''
LegendNumberField(
  value: amount,
  min: 0,
  max: 100,
  step: 0.5,
  decimals: 2,              // typing and formatting precision
  onChanged: (value) => setState(() => amount = value),
)''',
        ),
        DocSection(
          title: 'Slider',
          description:
              'A draggable value selector — drag the thumb or tap the '
              'track; arrow keys step the value while focused (one '
              'division when snapping, 5% of the range otherwise) and '
              'Home/End jump to the ends. Announced to assistive tech as '
              'a real slider with increase/decrease actions, never as a '
              'button.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.sm,
            children: [
              LegendText(
                'Volume — ${(_volume * 100).round()}%',
                variant: LegendTextVariant.b3,
              ),
              LegendSlider(
                value: _volume,
                semanticLabel: 'Volume',
                onChanged: (v) => setState(() => _volume = v),
              ),
              LegendText(
                'Quality — ${_quality.round()} (10 steps)',
                variant: LegendTextVariant.b3,
              ),
              LegendSlider(
                value: _quality,
                max: 100,
                divisions: 10,
                semanticLabel: 'Quality',
                semanticFormatter: (v) => '${v.round()} of 100',
                onChanged: (v) => setState(() => _quality = v),
              ),
              const LegendText('Disabled', variant: LegendTextVariant.b3),
              const LegendSlider(value: 0.3, onChanged: null),
            ],
          ),
          code: r'''
LegendSlider(
  value: volume,              // 0..1 by default
  semanticLabel: 'Volume',
  onChanged: (v) => setState(() => volume = v),
)

LegendSlider(
  value: quality,
  max: 100,
  divisions: 10,              // snaps every delivered value
  semanticFormatter: (v) => '${v.round()} of 100',
  onChanged: (v) => setState(() => quality = v),
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
