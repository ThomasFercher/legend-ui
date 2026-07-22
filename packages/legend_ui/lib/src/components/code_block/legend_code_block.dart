import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/text/legend_text.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_code_block.theme.g.dart';

/// Builds the styled spans a [LegendCodeBlock] renders instead of its raw
/// [LegendCodeBlock.code] — the hook a syntax highlighter plugs into. The
/// returned spans must contain exactly the source text (styling only), so
/// the copy affordance and text selection keep working on the real code.
typedef LegendCodeHighlighter = List<InlineSpan> Function(String code);

/// A monospace code display panel with a copy affordance — the
/// answer-rendering staple (RFC-004 #29).
///
/// Composes [LegendSurface] (the panel), [LegendText] (the text core — the
/// code renders as ordinary text spans, so it stays selectable under a
/// `SelectionArea`), and [LegendInteractive] for the copy affordance,
/// which writes [code] to the system [Clipboard] and shows a transient
/// check glyph while flipping its semantic label to [copiedLabel] inside a
/// live region.
///
/// Long lines scroll horizontally inside the panel; [maxHeight] bounds the
/// panel's height and lets taller code scroll vertically. No syntax
/// highlighting is built in — [highlighter] is the span-builder hook a
/// highlighter plugs into without the kit taking a dependency.
@LegendThemeable()
class LegendCodeBlock extends StatefulWidget {
  const LegendCodeBlock(
    this.code, {
    super.key,
    this.language,
    this.showCopyButton = true,
    this.maxHeight,
    this.highlighter,
    this.copyLabel = 'Copy code',
    this.copiedLabel = 'Copied',
    this.background,
    this.textStyle,
    this.borderRadius,
    this.padding,
    this.languageLabelStyle,
    this.copyGlyphColor,
  });

  /// The source code to display — also exactly what the copy affordance
  /// writes to the clipboard.
  final String code;

  /// Optional language tag shown in the panel's header corner (e.g.
  /// `'dart'`); null hides the label.
  final String? language;

  /// Whether the copy affordance is shown.
  final bool showCopyButton;

  /// Bounds the panel's height; code taller than this scrolls vertically.
  /// Null lets the panel grow with its content.
  final double? maxHeight;

  /// Builds styled spans over [code] instead of rendering it plain — the
  /// syntax-highlighting hook (see [LegendCodeHighlighter]).
  final LegendCodeHighlighter? highlighter;

  /// Semantic label of the copy affordance at rest.
  final String copyLabel;

  /// Semantic label of the copy affordance during the transient copied
  /// feedback — the flip is announced via a semantics live region.
  final String copiedLabel;

  /// Fill of the code panel.
  @Style<Color>.resolve(ColorRef.background2)
  final Color? background;

  /// Monospace style of the code text.
  @Style<TextStyle>.resolve(_textStyle)
  final TextStyle? textStyle;

  /// Corner rounding of the panel.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Inner padding around the header and the code.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Style of the [language] tag in the header.
  @Style<TextStyle>.resolve(_languageLabelStyle)
  final TextStyle? languageLabelStyle;

  /// Color of the copy affordance's glyph (both the copy sheets and the
  /// transient check).
  @Style<Color>.resolve(ColorRef.foreground2)
  final Color? copyGlyphColor;

  @override
  State<LegendCodeBlock> createState() => _LegendCodeBlockState();
}

TextStyle _textStyle(LegendTokens t) => t.typography.b2.copyWith(
  fontFamily: 'monospace',
  fontFamilyFallback: const ['Menlo', 'Courier'],
);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.all(t.sizes.md);

TextStyle _languageLabelStyle(LegendTokens t) =>
    t.typography.b3.copyWith(color: t.colors.foreground2);

class _LegendCodeBlockState extends State<LegendCodeBlock> {
  /// How long the check glyph (and the [LegendCodeBlock.copiedLabel]
  /// announcement) lingers after a copy.
  static const _copiedFeedback = Duration(milliseconds: 1500);

  Timer? _resetTimer;
  var _copied = false;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(_copiedFeedback, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final language = widget.language;
    final maxHeight = widget.maxHeight;

    Widget code = SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: widget.highlighter == null
            ? LegendText(widget.code, style: theme.textStyle)
            : LegendText.rich(
                TextSpan(children: widget.highlighter!(widget.code)),
                style: theme.textStyle,
              ),
      ),
    );
    if (maxHeight != null) {
      code = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(child: code),
      );
    }

    return LegendSurface(
      color: theme.background,
      borderRadius: theme.borderRadius,
      padding: theme.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.sizes.xs,
        children: [
          if (language != null || widget.showCopyButton)
            Row(
              spacing: tokens.sizes.sm,
              children: [
                Expanded(
                  child: language == null
                      ? const SizedBox.shrink()
                      : Text(language, style: theme.languageLabelStyle),
                ),
                if (widget.showCopyButton)
                  _CopyAffordance(
                    copied: _copied,
                    color: theme.copyGlyphColor,
                    size: tokens.sizes.iconSm,
                    semanticLabel: _copied
                        ? widget.copiedLabel
                        : widget.copyLabel,
                    onCopy: _copy,
                  ),
              ],
            ),
          code,
        ],
      ),
    );
  }
}

/// The copy control in the panel's header — its own [LegendInteractive] so
/// it presses, focuses, and announces separately from the selectable code.
///
/// The whole control merges into one semantics node marked as a live
/// region, so the label flip to the copied text is announced by assistive
/// tech — the implicit-Semantics route the SDK recommends over the
/// deprecated `SemanticsService.announce`.
class _CopyAffordance extends StatelessWidget {
  const _CopyAffordance({
    required this.copied,
    required this.color,
    required this.size,
    required this.semanticLabel,
    required this.onCopy,
  });

  final bool copied;
  final Color color;
  final double size;
  final String semanticLabel;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        liveRegion: true,
        child: LegendInteractive(
          onTap: onCopy,
          semanticLabel: semanticLabel,
          builder: (context, states) => AnimatedOpacity(
            // Rests dimmed, sharpens under the pointer — the affordance
            // signal without a second fill inside the panel.
            opacity: states.hovered || states.pressed || states.focused
                ? 1.0
                : 0.7,
            duration: const Duration(milliseconds: 120),
            child: CustomPaint(
              size: Size.square(size),
              painter: _CopyGlyphPainter(color: color, copied: copied),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the copy glyph — two offset sheets — or, during the transient
/// feedback, a check mark (stroke style matching `LegendCheckbox`'s mark).
class _CopyGlyphPainter extends CustomPainter {
  const _CopyGlyphPainter({required this.color, required this.copied});

  final Color color;
  final bool copied;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (copied) {
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.2, h * 0.55)
          ..lineTo(w * 0.42, h * 0.75)
          ..lineTo(w * 0.8, h * 0.3),
        paint,
      );
      return;
    }
    // The front sheet in full, with the back sheet's top and leading edges
    // peeking out behind its top-leading corner.
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.32, h * 0.32, w * 0.54, h * 0.54),
          Radius.circular(w * 0.12),
        ),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w * 0.64, h * 0.14)
          ..lineTo(w * 0.26, h * 0.14)
          ..quadraticBezierTo(w * 0.14, h * 0.14, w * 0.14, h * 0.26)
          ..lineTo(w * 0.14, h * 0.64),
        paint,
      );
  }

  @override
  bool shouldRepaint(_CopyGlyphPainter oldDelegate) =>
      color != oldDelegate.color || copied != oldDelegate.copied;
}
