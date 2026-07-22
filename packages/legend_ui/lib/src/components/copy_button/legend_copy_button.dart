import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_copy_button.theme.g.dart';

/// A compact icon-button that writes [value] to the system clipboard and
/// confirms with a transient check mark.
///
/// Composes [LegendInteractive] (tap/keyboard activation, button
/// semantics); both glyphs are small stroked painters in the
/// `LegendCaret` stroke style, so the kit stays free of Material's icon
/// font.
///
/// After a copy the glyph swaps to a check drawn in [confirmationColor]
/// for [confirmationDuration], and [copiedLabel] is announced through a
/// live-region `Semantics` node — assistive tech hears the confirmation
/// sighted users see.
@LegendThemeable()
class LegendCopyButton extends StatefulWidget {
  const LegendCopyButton({
    required this.value,
    super.key,
    this.enabled = true,
    this.semanticLabel = 'Copy',
    this.copiedLabel = 'Copied',
    this.onCopied,
    this.confirmationDuration = const Duration(milliseconds: 1500),
    this.foreground,
    this.confirmationColor,
    this.glyphSize,
  });

  /// The text written to the clipboard on activation.
  final String value;

  /// Whether the button accepts input at all. False makes it fully inert.
  final bool enabled;

  /// What activating does (announced as the button's label) — override
  /// for localization or a more specific action ('Copy address').
  final String semanticLabel;

  /// Announced through the live region once the value has been copied —
  /// override for localization.
  final String copiedLabel;

  /// Called after [value] has been written to the clipboard.
  final VoidCallback? onCopied;

  /// How long the check-mark confirmation shows before the copy glyph
  /// returns.
  final Duration confirmationDuration;

  /// Color of the copy glyph, per interaction state.
  @Style<InteractiveColors>.resolve(_foreground, lerp: true)
  final InteractiveColors? foreground;

  /// Color of the post-copy check mark (the success accent).
  @Style<Color>.resolve(ColorRef.secondary, lerp: true)
  final Color? confirmationColor;

  /// Width and height of the glyph's square canvas.
  @Style<double>.resolve(SizeRef.iconSm)
  final double? glyphSize;

  @override
  State<LegendCopyButton> createState() => _LegendCopyButtonState();
}

class _LegendCopyButtonState extends State<LegendCopyButton> {
  Timer? _revertTimer;
  var _copied = false;

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  /// Confirmation only shows once the platform accepted the write — a
  /// check mark over a failed copy would be a lie.
  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    widget.onCopied?.call();
    setState(() => _copied = true);
    _revertTimer?.cancel();
    _revertTimer = Timer(widget.confirmationDuration, () {
      if (!mounted) return;
      setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;

    return LegendInteractive(
      enabled: widget.enabled,
      onTap: () => unawaited(_copy()),
      semanticLabel: widget.semanticLabel,
      builder: (context, states) {
        final color = _copied
            ? theme.confirmationColor
            : theme.foreground.resolve(states.effective, tokens.states) ??
                  tokens.colors.foreground2;
        Widget glyph = CustomPaint(
          size: Size.square(theme.glyphSize),
          painter: _copied ? _CheckPainter(color) : _CopyPainter(color),
        );
        if (_copied) {
          // The node appearing with a live region is what triggers the
          // announcement (the LegendBanner idiom); the button's own label
          // stays [semanticLabel] throughout.
          glyph = Semantics(
            container: true,
            liveRegion: true,
            label: widget.copiedLabel,
            child: glyph,
          );
        }
        // Token padding inside the (opaque-hit-test) interactive area, so
        // the tap target is comfortably larger than the glyph itself.
        return Padding(padding: EdgeInsets.all(tokens.sizes.xs), child: glyph);
      },
    );
  }
}

/// Paints the copy glyph — two overlapping outlined sheets — proportional
/// to the canvas size (stroke style matching `LegendCaret`).
class _CopyPainter extends CustomPainter {
  const _CopyPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final radius = Radius.circular(w * 0.12);
    // The front sheet (the copy) sits over the lower-right of the source
    // sheet, whose covered corner is simply not drawn.
    canvas
      ..drawPath(
        Path()
          ..moveTo(w * 0.62, h * 0.28)
          ..lineTo(w * 0.62, h * 0.14)
          ..arcToPoint(Offset(w * 0.50, h * 0.02), radius: radius)
          ..lineTo(w * 0.14, h * 0.02)
          ..arcToPoint(Offset(w * 0.02, h * 0.14), radius: radius)
          ..lineTo(w * 0.02, h * 0.50)
          ..arcToPoint(Offset(w * 0.14, h * 0.62), radius: radius)
          ..lineTo(w * 0.28, h * 0.62),
        paint,
      )
      ..drawRRect(
        RRect.fromLTRBR(w * 0.38, h * 0.38, w * 0.98, h * 0.98, radius),
        paint,
      );
  }

  @override
  bool shouldRepaint(_CopyPainter oldDelegate) => color != oldDelegate.color;
}

/// Paints the post-copy check mark (the same stroke path shape as
/// `LegendCheckbox`'s mark, on a bare canvas).
class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.18, h * 0.54)
        ..lineTo(w * 0.42, h * 0.78)
        ..lineTo(w * 0.84, h * 0.26),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => color != oldDelegate.color;
}

InteractiveColors _foreground(LegendTokens t) => InteractiveColors(
  normal: t.colors.foreground2,
  hovered: t.colors.foreground1,
  pressed: t.colors.foreground1,
  disabled: t.colors.onDisabled,
);
