import 'package:flutter/widgets.dart';

/// The resolved source-presentation bundle of the markdown editor — the
/// styles `LegendMarkdownEditingController` applies over the unchanged
/// markdown source (RFC-005 §3.6).
///
/// `LegendMarkdownEditor` builds one instance per build from its resolved
/// theme and hands it to the controller imperatively (the theme itself
/// stays widget-side); a standalone controller can be given one directly.
/// Every member is optional — an unset member leaves that construct in the
/// base text style.
@immutable
class LegendMarkdownSourceStyle {
  /// Const so defaults and tests can share instances as literals.
  const LegendMarkdownSourceStyle({
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.syntaxMarkColor,
    this.codeStyle,
    this.codeBackground,
    this.linkColor,
    this.blockquoteColor,
    this.markerColor,
  });

  /// Emphasis style merged over `#` heading lines.
  final TextStyle? h1Style;

  /// Emphasis style merged over `##` heading lines.
  final TextStyle? h2Style;

  /// Emphasis style merged over `###` heading lines.
  final TextStyle? h3Style;

  /// Muted color of the syntax marks themselves — the `#`, `**`, `~~`,
  /// backticks, brackets, and fence delimiters.
  final Color? syntaxMarkColor;

  /// Monospace style of inline code spans and fenced code lines.
  final TextStyle? codeStyle;

  /// Background tint behind inline code spans and fenced code lines.
  final Color? codeBackground;

  /// Color of link text (the URL part renders as a syntax mark).
  final Color? linkColor;

  /// Color of quoted content on `>` lines.
  final Color? blockquoteColor;

  /// Color of list bullets and numbers.
  final Color? markerColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendMarkdownSourceStyle &&
          other.h1Style == h1Style &&
          other.h2Style == h2Style &&
          other.h3Style == h3Style &&
          other.syntaxMarkColor == syntaxMarkColor &&
          other.codeStyle == codeStyle &&
          other.codeBackground == codeBackground &&
          other.linkColor == linkColor &&
          other.blockquoteColor == blockquoteColor &&
          other.markerColor == markerColor;

  @override
  int get hashCode => Object.hash(
    h1Style,
    h2Style,
    h3Style,
    syntaxMarkColor,
    codeStyle,
    codeBackground,
    linkColor,
    blockquoteColor,
    markerColor,
  );
}
