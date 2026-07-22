import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_caret.dart';
import 'package:legend_ui/src/primitives/legend_field_core.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'legend_number_field.theme.g.dart';

/// A numeric input with increment/decrement steppers: typing is filtered to
/// a simple decimal pattern, on commit (blur or Enter) the value clamps to
/// [min]/[max] and reformats, and the trailing stepper pair — with
/// press-and-hold repeat and up/down arrow-key stepping — walks the value
/// in [step]s.
///
/// Composes [LegendFieldCore] (text editing/focus/cursor), [LegendSurface]
/// (the field's fill, border, and rounding), and [LegendInteractive] (the
/// stepper buttons, announced as 'Increase'/'Decrease').
///
/// The steppers disable at the bounds, and a disabled stepper is genuinely
/// inert (no tap, no hold-repeat, no keyboard activation) — the field
/// itself carries its current text as the semantic value.
@LegendThemeable()
class LegendNumberField extends StatefulWidget {
  const LegendNumberField({
    super.key,
    this.value,
    this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.decimals,
    this.title,
    this.placeholder,
    this.enabled = true,
    this.focusNode,
    this.increaseLabel = 'Increase',
    this.decreaseLabel = 'Decrease',
    this.background,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.borderColor,
    this.focusedBorderColor,
    this.stepperColors,
    this.stepperForeground,
    this.stepperWidth,
  }) : assert(step > 0, 'step must be positive'),
       assert(
         min == null || max == null || min <= max,
         'min must not exceed max',
       ),
       assert(decimals == null || decimals >= 0, 'decimals must be >= 0');

  /// Current value; null shows an empty field (with the [placeholder]).
  final double? value;

  /// Called with the clamped value as it changes — live while typing (only
  /// when the text parses), and on every commit or step. An emptied field
  /// reports null.
  final ValueChanged<double?>? onChanged;

  /// Lower bound; also gates the leading minus (typing '-' is only allowed
  /// when negatives are representable, i.e. [min] is null or below zero).
  final double? min;

  /// Upper bound; committed and stepped values never exceed it.
  final double? max;

  /// How far one stepper activation (or arrow key) moves the value.
  final double step;

  /// Fraction-digit precision: typing is limited to this many decimals and
  /// committed values reformat to exactly this many (0 forbids the
  /// separator entirely). Null leaves precision free.
  final int? decimals;

  /// Optional label rendered above the field.
  final String? title;

  /// Hint shown while the field is empty.
  final String? placeholder;

  /// Whether the field accepts input; false makes field and steppers inert.
  final bool enabled;

  /// The field's focus; null lets the widget own one internally.
  final FocusNode? focusNode;

  /// Semantic label of the increment stepper.
  final String increaseLabel;

  /// Semantic label of the decrement stepper.
  final String decreaseLabel;

  /// Fill color of the field surface.
  @Style<Color>.resolve(ColorRef.background1)
  final Color? background;

  /// Corner rounding of the field surface.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Inner padding between the border and the text.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Text style of the entered text (and the placeholder, recolored).
  @Style<TextStyle>.resolve(TextRef.b1)
  final TextStyle? textStyle;

  /// Border color while unfocused.
  @Style<Color>.resolve(ColorRef.background3)
  final Color? borderColor;

  /// Border color while focused — also the caret and selection color.
  @Style<Color>.resolve(ColorRef.primary)
  final Color? focusedBorderColor;

  /// Fill of a stepper button per interaction state (disabled falls back
  /// to the normal fill — the arrow color carries the disabled look).
  @Style<InteractiveColors>.resolve(_stepperColors)
  final InteractiveColors? stepperColors;

  /// Color of the stepper arrows.
  @Style<Color>.resolve(ColorRef.foreground2)
  final Color? stepperForeground;

  /// Width of the trailing stepper column.
  @Style<double>.resolve(SizeRef.lg)
  final double? stepperWidth;

  @override
  State<LegendNumberField> createState() => _LegendNumberFieldState();
}

class _LegendNumberFieldState extends State<LegendNumberField> {
  final _controller = TextEditingController();
  FocusNode? _ownFocusNode;

  Timer? _holdTimer;
  Timer? _repeatTimer;

  /// Whether the current press-and-hold already stepped — the release tap
  /// then must not step again.
  var _didRepeat = false;

