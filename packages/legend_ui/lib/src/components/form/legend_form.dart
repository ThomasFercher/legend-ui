import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The contract a field implements to participate in a [LegendForm].
///
/// Kit fields (`LegendTextField` via `formField`) and consumer fields (via
/// `LegendFormField`) implement this; fully custom widgets may too. A handle
/// registers on mount and **must unregister on dispose** — the controller
/// never holds on to dead fields (legacy bug: fields never unregistered,
/// see legacy-docs 01 §4.2).
abstract class LegendFormFieldHandle {
  /// The name this field's value is stored under in
  /// [LegendFormController.values].
  String get name;

  /// The field's current value.
  Object? get value;

  /// Runs the field's validator against the current value.
  ///
  /// Returns `null` when valid. Fields **without a validator always return
  /// `null`** — a validator-less field can never pin the form invalid
  /// (legacy bug regression).
  String? runValidator();

  /// Instructs the field to display (or clear, with `null`) a validation
  /// error. Called by the controller on [LegendFormController.validate],
  /// on value changes after the first validate, and on
  /// [LegendFormController.reset].
  void showError(String? error);

  /// Restores the field to its initial value and clears its error.
  void resetField();
}

/// Owns a [LegendForm]'s field registry and validity model.
///
/// Fields register on mount and unregister on dispose; [values], [isValid]
/// and [validate] always reflect exactly the fields currently in the tree.
///
/// Validation UX is "validate on submit, revalidate on change": errors are
/// only displayed once [validate] has been called, after which every value
/// change re-runs that field's validator. [isValid] is live from the start,
/// independent of error display.
class LegendFormController {
  final Map<String, LegendFormFieldHandle> _fields = {};
  final ValueNotifier<bool> _isValid = ValueNotifier(true);

  bool _validateOnChange = false;
  bool _recomputeScheduled = false;
  bool _disposed = false;

  /// Whether every registered field's validator currently passes.
  ///
  /// Updates live as fields register, unregister and change value.
  /// Validator-less fields count as always valid; an empty form is valid.
  ValueListenable<bool> get isValid => _isValid;

  /// Snapshot of the current values of all registered fields, keyed by
  /// field name.
  Map<String, Object?> get values => {
    for (final field in _fields.values) field.name: field.value,
  };

  /// Runs every field's validator, displays the resulting errors on the
  /// fields, and returns whether the whole form is valid.
  ///
  /// From the first call on, fields revalidate (and update their displayed
  /// error) on every value change.
  bool validate() {
    _validateOnChange = true;
    var valid = true;
    for (final field in _fields.values) {
      final error = field.runValidator();
      field.showError(error);
      valid = valid && error == null;
    }
    _isValid.value = valid;
    return valid;
  }

  /// Resets every field to its initial value, clears all displayed errors,
  /// and rearms the "errors only after validate" behavior.
  void reset() {
    _validateOnChange = false;
    for (final field in _fields.values) {
      field
        ..resetField()
        ..showError(null);
    }
    _recomputeValidity();
  }

  /// Called by fields when they mount inside the form.
  void register(LegendFormFieldHandle field) {
    _fields[field.name] = field;
    _scheduleRecomputeValidity();
  }

  /// Called by fields when they leave the tree (or re-register under a new
  /// name).
  ///
  /// Removes by identity, not by name: a replacement field may register
  /// under the same name before the old one is disposed, and the late
  /// unregister must not evict it.
  void unregister(LegendFormFieldHandle field) {
    _fields.removeWhere((_, registered) => identical(registered, field));
    _scheduleRecomputeValidity();
  }

  /// Called by fields whenever their value changes.
  void didChangeField(LegendFormFieldHandle field) {
    if (_validateOnChange) {
      field.showError(field.runValidator());
    }
    _recomputeValidity();
  }

  /// Register/unregister happen during build, where notifying [isValid]
  /// listeners synchronously could mark widgets dirty mid-build — so the
  /// recompute is deferred to a microtask (coalesced).
  void _scheduleRecomputeValidity() {
    if (_recomputeScheduled) return;
    _recomputeScheduled = true;
    scheduleMicrotask(() {
      _recomputeScheduled = false;
      if (!_disposed) _recomputeValidity();
    });
  }

  void _recomputeValidity() {
    _isValid.value = _fields.values.every(
      (field) => field.runValidator() == null,
    );
  }

  void dispose() {
    _disposed = true;
    _isValid.dispose();
  }
}

/// Scopes a [LegendFormController] to a subtree.
///
/// Descendant fields find the controller via [LegendForm.maybeOf] and manage
/// their own registration lifecycle. Pass a [controller] to drive the form
/// from outside (submit buttons, programmatic reset); otherwise the form
/// owns one internally.
class LegendForm extends StatefulWidget {
  const LegendForm({required this.child, this.controller, super.key});

  /// External controller; the form creates (and disposes) its own if null.
  final LegendFormController? controller;

  final Widget child;

  /// The nearest enclosing form's controller, or null when not in a form.
  static LegendFormController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_LegendFormScope>()
        ?.controller;
  }

  /// The nearest enclosing form's controller.
  static LegendFormController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No LegendForm found in context.');
    return controller!;
  }

  @override
  State<LegendForm> createState() => _LegendFormState();
}

class _LegendFormState extends State<LegendForm> {
  LegendFormController? _ownController;

  LegendFormController get _controller =>
      widget.controller ?? (_ownController ??= LegendFormController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LegendFormScope(controller: _controller, child: widget.child);
  }
}

class _LegendFormScope extends InheritedWidget {
  const _LegendFormScope({required this.controller, required super.child});

  final LegendFormController controller;

  @override
  bool updateShouldNotify(_LegendFormScope oldWidget) =>
      controller != oldWidget.controller;
}
