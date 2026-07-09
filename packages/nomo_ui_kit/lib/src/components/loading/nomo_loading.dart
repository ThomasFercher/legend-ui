import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/loading/nomo_loading.theme.g.dart';

/// An indeterminate arc spinner — a rotating [CustomPainter] arc, no
/// Material `CircularProgressIndicator` (DESIGN.md §3: no Material
/// service dependencies).
@NomoThemeable()
class NomoLoading extends StatefulWidget {
  const NomoLoading({super.key, this.color, this.size, this.strokeWidth});

  @Themed(defaultsTo: 't.colors.primary')
  final Color? color;

  @Themed(defaultsTo: '24.0')
  final double? size;

  @Themed(defaultsTo: '3.0')
  final double? strokeWidth;

  @override
  State<NomoLoading> createState() => _NomoLoadingState();
}

class _NomoLoadingState extends State<NomoLoading>
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
    final theme = NomoLoadingTheme.of(
      context,
      NomoLoadingThemeNullable(
        color: widget.color,
        size: widget.size,
        strokeWidth: widget.strokeWidth,
      ),
    );
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
