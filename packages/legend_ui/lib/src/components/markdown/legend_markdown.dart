import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/divider/legend_divider.dart';
import 'package:legend_ui/src/components/markdown/legend_markdown_syntax.dart';
import 'package:legend_ui/src/components/text/legend_text.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';
import 'package:markdown/markdown.dart' as md;

part 'legend_markdown.theme.g.dart';

/// Called when a markdown link is tapped, with the link's destination
/// (`href`) exactly as written in the source. The kit does not open URLs
/// itself — route the href to your navigator or launcher.
typedef LegendMarkdownLinkCallback = void Function(String href);

/// A read-only markdown block renderer — parses markdown source
/// (CommonMark plus GFM tables and strikethrough) into an AST with
/// `package:markdown` and renders it as a column of themed blocks
/// (RFC-004 #21, the first slice of the RFC-005 editor track).
///
/// Composes [LegendText] (the text core — every prose block is a
/// [LegendText.rich] span tree, so all content participates in text
/// selection under a `SelectionArea`), [LegendSurface] for fenced code
/// blocks, and [LegendDivider] for horizontal rules. The parser is used
/// for the AST only — never for HTML output; raw HTML in the source
/// renders as literal text.
///
/// Supported: headings (`#`–`######`), paragraphs, bold/italic/
/// strikethrough, inline code, fenced code blocks, links (tappable via
/// [onTapLink]), ordered/unordered/nested lists, blockquotes, horizontal
/// rules, and tables. Images render as their alt text — a markdown
/// document never triggers network fetches from inside the kit.
///
/// Domain-specific notation beyond that (RFC-005 §3.3) registers through
/// [syntaxes]: each [LegendMarkdownSyntax] pairs a `package:markdown`
/// parse hook with a span/widget render hook, and the same registrations
/// will later drive the editor's highlighter.
@LegendThemeable()
class LegendMarkdown extends StatefulWidget {
  const LegendMarkdown(
    this.data, {
    super.key,
    this.syntaxes = const [],
    this.onTapLink,
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.h4Style,
    this.h5Style,
    this.h6Style,
    this.bodyStyle,
    this.codeStyle,
    this.codeBackground,
    this.blockquoteBarColor,
    this.blockquoteInset,
    this.linkColor,
    this.markerColor,
    this.listIndent,
    this.tableBorderColor,
    this.blockSpacing,
  });

  /// The markdown source to render.
  final String data;

  /// Custom notations rendered in addition to the built-in syntax — the
  /// shared registry of RFC-005 §3.3, one [LegendMarkdownSyntax] per
  /// notation.
  final List<LegendMarkdownSyntax> syntaxes;

  /// Invoked with the link destination when a link is tapped; when null,
  /// links render styled but inert.
  final LegendMarkdownLinkCallback? onTapLink;

  /// Style of `#` headings.
  @Style<TextStyle>.resolve(TextRef.h1)
  final TextStyle? h1Style;

  /// Style of `##` headings.
  @Style<TextStyle>.resolve(TextRef.h2)
  final TextStyle? h2Style;

  /// Style of `###` headings.
  @Style<TextStyle>.resolve(TextRef.h3)
  final TextStyle? h3Style;

  /// Style of `####` headings.
  @Style<TextStyle>.resolve(_h4Style)
  final TextStyle? h4Style;

  /// Style of `#####` headings.
  @Style<TextStyle>.resolve(_h5Style)
  final TextStyle? h5Style;

  /// Style of `######` headings.
  @Style<TextStyle>.resolve(_h6Style)
  final TextStyle? h6Style;

  /// Base style of paragraphs, list items, quotes, and table cells.
  @Style<TextStyle>.resolve(TextRef.b1)
  final TextStyle? bodyStyle;

  /// Monospace style of inline code and fenced code blocks.
  @Style<TextStyle>.resolve(_codeStyle)
  final TextStyle? codeStyle;

  /// Fill behind inline code and fenced code blocks.
  @Style<Color>.resolve(ColorRef.background2)
  final Color? codeBackground;

  /// Color of the bar running down a blockquote's leading edge.
  @Style<Color>.resolve(ColorRef.background3)
  final Color? blockquoteBarColor;

  /// Gap between the blockquote bar and the quoted content.
  @Style<double>.resolve(SizeRef.md)
  final double? blockquoteInset;

  /// Color of link text and its underline.
  @Style<Color>.resolve(ColorRef.primary)
  final Color? linkColor;

