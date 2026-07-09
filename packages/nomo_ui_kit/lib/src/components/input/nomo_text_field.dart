import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/form/nomo_form.dart';
import 'package:nomo_ui_kit/src/components/input/nomo_text_field.theme.g.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';

/// The field core (DESIGN.md §3): a thin composition over Flutter's
/// `EditableText` — replacing legacy's 1,535-line CupertinoTextField fork.
///
/// MVP scope: single/multi-line text, placeholder, title, error state,
/// focus border. Selection toolbar/handles land in a later phase.
@NomoThemeable()
class NomoTextField extends StatefulWidget {
  const NomoTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.title,
    this.placeholder,
    this.errorText,
    this.formField,
    this.validator,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.background,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.borderColor,
    this.focusedBorderColor,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? title;
  final String? placeholder;

  /// Non-null switches the field into its error state.
  ///
  /// Inside a [NomoForm] this is merged with the form's validation error;
  /// an explicit [errorText] wins.
  final String? errorText;

  /// Registers this field in the enclosing [NomoForm] under this name:
  /// its text appears in [NomoFormController.values], [validator] runs on
  /// `validate()` (and on change thereafter), and the resulting error is
  /// displayed automatically. Without an enclosing form, or with a null
  /// name, the field is form-inert.
  final String? formField;

  /// Returns `null` when the text is valid, an error message otherwise
  /// (see `NomoValidator` for stock validators). Only consulted inside a
  /// [NomoForm] with a [formField] name; a field without a validator is
  /// always valid.
  final String? Function(String? value)? validator;

  final bool enabled;
  final bool obscureText;
  final bool autofocus;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @Themed(defaultsTo: 't.colors.background1')
  final Color? background;

  @Themed(defaultsTo: 't.sizes.borderRadiusMd')
  final BorderRadius? borderRadius;

  @Themed(
    defaultsTo:
        'EdgeInsets.symmetric(horizontal: t.sizes.md, '
        'vertical: t.sizes.sm)',
  )
  final EdgeInsetsGeometry? padding;

  @Themed(defaultsTo: 't.typography.b1')
  final TextStyle? textStyle;

  @Themed(defaultsTo: 't.colors.background3')
  final Color? borderColor;

  @Themed(defaultsTo: 't.colors.primary')
  final Color? focusedBorderColor;

  @override
  State<NomoTextField> createState() => _NomoTextFieldState();
}

class _NomoTextFieldState extends State<NomoTextField>
    implements NomoFormFieldHandle {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;

  NomoFormController? _form;
  String? _formError;
  late String _lastReportedText;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onStateChange);
    _controller.addListener(_onStateChange);
    _lastReportedText = _controller.text;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFormRegistration();
  }

  @override
  void didUpdateWidget(NomoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode ||
        oldWidget.controller != widget.controller) {
      // Own instances are stable; only external swaps need re-listening.
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onStateChange);
      (oldWidget.controller ?? _ownController)?.removeListener(_onStateChange);
      _focusNode.addListener(_onStateChange);
      _controller.addListener(_onStateChange);
    }
    if (oldWidget.formField != widget.formField) _syncFormRegistration();
  }

  void _onStateChange() {
    setState(() {});
    if (_controller.text != _lastReportedText) {
      _lastReportedText = _controller.text;
      if (widget.formField != null) _form?.didChangeField(this);
    }
  }

  @override
  void dispose() {
    _form?.unregister(this);
    _focusNode.removeListener(_onStateChange);
    _controller.removeListener(_onStateChange);
    _ownFocusNode?.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  // --- NomoFormFieldHandle (active when `formField` names this field) ---

  void _syncFormRegistration() {
    final form = widget.formField == null ? null : NomoForm.maybeOf(context);
    if (form != _form || widget.formField != null) {
      _form?.unregister(this);
      _form = form;
      _form?.register(this);
    }
    if (_form == null) _formError = null;
  }

  @override
  String get name => widget.formField!;

  @override
  String? get value => _controller.text;

  @override
  String? runValidator() => widget.validator?.call(_controller.text);

  @override
  void showError(String? error) {
    if (_formError == error || !mounted) return;
    setState(() => _formError = error);
  }

  @override
  void resetField() {
    // clear() may not notify (the text can already be empty), so the error
    // is cleared inside an explicit setState.
    _controller.clear();
    if (mounted) setState(() => _formError = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = NomoTextFieldTheme.of(
      context,
      NomoTextFieldThemeNullable(
        background: widget.background,
        borderRadius: widget.borderRadius,
        padding: widget.padding,
        textStyle: widget.textStyle,
        borderColor: widget.borderColor,
        focusedBorderColor: widget.focusedBorderColor,
      ),
    );
    final tokens = NomoTheme.of(context).tokens;
    // Explicit errorText wins over the form's validation error.
    final errorText = widget.errorText ?? _formError;
    final hasError = errorText != null;
    final focused = _focusNode.hasFocus;

    final borderColor = hasError
        ? tokens.colors.error
        : focused
        ? theme.focusedBorderColor
        : theme.borderColor;

    final field = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      child: NomoSurface(
        color: widget.enabled ? theme.background : tokens.colors.disabled,
        borderRadius: theme.borderRadius,
        border: Border.all(color: borderColor, width: tokens.sizes.borderWidth),
        padding: theme.padding,
        duration: const Duration(milliseconds: 120),
        child: Stack(
          children: [
            if (_controller.text.isEmpty && widget.placeholder != null)
              ExcludeSemantics(
                child: Text(
                  widget.placeholder!,
                  style: theme.textStyle.copyWith(
                    color: tokens.colors.foreground3,
                  ),
                ),
              ),
            EditableText(
              controller: _controller,
              focusNode: _focusNode,
              style: theme.textStyle.copyWith(
                color: widget.enabled
                    ? tokens.colors.foreground1
                    : tokens.colors.onDisabled,
              ),
              cursorColor: theme.focusedBorderColor,
              backgroundCursorColor: theme.borderColor,
              selectionColor: theme.focusedBorderColor.withValues(alpha: 0.3),
              obscureText: widget.obscureText,
              autofocus: widget.autofocus,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              readOnly: !widget.enabled,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.sizes.xs,
      children: [
        if (widget.title != null)
          Text(
            widget.title!,
            style: tokens.typography.b3.copyWith(
              color: tokens.colors.foreground2,
            ),
          ),
        field,
        if (hasError)
          Text(
            errorText,
            style: tokens.typography.b3.copyWith(color: tokens.colors.error),
          ),
      ],
    );
  }
}
