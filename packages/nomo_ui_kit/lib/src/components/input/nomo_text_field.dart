import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
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
  final String? errorText;

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

class _NomoTextFieldState extends State<NomoTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onStateChange);
    _controller.addListener(_onStateChange);
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
  }

  void _onStateChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onStateChange);
    _controller.removeListener(_onStateChange);
    _ownFocusNode?.dispose();
    _ownController?.dispose();
    super.dispose();
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
    final hasError = widget.errorText != null;
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
            widget.errorText!,
            style: tokens.typography.b3.copyWith(color: tokens.colors.error),
          ),
      ],
    );
  }
}