  /// Color of list bullets and numbers.
  @Style<Color>.resolve(ColorRef.foreground2)
  final Color? markerColor;

  /// Width of the marker gutter each list level indents by.
  @Style<double>.resolve(SizeRef.lg)
  final double? listIndent;

  /// Color of table grid lines.
  @Style<Color>.resolve(ColorRef.background3)
  final Color? tableBorderColor;

  /// Vertical gap between top-level blocks.
  @Style<double>.resolve(SizeRef.md)
  final double? blockSpacing;

  @override
  State<LegendMarkdown> createState() => _LegendMarkdownState();
}

TextStyle _h4Style(LegendTokens t) =>
    t.typography.b1.copyWith(fontWeight: FontWeight.w600);

TextStyle _h5Style(LegendTokens t) =>
    t.typography.b2.copyWith(fontWeight: FontWeight.w600);

TextStyle _h6Style(LegendTokens t) =>
    t.typography.b3.copyWith(fontWeight: FontWeight.w600);

TextStyle _codeStyle(LegendTokens t) => t.typography.b2.copyWith(
  fontFamily: 'monospace',
  fontFamilyFallback: const ['Menlo', 'Courier'],
);

class _LegendMarkdownState extends State<LegendMarkdown> {
  late List<md.Node> _nodes;

  /// Recognizers backing tappable link spans of the current build; replaced
  /// wholesale whenever the span tree is rebuilt.
  final List<TapGestureRecognizer> _recognizers = [];

  /// The kit's built-in markdown surface: the CommonMark defaults plus GFM
  /// tables and strikethrough. Raw HTML is deliberately not parsed — this
  /// renderer has no HTML pipeline for it to mean anything in.
  static final List<md.BlockSyntax> _blockSyntaxes = [
    const md.FencedCodeBlockSyntax(),
    const md.TableSyntax(),
  ];
  static final List<md.InlineSyntax> _inlineSyntaxes = [
    md.StrikethroughSyntax(),
  ];

  /// Tags that render as blocks — used to split mixed list-item children
  /// into paragraph runs and nested blocks.
  static const Set<String> _blockTags = {
    'p',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'ul',
    'ol',
    'blockquote',
    'pre',
    'hr',
    'table',
  };

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(LegendMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data ||
        !listEquals(widget.syntaxes, oldWidget.syntaxes)) {
      _parse();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _parse() {
    final document = md.Document(
      blockSyntaxes: [
        ..._blockSyntaxes,
        for (final syntax in widget.syntaxes)
          if (syntax.blockParser case final parser?) parser,
      ],
      inlineSyntaxes: [
        ..._inlineSyntaxes,
        for (final syntax in widget.syntaxes)
          if (syntax.parser case final parser?) parser,
      ],
      // The AST is rendered as spans, never as HTML — keep source text raw.
      encodeHtml: false,
    );
    _nodes = document.parse(widget.data);
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  LegendMarkdownWidgetBuilder? _blockBuilderFor(String tag) {
    for (final syntax in widget.syntaxes) {
      if (!syntax.isInline && syntax.tag == tag) return syntax.blockBuilder;
    }
    return null;
  }

  LegendMarkdownSpanBuilder? _spanBuilderFor(String tag) {
    for (final syntax in widget.syntaxes) {
      if (syntax.isInline && syntax.tag == tag) return syntax.builder;
    }
    return null;
  }

  bool _isBlock(md.Node node) =>
      node is md.Element &&
      (_blockTags.contains(node.tag) || _blockBuilderFor(node.tag) != null);

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    _disposeRecognizers();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.blockSpacing,
      children: _buildBlocks(context, _nodes, theme, tokens),
    );
  }

  // --- block rendering ---

  List<Widget> _buildBlocks(
    BuildContext context,
    List<md.Node> nodes,
    LegendMarkdownTheme theme,
    LegendTokens tokens,
  ) => [for (final node in nodes) _buildBlock(context, node, theme, tokens)];

