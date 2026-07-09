import 'package:flutter/widgets.dart';

/// A small chevron that rotates when [open] — the shared disclosure
/// indicator for dropdown triggers, expandables and similar widgets
/// (extracted so components don't ship duplicate caret painters).
class LegendCaret extends StatelessWidget {
  const LegendCaret({
    required this.color,
    required this.open,
    super.key,
    this.size = const Size(10, 6),
    this.duration = const Duration(milliseconds: 120),
  });

  final Color color;

  /// Whether the caret points up (open) instead of down (closed).
  final bool open;

  final Size size;

  /// How long the open/close rotation takes.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: open ? 0.5 : 0,
      duration: duration,
      child: CustomPaint(size: size, painter: _CaretPainter(color)),
    );
  }
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) => color != oldDelegate.color;
}
