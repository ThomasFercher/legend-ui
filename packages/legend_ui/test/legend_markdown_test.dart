import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';
import 'package:markdown/markdown.dart' as md;

Widget _wrap(Widget child, {LegendThemeData? data}) {
  return LegendTheme(
    data: data ?? const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

/// The effective style of the first span whose text equals [text] —
/// ancestor span styles merged top-down, the way the engine resolves them.
TextStyle? _styleOf(WidgetTester tester, String text) {
  for (final widget in tester.widgetList<Text>(find.byType(Text))) {
    final base = widget.style ?? const TextStyle();
    if (widget.data == text) return base;
    final span = widget.textSpan;
    if (span == null) continue;
    final found = _search(span, text, base);
    if (found != null) return found;
  }
  return null;
}

TextStyle? _search(InlineSpan span, String text, TextStyle acc) {
  if (span is! TextSpan) return null;
  final merged = span.style == null ? acc : acc.merge(span.style);
  if (span.text == text) return merged;
  for (final child in span.children ?? const <InlineSpan>[]) {
    final found = _search(child, text, merged);
    if (found != null) return found;
  }
  return null;
}

/// The recognizer attached to the first span whose text equals [text].
GestureRecognizer? _recognizerOf(WidgetTester tester, String text) {
  GestureRecognizer? result;
  for (final widget in tester.widgetList<Text>(find.byType(Text))) {
    widget.textSpan?.visitChildren((span) {
      if (span is TextSpan && span.text == text) {
        result = span.recognizer;
        return false;
      }
      return true;
    });
  }
  return result;
}

/// A custom inline notation for the end-to-end registry test: `@[ref:X]`
/// becomes a `lawRef` element (the RFC-005 §3.3 law-notation shape).
class _LawRefSyntax extends md.InlineSyntax {
  _LawRefSyntax() : super(r'@\[ref:([^\]]+)\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('lawRef', match[1]!));
    return true;
  }
}

/// A custom block notation for the end-to-end registry test: a `:::note`
/// fence becomes a `note` element wrapping its body.
class _NoteBlockSyntax extends md.BlockSyntax {
  const _NoteBlockSyntax();

  static final _closing = RegExp(r'^:::\s*$');

  @override
  RegExp get pattern => RegExp(r'^:::note\s*$');

  @override
  md.Node? parse(md.BlockParser parser) {
    parser.advance();
    final lines = <String>[];
    while (!parser.isDone && !_closing.hasMatch(parser.current.content)) {
      lines.add(parser.current.content);
      parser.advance();
    }
    if (!parser.isDone) parser.advance();
    return md.Element('note', [md.UnparsedContent(lines.join('\n'))]);
  }
}

void main() {
  const tokens = LegendTokens.light;

  group('blocks', () {
    testWidgets('headings render in the token type scale', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendMarkdown('# Title\n\n## Section\n\n#### Minor')),
      );
      expect(
        _styleOf(tester, 'Title')?.fontSize,
        tokens.typography.h1.fontSize,
      );
      expect(
        _styleOf(tester, 'Section')?.fontSize,
        tokens.typography.h2.fontSize,
      );
      // h4 derives from b1 at semibold (no h4 token exists).
      final minor = _styleOf(tester, 'Minor');
      expect(minor?.fontSize, tokens.typography.b1.fontSize);
      expect(minor?.fontWeight, FontWeight.w600);
    });

    testWidgets('paragraphs render body text', (tester) async {
      await tester.pumpWidget(_wrap(const LegendMarkdown('Just a paragraph.')));
      expect(find.text('Just a paragraph.', findRichText: true), findsOne);
    });

    testWidgets('fenced code block renders on the code surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendMarkdown('```dart\nfinal x = 1;\n```')),
      );
      expect(find.text('final x = 1;'), findsOne);
      final surface = tester.widget<LegendSurface>(find.byType(LegendSurface));
      expect(surface.color, tokens.colors.background2);
      expect(_styleOf(tester, 'final x = 1;')?.fontFamily, 'monospace');
    });

    testWidgets('blockquote draws the leading bar and inset', (tester) async {
      await tester.pumpWidget(_wrap(const LegendMarkdown('> Quoted wisdom')));
      expect(find.text('Quoted wisdom', findRichText: true), findsOne);
      final box = tester.widget<DecoratedBox>(
        find.ancestor(
          of: find.text('Quoted wisdom', findRichText: true),
          matching: find.byType(DecoratedBox),
        ),
      );
      final border =
          (box.decoration as BoxDecoration).border! as BorderDirectional;
      expect(border.start.color, tokens.colors.background3);
    });

    testWidgets('horizontal rule renders a LegendDivider', (tester) async {
      await tester.pumpWidget(_wrap(const LegendMarkdown('above\n\n---')));
      expect(find.byType(LegendDivider), findsOne);
    });

    testWidgets('unordered, ordered, and nested lists render markers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendMarkdown(
            '- one\n- two\n  - nested\n\n1. first\n2. second',
          ),
        ),
      );
      expect(find.text('•'), findsNWidgets(3));
      expect(find.text('1.'), findsOne);
      expect(find.text('2.'), findsOne);
      expect(find.text('one', findRichText: true), findsOne);
      expect(find.text('nested', findRichText: true), findsOne);
      expect(find.text('second', findRichText: true), findsOne);
    });

    testWidgets('ordered list honors a start offset', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendMarkdown('4. fourth\n5. fifth')),
      );
      expect(find.text('4.'), findsOne);
      expect(find.text('5.'), findsOne);
    });

    testWidgets('table renders a bordered grid with bold headers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendMarkdown(
            '| Law | Year |\n|-----|-----:|\n| GDPR | 2016 |',
          ),
        ),
      );
      final table = tester.widget<Table>(find.byType(Table));
      expect(table.border?.top.color, tokens.colors.background3);
      expect(table.children, hasLength(2));
      expect(_styleOf(tester, 'Law')?.fontWeight, FontWeight.w600);
      expect(find.text('2016', findRichText: true), findsOne);
    });
  });

  group('inline', () {
    testWidgets('bold, italic, strikethrough, and inline code style spans', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendMarkdown('**bold** *italic* ~~gone~~ `code` plain')),
      );
      expect(_styleOf(tester, 'bold')?.fontWeight, FontWeight.w700);
      expect(_styleOf(tester, 'italic')?.fontStyle, FontStyle.italic);
      expect(_styleOf(tester, 'gone')?.decoration, TextDecoration.lineThrough);
      final code = _styleOf(tester, 'code');
      expect(code?.fontFamily, 'monospace');
      expect(code?.backgroundColor, tokens.colors.background2);
    });

    testWidgets('link renders in the link color and reports taps', (
      tester,
    ) async {
      String? tapped;
      await tester.pumpWidget(
        _wrap(
          LegendMarkdown(
            'See [the docs](https://legend.app/docs) for more.',
            onTapLink: (href) => tapped = href,
          ),
        ),
      );
      final style = _styleOf(tester, 'the docs');
      expect(style?.color, tokens.colors.primary);
      expect(style?.decoration, TextDecoration.underline);

      final recognizer = _recognizerOf(tester, 'the docs');
      expect(recognizer, isA<TapGestureRecognizer>());
      (recognizer! as TapGestureRecognizer).onTap!();
      expect(tapped, 'https://legend.app/docs');
    });

    testWidgets('without onTapLink the link is styled but inert', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendMarkdown('[inert](https://legend.app)')),
      );
      expect(_styleOf(tester, 'inert')?.color, tokens.colors.primary);
      expect(_recognizerOf(tester, 'inert'), isNull);
    });

    testWidgets('images render as their alt text, never a fetch', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendMarkdown('![alt text](https://example.com/x.png)')),
      );
      expect(find.text('alt text', findRichText: true), findsOne);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('custom syntax registry (RFC-005 §3.3)', () {
    testWidgets('a registered inline notation parses and renders', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LegendMarkdown(
            'Per @[ref:GDPR-6] processing is lawful.',
            syntaxes: [
              LegendMarkdownSyntax.inline(
                tag: 'lawRef',
                parser: _LawRefSyntax(),
                builder: (context, element, style) => TextSpan(
                  text: '§ ${element.textContent}',
                  style: style.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
      expect(_styleOf(tester, '§ GDPR-6')?.fontWeight, FontWeight.w700);
      // The raw notation never leaks into the output.
      expect(find.textContaining('@[ref:', findRichText: true), findsNothing);
    });

    testWidgets('a registered block notation parses and renders', (
      tester,
    ) async {
      const key = Key('note');
      await tester.pumpWidget(
        _wrap(
          LegendMarkdown(
            ':::note\nRead the statute first.\n:::\n\nAfter.',
            syntaxes: [
              LegendMarkdownSyntax.block(
                tag: 'note',
                blockParser: const _NoteBlockSyntax(),
                blockBuilder: (context, element) =>
                    Container(key: key, child: LegendText(element.textContent)),
              ),
            ],
          ),
        ),
      );
      expect(find.byKey(key), findsOne);
      expect(find.text('Read the statute first.'), findsOne);
      expect(find.text('After.', findRichText: true), findsOne);
    });
  });

  group('theming', () {
    testWidgets('level 3: a components-map entry restyles links', (
      tester,
    ) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          const LegendMarkdown('[link](https://legend.app)'),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendMarkdown: LegendMarkdownThemeNullable(linkColor: navy),
            },
          ),
        ),
      );
      expect(_styleOf(tester, 'link')?.color, navy);
    });

    testWidgets('level 1: a constructor param wins over the registry', (
      tester,
    ) async {
      const navy = Color(0xFF001F54);
      const lime = Color(0xFF32CD32);
      await tester.pumpWidget(
        _wrap(
          const LegendMarkdown('[link](https://legend.app)', linkColor: lime),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendMarkdown: LegendMarkdownThemeNullable(linkColor: navy),
            },
          ),
        ),
      );
      expect(_styleOf(tester, 'link')?.color, lime);
    });
  });

  group('updates', () {
    testWidgets('new source reparses in place', (tester) async {
      await tester.pumpWidget(_wrap(const LegendMarkdown('first')));
      expect(find.text('first', findRichText: true), findsOne);
      await tester.pumpWidget(_wrap(const LegendMarkdown('# second')));
      expect(find.text('first', findRichText: true), findsNothing);
      expect(
        _styleOf(tester, 'second')?.fontSize,
        tokens.typography.h1.fontSize,
      );
    });
  });
}
