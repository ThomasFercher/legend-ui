import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;

/// Builds the [InlineSpan] for a custom inline [md.Element] emitted by a
/// [LegendMarkdownSyntax.inline] parser. [style] is the fully resolved text
/// style at the element's position, so custom spans can inherit or merge
/// over it.
typedef LegendMarkdownSpanBuilder =
    InlineSpan Function(
      BuildContext context,
      md.Element element,
      TextStyle style,
    );

/// Builds the block [Widget] for a custom block [md.Element] emitted by a
/// [LegendMarkdownSyntax.block] parser.
typedef LegendMarkdownWidgetBuilder =
    Widget Function(BuildContext context, md.Element element);

/// One custom markdown notation — a parse hook plus a render hook,
/// registered once and consumed by every markdown consumer in the kit
/// (RFC-005 §3.3): today the read-only `LegendMarkdown` renderer, later the
/// editor's highlighter, so a notation can never diverge between editing
/// and rendering.
///
/// The parse hook is a plain `package:markdown` [md.InlineSyntax] /
/// [md.BlockSyntax] subclass emitting an [md.Element] whose tag is [tag];
/// the render hook turns that element into an [InlineSpan]
/// ([LegendMarkdownSyntax.inline]) or a [Widget]
/// ([LegendMarkdownSyntax.block]). A domain notation (an `@[ref:…]` law
/// reference, a `:::note` callout) is one instance of this class passed to
/// `LegendMarkdown.syntaxes`:
///
/// ```dart
/// class LawRefSyntax extends md.InlineSyntax {
///   LawRefSyntax() : super(r'@\[ref:([^\]]+)\]');
///
///   @override
///   bool onMatch(md.InlineParser parser, Match match) {
///     parser.addNode(md.Element.text('lawRef', match[1]!));
///     return true;
///   }
/// }
///
/// LegendMarkdownSyntax.inline(
///   tag: 'lawRef',
///   parser: LawRefSyntax(),
///   builder: (context, element, style) =>
///       TextSpan(text: '§ ${element.textContent}', style: bold),
/// )
/// ```
///
/// The editor's highlight rule (RFC-005 §3.3) will slot in here as an
/// additional optional member once the editor lands — registrations written
/// today stay source-compatible.
class LegendMarkdownSyntax {
  /// A custom inline notation: [parser] emits `<tag>` elements inside a
  /// text run; [builder] renders each one as an [InlineSpan].
  const LegendMarkdownSyntax.inline({
    required this.tag,
    required md.InlineSyntax this.parser,
    required LegendMarkdownSpanBuilder this.builder,
  }) : blockParser = null,
       blockBuilder = null;

  /// A custom block notation: [blockParser] emits `<tag>` elements at block
  /// level; [blockBuilder] renders each one as a [Widget].
  const LegendMarkdownSyntax.block({
    required this.tag,
    required md.BlockSyntax this.blockParser,
    required LegendMarkdownWidgetBuilder this.blockBuilder,
  }) : parser = null,
       builder = null;

  /// The [md.Element.tag] this notation's parser emits — the key connecting
  /// the parse hook to the render hook.
  final String tag;

  /// The inline parse hook; null for a block notation.
  final md.InlineSyntax? parser;

  /// The inline render hook; null for a block notation.
  final LegendMarkdownSpanBuilder? builder;

  /// The block parse hook; null for an inline notation.
  final md.BlockSyntax? blockParser;

  /// The block render hook; null for an inline notation.
  final LegendMarkdownWidgetBuilder? blockBuilder;

  /// Whether this is an inline notation ([LegendMarkdownSyntax.inline]).
  bool get isInline => parser != null;
}
