import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_loading.theme.g.dart';

/// An indeterminate arc spinner — a rotating [CustomPainter] arc, no
/// Material `CircularProgressIndicator` (DESIGN.md §3: no Material
/// service dependencies).
@LegendThemeable()
class LegendLoading extends StatefulWidget {
  const LegendLoading({super.key, this.color, this.size, this.strokeWidth});

  /// Color of the spinning arc.
  @Style<Color>.resolve(_color)
  final Color? color;
  static Color _color(LegendTokens t) => t.colors.primary;

  /// Diameter of the spinner.
  @Style<double>(24)
  final double? size;

  /// Stroke width of the arc.
  @Style<double>(3)
  final double? strokeWidth;

  @override
  State<LegendLoading> createState() => _LegendLoadingState();
}

class _LegendLoadingState extends State<LegendLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget._theme(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(theme.size),
        painter: _ArcPainter(
          color: theme.color,
          strokeWidth: theme.strokeWidth,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });

  final Color color;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    canvas.drawArc(
      rect,
      progress * 2 * math.pi - math.pi / 2,
      math.pi * 1.5,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      progress != oldDelegate.progress;
}
