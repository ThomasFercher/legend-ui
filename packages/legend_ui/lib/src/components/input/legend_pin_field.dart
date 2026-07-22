import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_field_core.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'legend_pin_field.theme.g.dart';

/// A fixed-length code entry (unlock PIN / 2FA): ONE hidden text field
/// drives [length] painted character cells — tapping anywhere focuses the
/// single field, typing fills the cells left to right, backspace clears
/// backwards, and pasting a full code fills every cell at once.
///
/// Composes [LegendFieldCore] (the one real editing/focus/IME surface —
/// never N separate fields, so cross-field focus-hop bugs cannot exist)
/// and [LegendSurface] (each cell's fill, border, and rounding).
///
/// Assistive tech sees a single text-field node labeled like
/// "PIN, 3 of 6 digits entered" — the painted cells are pure paint and
/// excluded from semantics.
@LegendThemeable()
class LegendPinField extends StatefulWidget {
  const LegendPinField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.obscure = false,
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
    this.enabled = true,
    this.errorText,
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel = 'PIN',
    this.cellSize,
    this.cellSpacing,
    this.cellBackground,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.textStyle,
    this.borderRadius,
  }) : assert(length > 0, 'length must be positive');

  /// How many characters the code has (and how many cells render).
  final int length;

  /// Called with the entered text on every edit.
  final ValueChanged<String>? onChanged;

  /// Called with the full code the moment the last cell fills — typing the
  /// final character or pasting a complete code.
  final ValueChanged<String>? onCompleted;

  /// Renders entered characters as dots (unlock PIN) instead of visible
  /// text (2FA code).
  final bool obscure;

  /// Software keyboard to summon; numeric by default.
  final TextInputType keyboardType;

  /// Input filter; digits-only by default. The [length] cap always applies
  /// on top.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field accepts input; false renders inert, dimmed cells.
  final bool enabled;

  /// Non-null switches the cells into their error border and shows this
  /// message inline below the cells.
  final String? errorText;

  /// Whether the field focuses itself when first built.
  final bool autofocus;

  /// The field's focus; null lets the widget own one internally.
  final FocusNode? focusNode;

  /// What the code is called in the assistive-tech label
  /// ("PIN, 3 of 6 digits entered").
  final String semanticLabel;

  /// Width and height of one character cell.
  @Style<Size>.resolve(_cellSize)
  final Size? cellSize;

  /// Gap between adjacent cells.
  @Style<double>.resolve(SizeRef.sm)
  final double? cellSpacing;

  /// Fill of each cell.
  @Style<Color>.resolve(ColorRef.background1)
  final Color? cellBackground;

  /// Cell border while inactive.
  @Style<Color>.resolve(ColorRef.background3)
  final Color? borderColor;

  /// Border of the active cell (the one the next character lands in) while
  /// the field is focused.
  @Style<Color>.resolve(ColorRef.primary)
  final Color? focusedBorderColor;

  /// Cell border while [errorText] is set.
  @Style<Color>.resolve(ColorRef.error)
  final Color? errorBorderColor;

  /// Style of the entered characters (recolored to the foreground).
  @Style<TextStyle>.resolve(TextRef.h3)
  final TextStyle? textStyle;

  /// Corner rounding of each cell.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  @override
  State<LegendPinField> createState() => _LegendPinFieldState();
}

class _LegendPinFieldState extends State<LegendPinField> {
  final _controller = TextEditingController();
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onStateChange);
    // Cell contents and the active highlight track the text.
    _controller.addListener(_onStateChange);
  }

  @override
  void didUpdateWidget(LegendPinField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      // The own instance is stable; only external swaps need re-listening.
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onStateChange);
      _focusNode.addListener(_onStateChange);
    }
    // A shrunk length drops the characters that no longer have a cell.
    if (widget.length < _controller.text.length) {
      _controller.text = _controller.text.substring(0, widget.length);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onStateChange);
    _controller
      ..removeListener(_onStateChange)
      ..dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onStateChange() => setState(() {});

  void _onUserEdit(String text) {
    widget.onChanged?.call(text);
    if (text.length == widget.length) widget.onCompleted?.call(text);
  }

  /// The cell the next character lands in; the last cell once the code is
  /// full, none while unfocused.
  int get _activeIndex {
    if (!_focusNode.hasFocus) return -1;
    final entered = _controller.text.length;
    return entered >= widget.length ? widget.length - 1 : entered;
  }

  Widget _cell(
    int index,
    LegendPinFieldTheme theme,
    LegendTokens tokens, {
    required bool hasError,
  }) {
    final text = _controller.text;
    final borderColor = hasError
        ? theme.errorBorderColor
        : index == _activeIndex
        ? theme.focusedBorderColor
        : theme.borderColor;
    final foreground = widget.enabled
        ? tokens.colors.foreground1
        : tokens.colors.onDisabled;

    final Widget? content;
    if (index >= text.length) {
      content = null;
    } else if (widget.obscure) {
      content = SizedBox(
        width: tokens.sizes.sm,
        height: tokens.sizes.sm,
        child: DecoratedBox(
          decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
        ),
      );
    } else {
      content = Text(
        text[index],
        style: theme.textStyle.copyWith(color: foreground),
      );
    }

    return LegendSurface(
      color: widget.enabled ? theme.cellBackground : tokens.colors.disabled,
      borderRadius: theme.borderRadius,
      border: Border.all(color: borderColor, width: tokens.sizes.borderWidth),
      duration: const Duration(milliseconds: 120),
      child: SizedBox(
        width: theme.cellSize.width,
        height: theme.cellSize.height,
        child: Center(child: content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final hasError = widget.errorText != null;
    const transparent = Color(0x00000000);

    final field = Semantics(
      container: true,
      textField: true,
      enabled: widget.enabled,
      focused: _focusNode.hasFocus,
      label:
          '${widget.semanticLabel}, ${_controller.text.length} of '
          '${widget.length} digits entered',
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      // One text-field node for the whole widget: the cells are pure paint
      // and the hidden core would only add a second, empty-looking field.
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _focusNode.requestFocus : null,
          child: Stack(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: theme.cellSpacing,
                children: [
                  for (var i = 0; i < widget.length; i++)
                    _cell(i, theme, tokens, hasError: hasError),
                ],
              ),
              // The one real text field: 1×1 and fully transparent — it
              // owns focus, IME, and the edited string.
              Positioned(
                left: 0,
                top: 0,
                width: 1,
                height: 1,
                child: LegendFieldCore(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(color: transparent),
                  cursorColor: transparent,
                  backgroundCursorColor: transparent,
                  selectionColor: transparent,
                  readOnly: !widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: widget.keyboardType,
                  inputFormatters: [
                    ...widget.inputFormatters ??
                        [FilteringTextInputFormatter.digitsOnly],
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  onChanged: _onUserEdit,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!hasError) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.sizes.xs,
      children: [
        field,
        Text(
          widget.errorText!,
          style: tokens.typography.b3.copyWith(color: tokens.colors.error),
        ),
      ],
    );
  }
}

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

Size _cellSize(LegendTokens t) => Size(t.sizes.xl + t.sizes.sm, t.sizes.xxl);