  Widget _buildBlock(
    BuildContext context,
    md.Node node,
    LegendMarkdownTheme theme,
    LegendTokens tokens,
  ) {
    if (node is! md.Element) {
      // A stray top-level text run — render it as a paragraph.
      return _paragraph(context, [node], theme, theme.bodyStyle);
    }
    final custom = _blockBuilderFor(node.tag);
    if (custom != null) return custom(context, node);
    return switch (node.tag) {
      'p' => _paragraph(context, node.children ?? [], theme, theme.bodyStyle),
      'h1' => _paragraph(context, node.children ?? [], theme, theme.h1Style),
      'h2' => _paragraph(context, node.children ?? [], theme, theme.h2Style),
      'h3' => _paragraph(context, node.children ?? [], theme, theme.h3Style),
      'h4' => _paragraph(context, node.children ?? [], theme, theme.h4Style),
      'h5' => _paragraph(context, node.children ?? [], theme, theme.h5Style),
      'h6' => _paragraph(context, node.children ?? [], theme, theme.h6Style),
      'blockquote' => _blockquote(context, node, theme, tokens),
      'pre' => _codeBlock(node, theme, tokens),
      'ul' => _list(context, node, theme, tokens, ordered: false),
      'ol' => _list(context, node, theme, tokens, ordered: true),
      'hr' => const LegendDivider(),
      'table' => _table(context, node, theme, tokens),
      // Unknown containers (e.g. a footnote section) fall back to their
      // block children; unknown leaves to their text.
      _ when (node.children ?? []).any(_isBlock) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.blockSpacing,
        children: _buildBlocks(context, node.children!, theme, tokens),
      ),
      _ => _paragraph(context, node.children ?? [], theme, theme.bodyStyle),
    };
  }

  Widget _paragraph(
    BuildContext context,
    List<md.Node> nodes,
    LegendMarkdownTheme theme,
    TextStyle style,
  ) => LegendText.rich(
    TextSpan(children: _buildSpans(context, nodes, theme, style)),
    style: style,
  );

  Widget _blockquote(
    BuildContext context,
    md.Element element,
    LegendMarkdownTheme theme,
    LegendTokens tokens,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      border: BorderDirectional(
        start: BorderSide(
          color: theme.blockquoteBarColor,
          width: tokens.sizes.borderWidth * 3,
        ),
      ),
    ),
    child: Padding(
      padding: EdgeInsetsDirectional.only(start: theme.blockquoteInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.blockSpacing,
        children: _buildBlocks(context, element.children ?? [], theme, tokens),
      ),
    ),
  );

  Widget _codeBlock(
    md.Element element,
    LegendMarkdownTheme theme,
    LegendTokens tokens,
  ) {
    // A fenced block is `pre > code` with a trailing newline in the text.
    final code = element.textContent.trimRight();
    return LegendSurface(
      color: theme.codeBackground,
      borderRadius: tokens.sizes.borderRadiusSm,
      padding: EdgeInsets.all(tokens.sizes.sm),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: LegendText(code, style: theme.codeStyle),
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    md.Element element,
    LegendMarkdownTheme theme,
    LegendTokens tokens, {
    required bool ordered,
  }) {
    final start = int.tryParse(element.attributes['start'] ?? '') ?? 1;
    final items = [
      for (final child in element.children ?? <md.Node>[])
        if (child is md.Element && child.tag == 'li') child,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.xs,
      children: [
        for (final (index, item) in items.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: theme.listIndent,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: tokens.sizes.xs),
                  child: LegendText(
                    ordered ? '${start + index}.' : '•',
                    color: theme.markerColor,
                    style: theme.bodyStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
              Expanded(child: _listItem(context, item, theme, tokens)),
            ],
          ),
      ],
    );
  }

  /// A list item's children mix bare inline runs (tight lists) with block
  /// elements (loose lists, nested lists) — group consecutive inline nodes
  /// into paragraphs and render blocks between them.
  Widget _listItem(
    BuildContext context,
    md.Element item,
    LegendMarkdownTheme theme,
    LegendTokens tokens,
  ) {
    final blocks = <Widget>[];
    final run = <md.Node>[];
    void flush() {
      if (run.isEmpty) return;
      blocks.add(_paragraph(context, [...run], theme, theme.bodyStyle));
      run.clear();
    }

    for (final child in item.children ?? <md.Node>[]) {
      if (_isBlock(child)) {
        flush();
        blocks.add(_buildBlock(context, child, theme, tokens));
      } else {
        run.add(child);
      }
    }
    flush();
    if (blocks.length == 1) return blocks.single;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.xs,
      children: blocks,
    );
  }

  Widget _table(
    BuildContext context,
    md.Element element,
    LegendMarkdownTheme theme,
    LegendTokens tokens,
  ) {
    final rows = <TableRow>[];
    for (final section in element.children ?? <md.Node>[]) {
      if (section is! md.Element) continue;
      for (final row in section.children ?? <md.Node>[]) {
        if (row is! md.Element || row.tag != 'tr') continue;
        rows.add(
          TableRow(
            children: [
              for (final cell in row.children ?? <md.Node>[])
                if (cell is md.Element)
                  _tableCell(context, cell, theme, tokens),
            ],
          ),
        );
      }
    }
    return Table(
      border: TableBorder.all(
        color: theme.tableBorderColor,
        width: tokens.sizes.borderWidth,
      ),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  Widget _tableCell(
    BuildContext context,
    md.Element cell,
    LegendMarkdownTheme theme,
    LegendTokens tokens,
  ) {
    final header = cell.tag == 'th';
    final style = header
        ? theme.bodyStyle.copyWith(fontWeight: FontWeight.w600)
        : theme.bodyStyle;
    final align = switch (cell.attributes['align']) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.start,
    };
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.sizes.sm,
        vertical: tokens.sizes.xs,
      ),
      child: LegendText.rich(
        TextSpan(
          children: _buildSpans(context, cell.children ?? [], theme, style),
        ),
        style: style,
        textAlign: align,
      ),
    );
  }

  // --- inline rendering ---

  List<InlineSpan> _buildSpans(
    BuildContext context,
    List<md.Node> nodes,
    LegendMarkdownTheme theme,
    TextStyle style, {
    GestureRecognizer? recognizer,
  }) => [
    for (final node in nodes)
      _buildSpan(context, node, theme, style, recognizer: recognizer),
  ];

  InlineSpan _buildSpan(
    BuildContext context,
    md.Node node,
    LegendMarkdownTheme theme,
    TextStyle style, {
    GestureRecognizer? recognizer,
  }) {
    if (node is! md.Element) {
      return TextSpan(text: node.textContent, recognizer: recognizer);
    }
    final custom = _spanBuilderFor(node.tag);
    if (custom != null) return custom(context, node, style);
    switch (node.tag) {
      case 'em':
        const delta = TextStyle(fontStyle: FontStyle.italic);
        return _styled(context, node, theme, style, delta, recognizer);
      case 'strong':
        const delta = TextStyle(fontWeight: FontWeight.w700);
        return _styled(context, node, theme, style, delta, recognizer);
      case 'del':
        const delta = TextStyle(decoration: TextDecoration.lineThrough);
        return _styled(context, node, theme, style, delta, recognizer);
      case 'code':
        return TextSpan(
          text: node.textContent,
          style: theme.codeStyle.copyWith(
            backgroundColor: theme.codeBackground,
          ),
          recognizer: recognizer,
        );
      case 'a':
        return _link(context, node, theme, style);
      case 'br':
        return TextSpan(text: '\n', recognizer: recognizer);
      case 'img':
        // No image pipeline (and no network fetches) — the alt text stands
        // in for the image.
        return TextSpan(text: node.attributes['alt'], recognizer: recognizer);
      default:
        // Unknown inline tags are transparent: their children render with
        // the surrounding style.
        return TextSpan(
          children: _buildSpans(
            context,
            node.children ?? [],
            theme,
            style,
            recognizer: recognizer,
          ),
        );
    }
  }

  TextSpan _styled(
    BuildContext context,
    md.Element element,
    LegendMarkdownTheme theme,
    TextStyle style,
    TextStyle delta,
    GestureRecognizer? recognizer,
  ) => TextSpan(
    style: delta,
    children: _buildSpans(
      context,
      element.children ?? [],
      theme,
      style.merge(delta),
      recognizer: recognizer,
    ),
  );

  InlineSpan _link(
    BuildContext context,
    md.Element element,
    LegendMarkdownTheme theme,
    TextStyle style,
  ) {
    final href = element.attributes['href'];
    final onTapLink = widget.onTapLink;
    TapGestureRecognizer? recognizer;
    if (href != null && onTapLink != null) {
      // Recognizers do not cascade to child spans, so the same instance is
      // threaded down to every leaf of the link's span subtree.
      recognizer = TapGestureRecognizer()..onTap = () => onTapLink(href);
      _recognizers.add(recognizer);
    }
    final delta = TextStyle(
      color: theme.linkColor,
      decoration: TextDecoration.underline,
      decorationColor: theme.linkColor,
    );
    return TextSpan(
      style: delta,
      children: _buildSpans(
        context,
        element.children ?? [],
        theme,
        style.merge(delta),
        recognizer: recognizer,
      ),
    );
  }
}