  /// The value last delivered through [LegendNumberField.onChanged] (or
  /// last accepted from the widget) — reports dedupe against this, not
  /// against `widget.value`, which goes stale when the parent doesn't
  /// rebuild with the reported value.
  double? _lastReported;

  /// How long a stepper press holds before repeating starts.
  static const _holdDelay = Duration(milliseconds: 500);

  /// Interval between repeated steps while holding.
  static const _holdInterval = Duration(milliseconds: 80);

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.text = _format(widget.value);
    _lastReported = widget.value;
    _focusNode.addListener(_onFocusChange);
    // Placeholder visibility and stepper bound-disable track the text.
    _controller.addListener(_onTextTick);
  }

  @override
  void didUpdateWidget(LegendNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      // The own instance is stable; only external swaps need re-listening.
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
    // Sync an external value change into the text — but never clobber text
    // that already parses to the new value (the echo of our own report).
    if (oldWidget.value != widget.value) {
      _lastReported = widget.value;
      if (widget.value != _parse(_controller.text)) {
        _controller.text = _format(widget.value);
      }
    }
  }

  @override
  void dispose() {
    _stopHold();
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onTextTick() => setState(() {});

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commit();
    setState(() {});
  }

  // --- value model -------------------------------------------------------

  /// The simple-locale parse: one '.' (or ',') separator, optional minus.
  double? _parse(String text) => double.tryParse(text.replaceAll(',', '.'));

  /// The value the steppers walk from: the current text when it parses,
  /// else the last committed [LegendNumberField.value].
  double? get _current => _parse(_controller.text) ?? widget.value;

  /// Clamps into [LegendNumberField.min]/[LegendNumberField.max] and rounds to the
  /// [LegendNumberField.decimals] precision (a sane default precision
  /// otherwise, so 0.1-steps don't accumulate float noise).
  double _normalize(double value) {
    var v = value;
    final min = widget.min;
    final max = widget.max;
    if (min != null && v < min) v = min;
    if (max != null && v > max) v = max;
    return double.parse(v.toStringAsFixed(widget.decimals ?? 10));
  }

  String _format(double? value) {
    if (value == null) return '';
    final decimals = widget.decimals;
    if (decimals != null) return value.toStringAsFixed(decimals);
    final text = value.toString();
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  void _report(double? value) {
    if (value == _lastReported) return;
    _lastReported = value;
    widget.onChanged?.call(value);
  }

  /// Live report while typing: only when the text parses (or empties) —
  /// clamped, but without rewriting what the user is mid-typing.
  void _onUserEdit(String text) {
    if (text.isEmpty) return _report(null);
    final parsed = _parse(text);
    if (parsed != null) _report(_normalize(parsed));
  }

  /// Blur/Enter: clamp, reformat the text, and report.
  void _commit() {
    final text = _controller.text;
    final double? committed;
    if (text.isEmpty) {
      committed = null;
    } else {
      final parsed = _parse(text);
      // Unparseable leftovers ('-', '.') revert to the last value.
      committed = parsed == null ? _lastReported : _normalize(parsed);
    }
    _controller.text = _format(committed);
    _report(committed);
  }

  // --- stepping ----------------------------------------------------------

  bool get _canIncrement {
    if (!widget.enabled) return false;
    final current = _current;
    final max = widget.max;
    return current == null || max == null || current < max;
  }

  bool get _canDecrement {
    if (!widget.enabled) return false;
    final current = _current;
    final min = widget.min;
    return current == null || min == null || current > min;
  }

  void _step(double direction) {
    final next = _normalize((_current ?? 0) + direction * widget.step);
    _controller.text = _format(next);
    _report(next);
  }

  void _startHold(double direction) {
    _stopHold();
    _didRepeat = false;
    _holdTimer = Timer(_holdDelay, () {
      _didRepeat = true;
      _step(direction);
      _repeatTimer = Timer.periodic(_holdInterval, (_) {
        if (direction > 0 ? _canIncrement : _canDecrement) {
          _step(direction);
        } else {
          _stopHold();
        }
      });
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _repeatTimer?.cancel();
    _holdTimer = null;
    _repeatTimer = null;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && _canIncrement) {
      _step(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && _canDecrement) {
      _step(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // --- build -------------------------------------------------------------

  Widget _stepper(
    LegendNumberFieldTheme theme,
    LegendTokens tokens, {
    required bool up,
  }) {
    final canStep = up ? _canIncrement : _canDecrement;
    final direction = up ? 1.0 : -1.0;
    return Expanded(
      child: Listener(
        onPointerDown: canStep ? (_) => _startHold(direction) : null,
        onPointerUp: (_) => _stopHold(),
        onPointerCancel: (_) => _stopHold(),
        child: LegendInteractive(
          enabled: canStep,
          semanticLabel: up ? widget.increaseLabel : widget.decreaseLabel,
          onTap: () {
            // A hold that already repeated consumes the release tap.
            if (_didRepeat) {
              _didRepeat = false;
              return;
            }
            _step(direction);
          },
          builder: (context, states) => LegendSurface(
            color: theme.stepperColors.pick(states.effective),
            duration: const Duration(milliseconds: 120),
            child: SizedBox(
              width: theme.stepperWidth,
              child: Center(
                child: LegendCaret(
                  color: canStep
                      ? theme.stepperForeground
                      : tokens.colors.onDisabled,
                  open: up,
                  size: const Size(8, 5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final focused = _focusNode.hasFocus;
    final borderColor = focused ? theme.focusedBorderColor : theme.borderColor;
    final allowNegative = widget.min == null || widget.min! < 0;

    final field = LegendSurface(
      color: widget.enabled ? theme.background : tokens.colors.disabled,
      borderRadius: theme.borderRadius,
      border: Border.all(color: borderColor, width: tokens.sizes.borderWidth),
      duration: const Duration(milliseconds: 120),
      clip: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.enabled ? _focusNode.requestFocus : null,
                child: Padding(
                  padding: theme.padding,
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      if (_controller.text.isEmpty &&
                          widget.placeholder != null)
                        ExcludeSemantics(
                          child: Text(
                            widget.placeholder!,
                            style: theme.textStyle.copyWith(
                              color: tokens.colors.foreground3,
                            ),
                          ),
                        ),
                      Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        onKeyEvent: _onKeyEvent,
                        child: LegendFieldCore(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: theme.textStyle.copyWith(
                            color: widget.enabled
                                ? tokens.colors.foreground1
                                : tokens.colors.onDisabled,
                          ),
                          cursorColor: theme.focusedBorderColor,
                          backgroundCursorColor: theme.borderColor,
                          selectionColor: theme.focusedBorderColor.withValues(
                            alpha: 0.3,
                          ),
                          readOnly: !widget.enabled,
                          keyboardType: TextInputType.numberWithOptions(
                            signed: allowNegative,
                            decimal: widget.decimals != 0,
                          ),
                          inputFormatters: [
                            _DecimalTextInputFormatter(
                              allowNegative: allowNegative,
                              decimals: widget.decimals,
                            ),
                          ],
                          onChanged: _onUserEdit,
                          onSubmitted: (_) => _commit(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _stepper(theme, tokens, up: true),
                _stepper(theme, tokens, up: false),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.title == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.sizes.xs,
      children: [
        Text(
          widget.title!,
          style: tokens.typography.b3.copyWith(
            color: tokens.colors.foreground2,
          ),
        ),
        field,
      ],
    );
  }
}

/// Keeps the text a valid simple-locale decimal: digits, at most one
/// separator ('.' or ',', normalized to '.'), a leading minus only when
/// `allowNegative`, and at most `decimals` fraction digits. Rejected edits
/// keep the previous text.
class _DecimalTextInputFormatter extends TextInputFormatter {
  _DecimalTextInputFormatter({
    required bool allowNegative,
    required int? decimals,
  }) : _pattern = RegExp(
         '^${allowNegative ? '-?' : ''}\\d*'
         '${switch (decimals) {
           0 => '',
           null => r'(\.\d*)?',
           final d => '(\\.\\d{0,$d})?',
         }}\$',
       );

  final RegExp _pattern;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '.');
    if (!_pattern.hasMatch(text)) return oldValue;
    // ',' → '.' is length-preserving, so the selection carries over as-is.
    return text == newValue.text ? newValue : newValue.copyWith(text: text);
  }
}

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

EdgeInsetsGeometry _padding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);

InteractiveColors _stepperColors(LegendTokens t) => InteractiveColors(
  normal: t.colors.background1,
  hovered: t.colors.background2,
  pressed: t.colors.background3,
  disabled: t.colors.background1,
);
