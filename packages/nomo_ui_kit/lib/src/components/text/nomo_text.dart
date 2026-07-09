import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';

/// Which token text style a [NomoText] uses.
enum NomoTextVariant { h1, h2, h3, b1, b2, b3 }

/// Token-styled text — the text core (DESIGN.md §3). Styles come straight
/// from `NomoTokens.typography`; there is no per-widget theme class and no
/// silent auto-fit (legacy's dead `fit:` API is intentionally not ported —
/// an explicit `NomoFittedText` can come later if a real need shows up,
/// DESIGN §9.4).
class NomoText extends StatelessWidget {
  const NomoText(
    this.text, {
    super.key,
    this.variant = NomoTextVariant.b1,
    this.color,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final NomoTextVariant variant;

  /// Defaults to the `foreground1` color token.
  final Color? color;

  /// Merged over the variant's token style.
  final TextStyle? style;

  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final tokens = NomoTheme.of(context).tokens;
    final base = switch (variant) {
      NomoTextVariant.h1 => tokens.typography.h1,
      NomoTextVariant.h2 => tokens.typography.h2,
      NomoTextVariant.h3 => tokens.typography.h3,
      NomoTextVariant.b1 => tokens.typography.b1,
      NomoTextVariant.b2 => tokens.typography.b2,
      NomoTextVariant.b3 => tokens.typography.b3,
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
