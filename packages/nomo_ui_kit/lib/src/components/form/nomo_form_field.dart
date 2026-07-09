import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/components/form/nomo_form.dart';

/// Gives **consumer-built inputs** the same form support kit fields get
/// (consumer symmetry, DESIGN.md §1.4): registration on mount,
/// unregistration on dispose, value reporting, validation, and the
/// "validate on submit, revalidate on change" error lifecycle.
///
/// The [builder] receives the field's [NomoFormFieldState]; the consumer
/// renders whatever input they like, calls
/// [NomoFormFieldState.didChange] on edits, and displays
/// [NomoFormFieldState.error]:
///
/// ```dart
/// NomoFormField<bool>(
///   name: 'terms',
///   initialValue: false,
///   validator: (v) => (v ?? false) ? null : 'Please accept the terms.',
///   builder: (context, field) => NomoSwitch(
///     value: field.value ?? false,
///     onChanged: field.didChange,
///   ),
/// )
/// ```
class NomoFormField<T> extends StatefulWidget {
  const NomoFormField({
    required this.name,
    required this.builder,
    super.key,
    this.initialValue,
    this.validator,
  });

  /// The key under which this field's value appears in
  /// [NomoFormController.values].
  final String name;

  /// The value the field starts with and returns to on
  /// [NomoFormController.reset].
  final T? initialValue;

  /// Returns `null` when [T] is valid, an error message otherwise.
  /// A field without a validator is always valid.
  final String? Function(T? value)? validator;

  /// Builds the input UI from the field's current state.
  final Widget Function(BuildContext context, NomoFormFieldState<T> field)
  builder;

  @override
  NomoFormFieldState<T> createState() => NomoFormFieldState<T>();
}

/// The state handed to [NomoFormField.builder] — current [value], displayed
/// [error], and [didChange] to report edits.
class NomoFormFieldState<T> extends State<NomoFormField<T>>
    implements NomoFormFieldHandle {
  NomoFormController? _form;
  T? _value;
  String? _error;

  /// The field's current value.
  @override
  T? get value => _value;

  /// The validation error to display, or null. Set by the enclosing form on
  /// `validate()` and, after the first validate, on every value change.
  String? get error => _error;

  @override
  String get name => widget.name;

  /// Reports a new value. Call this from the input's change callback.
  void didChange(T? value) {
    if (_value == value) return;
    setState(() => _value = value);
    _form?.didChangeField(this);
  }

  @override
  String? runValidator() => widget.validator?.call(_value);

  @override
  void showError(String? error) {
    if (_error == error || !mounted) return;
    setState(() => _error = error);
  }

  @override
  void resetField() {
    if (!mounted) return;
    setState(() {
      _value = widget.initialValue;
      _error = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final form = NomoForm.maybeOf(context);
    if (form != _form) {
      _form?.unregister(this);
      _form = form;
      _form?.register(this);
    }
  }

  @override
  void didUpdateWidget(NomoFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      // Drop the entry under the old name, re-register under the new one.
      _form
        ?..unregister(this)
        ..register(this);
    }
  }

  @override
  void dispose() {
    _form?.unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, this);
}
