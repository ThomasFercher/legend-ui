import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_steps.theme.g.dart';

/// One step of [LegendSteps] — a title plus optional supporting copy.
class LegendStep {
  const LegendStep({required this.title, this.description});

  /// The one-line step name.
  final String title;

  /// Optional supporting copy under the [title].
  final String? description;
}

/// Where a step stands relative to [LegendSteps.currentIndex].
enum _StepStatus { completed, current, pending }

/// A sequential progress display: numbered circles joined by connector
/// lines, one per step of a linear flow (onboarding, transaction
/// confirmation, checkout).
///
/// Composes [LegendSurface] for the circular indicators and token-styled
/// text for the labels; the completed check mark is a small stroked-path
/// painter (no Material Icons — DESIGN.md §4). Purely presentational — it
/// has no gestures of its own; the flow's controller decides
/// [currentIndex].
///
/// Steps before [currentIndex] show a painted check on [completedColor],
/// the current step shows its number emphasized on [currentColor], and
/// future steps sit muted on [pendingColor]. [currentIndex] may equal
/// `steps.length` to mark the whole flow completed.
///
/// Each step announces itself as one semantics node — "Step 2 of 4:
/// (title), current/completed" — with the description as its own node
/// beneath, so screen readers hear position and state without reading the
/// visual number.
///
/// A horizontal [axis] divides the available width equally between steps
/// (same bounded-parent contract as a horizontal `LegendDivider`); a
/// vertical one sizes to its content.
@LegendThemeable()
class LegendSteps extends StatelessWidget {
  LegendSteps({
    required this.steps,
    super.key,
    this.currentIndex = 0,
    this.axis = Axis.horizontal,
    this.indicatorSize,
    this.completedColor,
    this.currentColor,
    this.pendingColor,
    this.indicatorForeground,
    this.pendingForeground,
    this.connectorColor,
    this.connectorThickness,
    this.titleStyle,
    this.descriptionStyle,
    this.spacing,
    this.stepSpacing,
  }) : assert(steps.isNotEmpty, 'steps must not be empty.');

  /// The steps of the flow, in order.
  final List<LegendStep> steps;

  /// Index of the step currently in progress; steps before it render
  /// completed. Clamped to `0..steps.length` — passing `steps.length`
  /// marks every step completed.
  final int currentIndex;

  /// The direction the steps run in.
  final Axis axis;

  /// Diameter of the circular step indicators.
  @Style<double>.resolve(SizeRef.iconLg)
  final double? indicatorSize;

  /// Fill of completed indicators (behind the check mark).
  @Style<Color>.resolve(ColorRef.primary)
  final Color? completedColor;

  /// Fill of the current step's indicator (behind its number).
  @Style<Color>.resolve(ColorRef.primary)
  final Color? currentColor;

  /// Fill of pending indicators (behind their muted numbers).
  @Style<Color>.resolve(ColorRef.background2)
  final Color? pendingColor;

  /// Color of the check mark and the current step's number.
  @Style<Color>.resolve(ColorRef.onPrimary)
  final Color? indicatorForeground;

  /// Color of pending steps' numbers.
  @Style<Color>.resolve(ColorRef.foreground3)
  final Color? pendingForeground;

  /// Color of the connector lines between indicators.
  @Style<Color>.resolve(ColorRef.background3)
  final Color? connectorColor;

  /// Stroke width of the connector lines.
  @Style<double>.resolve(SizeRef.borderWidth)
  final double? connectorThickness;

  /// Text style of step titles (pending titles swap its color for the
  /// muted token foreground).
  @Style<TextStyle>.resolve(_titleStyle)
  final TextStyle? titleStyle;

  /// Text style of step descriptions.
  @Style<TextStyle>.resolve(_descriptionStyle)
  final TextStyle? descriptionStyle;

  /// Gap between an indicator and its texts.
  @Style<double>.resolve(SizeRef.sm)
  final double? spacing;

  /// Gap between consecutive steps along a vertical [axis] (horizontal
  /// steps divide the width equally instead).
  @Style<double>.resolve(SizeRef.md)
  final double? stepSpacing;

  _StepStatus _statusOf(int index) {
    final current = currentIndex.clamp(0, steps.length);
    if (index < current) return _StepStatus.completed;
    if (index == current) return _StepStatus.current;
    return _StepStatus.pending;
  }

  /// The spoken position and state — "Step 2 of 4: Verify, current".
  String _semanticLabelOf(int index, _StepStatus status) {
    final position =
        'Step ${index + 1} of ${steps.length}: '
        '${steps[index].title}';
    return switch (status) {
      _StepStatus.completed => '$position, completed',
      _StepStatus.current => '$position, current',
      _StepStatus.pending => position,
    };
  }

