import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';

/// Which token text style a [LegendText] uses.
enum LegendTextVariant { h1, h2, h3, b1, b2, b3 }

/// Token-styled text — the text core (DESIGN.md §3). Styles come straight
/// from `LegendTokens.typography`; there is no per-widget theme class and no
/// silent auto-fit (legacy's dead `fit:` API is intentionally not ported —
/// an explicit `LegendFittedText` can come later if a real need shows up,
/// DESIGN §9.4).
class LegendText extends StatelessWidget {
  const LegendText(
    this.text, {
    super.key,
    this.variant = LegendTextVariant.b1,
    this.color,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final LegendTextVariant variant;

  /// Defaults to the `foreground1` color token.
  final Color? color;

  /// Merged over the variant's token style.
  final TextStyle? style;

  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    final base = switch (variant) {
      LegendTextVariant.h1 => tokens.typography.h1,
      LegendTextVariant.h2 => tokens.typography.h2,
      LegendTextVariant.h3 => tokens.typography.h3,
      LegendTextVariant.b1 => tokens.typography.b1,
      LegendTextVariant.b2 => tokens.typography.b2,
      LegendTextVariant.b3 => tokens.typography.b3,
    };
    return Text(
      text,
      style: base
          .copyWith(color: color ?? tokens.colors.foreground1)
          .merge(style),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
