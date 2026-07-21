import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_selection_control.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_checkbox.theme.g.dart';

/// A checkbox — an independent on/off (optionally tristate) choice.
///
/// Composes [LegendSelectionControl] (tap/keyboard activation, checkbox
/// semantics including the tristate mixed state, tristate cycling) +
/// [LegendSurface] (the box itself).
///
/// The check mark and indeterminate dash are a dedicated painter:
/// `LegendCaret` is the shared *disclosure chevron*, the wrong glyph for a
/// check mark — reusing it would bend a primitive out of shape rather than
/// share code.
///
/// An optional inline [label] renders after the box and is part of the tap
/// target, so tapping the text toggles the checkbox too.
@LegendThemeable()
class LegendCheckbox extends StatelessWidget {
  const LegendCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
    this.tristate = false,
    this.enabled = true,
    this.label,
    this.semanticLabel,
    this.box,
    this.checkColor,
    this.borderColor,
    this.focusedBorderColor,
    this.size,
    this.borderWidth,
    this.borderRadius,
  });

  /// Current value — true/false, or null for the tristate indeterminate
  /// middle (only valid while [tristate]).
  final bool? value;

  /// Called with the next value when the checkbox is activated (tap or
  /// Enter/Space). Null disables the checkbox. Non-tristate checkboxes
  /// always receive a non-null value; tristate ones cycle
  /// false → true → null.
  final ValueChanged<bool?>? onChanged;

  /// Enables the third indeterminate value: the activation cycle becomes
  /// false → true → null → false and [value] may be null.
  final bool tristate;

  /// Whether the checkbox accepts input at all. False makes it fully inert.
  final bool enabled;

  /// Inline label after the box — part of the tap target, and the semantic
  /// label when [semanticLabel] is unset.
  final String? label;

  /// What this checkbox agrees to or includes (e.g. 'Accept terms') — the
  /// checked state itself is announced via checkbox semantics, never as a
  /// hard-coded label. Falls back to [label].
  final String? semanticLabel;

  /// Fill of the box while checked or indeterminate, per interaction
  /// state — hover/press blend the check color over the fill (8%/16%),
  /// disabled swaps to the token disabled fill.
  @Style<InteractiveColors>.resolve(_box, lerp: true)
  final InteractiveColors? box;

  /// Color of the check mark and indeterminate dash.
  @Style<Color>.resolve(ColorRef.onPrimary, lerp: true)
  final Color? checkColor;

  /// Border color of the unchecked box.
  @Style<Color>.resolve(ColorRef.background3, lerp: true)
  final Color? borderColor;

  /// Border color while the unchecked box holds keyboard focus (a checked
  /// box shows focus through the [box] focused fill instead).
  @Style<Color>.resolve(ColorRef.primary, lerp: true)
  final Color? focusedBorderColor;

  /// Edge length of the square box.
  @Style<double>.resolve(SizeRef.iconMd)
  final double? size;

  /// Stroke width of the unchecked border.
  @Style<double>(1.5)
  final double? borderWidth;

  /// Corner rounding of the box.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;

    return LegendSelectionControl(
      selected: value,
      onChanged: onChanged,
      role: LegendSelectionRole.checkbox,
      enabled: enabled,
      tristate: tristate,
      semanticLabel: semanticLabel ?? label,
      builder: (context, state) {
        final marked = state.selected || state.indeterminate;
        final borderColor = state.disabled
            ? tokens.colors.disabled
            : state.focused
            ? theme.focusedBorderColor
            : theme.borderColor;
        final box = LegendSurface(
          color: marked
              ? theme.box.resolve(state.effective, tokens.states)
              : null,
          borderRadius: theme.borderRadius,
          border: marked
              ? null
              : Border.all(color: borderColor, width: theme.borderWidth),
          duration: const Duration(milliseconds: 120),
          child: SizedBox.square(
            dimension: theme.size,
            child: AnimatedOpacity(
              opacity: marked ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: CustomPaint(
                painter: _MarkPainter(
                  color: state.disabled
                      ? tokens.colors.onDisabled
                      : theme.checkColor,
                  indeterminate: state.indeterminate,
                ),
              ),
            ),
          ),
        );
        final label = this.label;
        if (label == null) return box;
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.sizes.sm,
          children: [
            box,
            Flexible(
              // The control's Semantics node already carries the label —
              // without this the text would announce twice.
              child: ExcludeSemantics(
                child: Text(
                  label,
                  style: tokens.typography.b2.copyWith(
                    color: state.disabled
                        ? tokens.colors.onDisabled
                        : tokens.colors.foreground1,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Paints the check mark — or the tristate indeterminate dash — as a
/// stroked path proportional to the box size.
class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.color, required this.indeterminate});

  final Color color;
  final bool indeterminate;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = indeterminate
        ? (Path()
            ..moveTo(w * 0.26, h * 0.5)
            ..lineTo(w * 0.74, h * 0.5))
        : (Path()
            ..moveTo(w * 0.24, h * 0.54)
            ..lineTo(w * 0.43, h * 0.72)
            ..lineTo(w * 0.76, h * 0.31));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      color != oldDelegate.color || indeterminate != oldDelegate.indeterminate;
}

InteractiveColors _box(LegendTokens t) => InteractiveColors(
  normal: t.colors.primary,
  hovered: Color.alphaBlend(
    t.colors.onPrimary.withValues(alpha: 0.08),
    t.colors.primary,
  ),
  pressed: Color.alphaBlend(
    t.colors.onPrimary.withValues(alpha: 0.16),
    t.colors.primary,
  ),
  focused: Color.alphaBlend(
    t.colors.onPrimary.withValues(alpha: 0.08),
    t.colors.primary,
  ),
  disabled: t.colors.disabled,
);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusSm;