  Widget _indicator(
    LegendStepsTheme theme,
    LegendTokens tokens,
    int index,
    _StepStatus status,
  ) {
    final fill = switch (status) {
      _StepStatus.completed => theme.completedColor,
      _StepStatus.current => theme.currentColor,
      _StepStatus.pending => theme.pendingColor,
    };
    final child = status == _StepStatus.completed
        ? CustomPaint(painter: _CheckPainter(color: theme.indicatorForeground))
        : Center(
            child: Text(
              '${index + 1}',
              style: tokens.typography.b3.copyWith(
                fontWeight: FontWeight.w600,
                color: status == _StepStatus.current
                    ? theme.indicatorForeground
                    : theme.pendingForeground,
              ),
            ),
          );
    // The number/check is decoration — position and state are announced
    // by the step's semantics label instead.
    return ExcludeSemantics(
      child: LegendSurface(
        color: fill,
        borderRadius: BorderRadius.circular(theme.indicatorSize),
        duration: const Duration(milliseconds: 120),
        child: SizedBox.square(dimension: theme.indicatorSize, child: child),
      ),
    );
  }

  /// One connector segment; [horizontal] is the line's own direction.
  Widget _connector(
    LegendStepsTheme theme,
    LegendTokens tokens, {
    required bool horizontal,
  }) {
    return Padding(
      padding: horizontal
          ? EdgeInsets.symmetric(horizontal: tokens.sizes.xs)
          : EdgeInsets.symmetric(vertical: tokens.sizes.xs),
      child: SizedBox(
        width: horizontal ? null : theme.connectorThickness,
        height: horizontal ? theme.connectorThickness : null,
        child: LegendSurface(color: theme.connectorColor),
      ),
    );
  }

  Widget _horizontalStep(
    LegendStepsTheme theme,
    LegendTokens tokens,
    int index,
  ) {
    final step = steps[index];
    final status = _statusOf(index);
    return Semantics(
      container: true,
      label: _semanticLabelOf(index, status),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: index == 0
                    ? const SizedBox.shrink()
                    : _connector(theme, tokens, horizontal: true),
              ),
              _indicator(theme, tokens, index, status),
              Expanded(
                child: index == steps.length - 1
                    ? const SizedBox.shrink()
                    : _connector(theme, tokens, horizontal: true),
              ),
            ],
          ),
          SizedBox(height: theme.spacing),
          ExcludeSemantics(
            child: Text(
              step.title,
              style: status == _StepStatus.pending
                  ? theme.titleStyle.copyWith(color: tokens.colors.foreground3)
                  : theme.titleStyle,
              textAlign: TextAlign.center,
            ),
          ),
          if (step.description != null)
            Text(
              step.description!,
              style: theme.descriptionStyle,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _verticalStep(LegendStepsTheme theme, LegendTokens tokens, int index) {
    final step = steps[index];
    final status = _statusOf(index);
    final last = index == steps.length - 1;
    return Semantics(
      container: true,
      label: _semanticLabelOf(index, status),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: theme.indicatorSize,
              child: Column(
                children: [
                  _indicator(theme, tokens, index, status),
                  if (!last)
                    Expanded(
                      child: _connector(theme, tokens, horizontal: false),
                    ),
                ],
              ),
            ),
            SizedBox(width: theme.spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Center the title against the indicator circle.
                  SizedBox(
                    height: theme.indicatorSize,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ExcludeSemantics(
                        child: Text(
                          step.title,
                          style: status == _StepStatus.pending
                              ? theme.titleStyle.copyWith(
                                  color: tokens.colors.foreground3,
                                )
                              : theme.titleStyle,
                        ),
                      ),
                    ),
                  ),
                  if (step.description != null)
                    Text(step.description!, style: theme.descriptionStyle),
                  if (!last) SizedBox(height: theme.stepSpacing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    if (axis == Axis.horizontal) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(child: _horizontalStep(theme, tokens, i)),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < steps.length; i++) _verticalStep(theme, tokens, i),
      ],
    );
  }
}

/// Paints the completed check mark as a stroked path proportional to the
/// indicator size (same proportions as `LegendCheckbox`'s mark).
class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.30, h * 0.53)
      ..lineTo(w * 0.44, h * 0.67)
      ..lineTo(w * 0.70, h * 0.35);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => color != oldDelegate.color;
}

TextStyle _titleStyle(LegendTokens t) => t.typography.b2.copyWith(
  fontWeight: FontWeight.w600,
  color: t.colors.foreground1,
);

TextStyle _descriptionStyle(LegendTokens t) =>
    t.typography.b3.copyWith(color: t.colors.foreground3);
