import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';
import 'package:markdown/markdown.dart' as md;

/// A distinctive source style so every assertion is independent of tokens.
const _style = LegendMarkdownSourceStyle(
  h1Style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
  h2Style: TextStyle(fontSize: 26),
  h3Style: TextStyle(fontSize: 22),
  syntaxMarkColor: Color(0xFF888888),
  codeStyle: TextStyle(fontFamily: 'monospace'),
  codeBackground: Color(0xFFEEEEEE),
  linkColor: Color(0xFF0000EE),
  blockquoteColor: Color(0xFF448844),
  markerColor: Color(0xFF884488),
);

const _base = TextStyle(fontSize: 14, color: Color(0xFF111111));

Widget _wrap(Widget child, {LegendThemeData? data}) {
  return LegendTheme(
    data: data ?? const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
}

/// Builds the controller's span tree the way EditableText would.
Future<TextSpan> _span(
  WidgetTester tester,
  LegendMarkdownEditingController controller, {
  bool withComposing = false,
}) async {
  await tester.pumpWidget(const SizedBox());
  return controller.buildTextSpan(
    context: tester.element(find.byType(SizedBox)),
    style: _base,
    withComposing: withComposing,
  );
}

/// The effective style of the first leaf whose text equals [text] —
/// ancestor styles merged top-down, the way the engine resolves them.
TextStyle? _styleOf(TextSpan span, String text) =>
    _search(span, text, const TextStyle());

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

/// A custom inline notation with both hooks of the shared registry: parse
/// + render for `LegendMarkdown`, highlight for the editor.
class _LawRefSyntax extends md.InlineSyntax {
  _LawRefSyntax() : super(r'@\[ref:([^\]]+)\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('lawRef', match[1]!));
    return true;
  }
}

LegendMarkdownSyntax _lawRef() => LegendMarkdownSyntax.inline(
  tag: 'lawRef',
  parser: _LawRefSyntax(),
  builder: (context, element, style) => TextSpan(
    text: '§ ${element.textContent}',
    style: style.copyWith(fontWeight: FontWeight.w700),
  ),
  highlight: LegendMarkdownHighlight(
    pattern: r'@\[ref:[^\]]+\]',
    style: (base, style) =>
        base.copyWith(color: style.linkColor, fontWeight: FontWeight.w700),
  ),
);

LegendMarkdownEditingController _controller(
  String text, {
  List<LegendMarkdownSyntax> syntaxes = const [],
}) {
  final controller = LegendMarkdownEditingController(
    text: text,
    syntaxes: syntaxes,
    sourceStyle: _style,
  );
  addTearDown(controller.dispose);
  return controller;
}

TextEditingValue _value(String text, int offset, [int? extent]) =>
    TextEditingValue(
      text: text,
      selection: extent == null
          ? TextSelection.collapsed(offset: offset)
          : TextSelection(baseOffset: offset, extentOffset: extent),
    );

void main() {
  group('buildTextSpan styles the unchanged source', () {
    testWidgets('the round-trip is exact for every construct', (tester) async {
      const sources = [
        '',
        'plain text',
        '# Title\n\n## Section\n\n### Sub\n\n#### Minor',
        '**bold** *italic* ~~gone~~ `code` and [t](https://x.y)',
        '- one\n- two\n  - nested\n1. first\n2) second',
        '> quoted\n> > deeper',
        '```dart\nfinal x = 1;\n```\nafter',
        'trailing newline\n',
        '\n\n',
        'unicode — äöü 🚀 **fett**',
      ];
      for (final source in sources) {
        final span = await _span(tester, _controller(source));
        expect(span.toPlainText(), source, reason: 'round-trip of "$source"');
      }
    });

    testWidgets('headings emphasize content and mute the marks', (
      tester,
    ) async {
      final span = await _span(
        tester,
        _controller('# One\n## Two\n### Three\n#### Four'),
      );
      expect(_styleOf(span, 'One')?.fontSize, 32);
      expect(_styleOf(span, 'Two')?.fontSize, 26);
      expect(_styleOf(span, 'Three')?.fontSize, 22);
      // h4–h6 derive as semibold body (the base size), matching the
      // renderer.
      expect(_styleOf(span, 'Four')?.fontSize, _base.fontSize);
      expect(_styleOf(span, 'Four')?.fontWeight, FontWeight.w600);
      // The `# ` mark is muted but keeps the heading's metrics.
      final mark = _styleOf(span, '# ');
      expect(mark?.color, _style.syntaxMarkColor);
      expect(mark?.fontSize, 32);
    });

    testWidgets('bold, italic, strikethrough, and inline code', (tester) async {
      final span = await _span(
        tester,
        _controller('**b** *i* ~~s~~ __u__ `c` plain'),
      );
      expect(_styleOf(span, 'b')?.fontWeight, FontWeight.w700);
      expect(_styleOf(span, 'i')?.fontStyle, FontStyle.italic);
      expect(_styleOf(span, 's')?.decoration, TextDecoration.lineThrough);
      expect(_styleOf(span, 'u')?.fontWeight, FontWeight.w700);
      final code = _styleOf(span, 'c');
      expect(code?.fontFamily, 'monospace');
      expect(code?.backgroundColor, _style.codeBackground);
      expect(_styleOf(span, '**'), isNotNull);
      expect(_styleOf(span, '**')?.color, _style.syntaxMarkColor);
      expect(_styleOf(span, ' plain')?.color, isNot(_style.syntaxMarkColor));
    });

    testWidgets('snake_case never reads as italic', (tester) async {
      final span = await _span(tester, _controller('use snake_case_names ok'));
      expect(_styleOf(span, 'case')?.fontStyle, isNull);
      expect(span.toPlainText(), 'use snake_case_names ok');
    });

    testWidgets('links color the text and mute the URL', (tester) async {
      final span = await _span(
        tester,
        _controller('see [the docs](https://legend.app)'),
      );
      final text = _styleOf(span, 'the docs');
      expect(text?.color, _style.linkColor);
      expect(text?.decoration, TextDecoration.underline);
      expect(_styleOf(span, 'https://legend.app')?.color, _style.syntaxMarkColor);
      expect(_styleOf(span, '[')?.color, _style.syntaxMarkColor);
    });

    testWidgets('list markers color, content stays plain', (tester) async {
      final span = await _span(tester, _controller('- one\n12. twelve'));
      expect(_styleOf(span, '- ')?.color, _style.markerColor);
      expect(_styleOf(span, '12. ')?.color, _style.markerColor);
      expect(_styleOf(span, 'one')?.color, isNot(_style.markerColor));
    });

    testWidgets('blockquotes mute the mark and color the content', (
      tester,
    ) async {
      final span = await _span(tester, _controller('> wisdom **loud**'));
      expect(_styleOf(span, '> ')?.color, _style.syntaxMarkColor);
      expect(_styleOf(span, 'wisdom ')?.color, _style.blockquoteColor);
      // Inline marks still apply inside the quote context.
      final bold = _styleOf(span, 'loud');
      expect(bold?.fontWeight, FontWeight.w700);
      expect(bold?.color, _style.blockquoteColor);
    });

    testWidgets('fence state carries across lines', (tester) async {
      final span = await _span(
        tester,
        _controller('```dart\nfinal **x**;\n```\n**after**'),
      );
      // Inside the fence, lines render mono — inline marks do not apply.
      final inside = _styleOf(span, 'final **x**;');
      expect(inside?.fontFamily, 'monospace');
      expect(inside?.backgroundColor, _style.codeBackground);
      // The delimiters are marks; the info string reads as code.
      expect(_styleOf(span, '```')?.color, _style.syntaxMarkColor);
      expect(_styleOf(span, 'dart')?.fontFamily, 'monospace');
      // After the closing fence, inline tokenization resumes.
      expect(_styleOf(span, 'after')?.fontWeight, FontWeight.w700);
    });

    testWidgets('an unclosed fence runs to the end', (tester) async {
      final span = await _span(tester, _controller('```\nstill code'));
      expect(_styleOf(span, 'still code')?.fontFamily, 'monospace');
    });

    testWidgets('the composing region gains an underline, text untouched', (
      tester,
    ) async {
      final controller = _controller('# Heading');
      controller.value = controller.value.copyWith(
        composing: const TextRange(start: 2, end: 9),
      );
      final span = await _span(tester, controller, withComposing: true);
      expect(span.toPlainText(), '# Heading');
      final composed = _styleOf(span, 'Heading');
      expect(composed?.decoration, TextDecoration.underline);
      // Styling still applies beneath the underline.
      expect(composed?.fontSize, 32);
    });
  });

  group('incremental retokenization', () {
    testWidgets('an edit retokenizes only the touched line', (tester) async {
      final controller = _controller('alpha\nbravo\ncharlie\ndelta');
      await _span(tester, controller);
      expect(controller.debugTokenizedLineCount, 4);

      controller.text = 'alpha\nBRAVO **now**\ncharlie\ndelta';
      await _span(tester, controller);
      // Prefix (alpha) and suffix (charlie, delta) reuse their cache.
      expect(controller.debugTokenizedLineCount, 5);
    });

    testWidgets('identical text never retokenizes', (tester) async {
      final controller = _controller('one\ntwo');
      await _span(tester, controller);
      await _span(tester, controller);
      expect(controller.debugTokenizedLineCount, 2);
    });

    testWidgets('opening a fence retokenizes the lines downstream', (
      tester,
    ) async {
      final controller = _controller('one\ntwo\nthree');
      await _span(tester, controller);
      expect(controller.debugTokenizedLineCount, 3);

      controller.text = '```\ntwo\nthree';
      final span = await _span(tester, controller);
      // The new fence line + both downstream lines (their entering fence
      // state flipped, so the cached suffix is unusable).
      expect(controller.debugTokenizedLineCount, 6);
      expect(_styleOf(span, 'two')?.fontFamily, 'monospace');
      expect(_styleOf(span, 'three')?.fontFamily, 'monospace');
    });

    testWidgets('an appended line leaves the prefix cached', (tester) async {
      final controller = _controller('one\ntwo');
      await _span(tester, controller);
      controller.text = 'one\ntwo\nthree';
      await _span(tester, controller);
      expect(controller.debugTokenizedLineCount, 3);
    });
  });

  group('keyboard transforms (pure)', () {
    test('Enter continues a bullet list', () {
      final next = LegendMarkdownEdits.continueList(_value('- one', 5));
      expect(next?.text, '- one\n- ');
      expect(next?.selection.baseOffset, 8);
    });

    test('Enter increments an ordered list and keeps the indent', () {
      final next = LegendMarkdownEdits.continueList(
        _value('  3. three', 10),
      );
      expect(next?.text, '  3. three\n  4. ');
      expect(next?.selection.baseOffset, 16);
    });

    test('Enter on an empty item ends the list', () {
      final next = LegendMarkdownEdits.continueList(_value('- one\n- ', 8));
      expect(next?.text, '- one\n');
      expect(next?.selection.baseOffset, 6);
    });

    test('Enter mid-item carries the tail onto the new item', () {
      final next = LegendMarkdownEdits.continueList(_value('- one two', 5));
      expect(next?.text, '- one\n-  two');
      expect(next?.selection.baseOffset, 8);
    });

    test('Enter outside a list declines', () {
      expect(LegendMarkdownEdits.continueList(_value('plain', 5)), isNull);
      expect(
        LegendMarkdownEdits.continueList(_value('- one', 1)),
        isNull,
        reason: 'inside the marker itself',
      );
    });

    test('Tab indents the list item and moves the cursor with it', () {
      final next = LegendMarkdownEdits.indent(_value('- one', 5));
      expect(next?.text, '  - one');
      expect(next?.selection.baseOffset, 7);
    });

    test('Tab indents every list line the selection touches', () {
      final next = LegendMarkdownEdits.indent(
        _value('- one\n- two\nplain', 2, 8),
      );
      expect(next?.text, '  - one\n  - two\nplain');
      expect(next?.selection.baseOffset, 4);
      expect(next?.selection.extentOffset, 12);
    });

    test('Shift-Tab outdents up to two spaces', () {
      final next = LegendMarkdownEdits.outdent(_value('  - one', 7));
      expect(next?.text, '- one');
      expect(next?.selection.baseOffset, 5);
    });

    test('outdent declines when nothing changes', () {
      expect(LegendMarkdownEdits.outdent(_value('- one', 5)), isNull);
      expect(LegendMarkdownEdits.indent(_value('plain', 3)), isNull);
    });

    test('bold wraps a selection and keeps it on the content', () {
      final next = LegendMarkdownEdits.toggleInline(
        _value('make this bold', 5, 9),
        '**',
      );
      expect(next?.text, 'make **this** bold');
      expect(next?.selection.baseOffset, 7);
      expect(next?.selection.extentOffset, 11);
    });

    test('bold unwraps delimiters just outside the selection', () {
      final next = LegendMarkdownEdits.toggleInline(
        _value('make **this** bold', 7, 11),
        '**',
      );
      expect(next?.text, 'make this bold');
      expect(next?.selection.baseOffset, 5);
      expect(next?.selection.extentOffset, 9);
    });

    test('bold unwraps delimiters inside the selection', () {
      final next = LegendMarkdownEdits.toggleInline(
        _value('make **this** bold', 5, 13),
        '**',
      );
      expect(next?.text, 'make this bold');
      expect(next?.selection.baseOffset, 5);
      expect(next?.selection.extentOffset, 9);
    });

    test('a collapsed cursor inserts an empty pair, then removes it', () {
      final inserted = LegendMarkdownEdits.toggleInline(_value('ab', 1), '**');
      expect(inserted?.text, 'a****b');
      expect(inserted?.selection.baseOffset, 3);
      final removed = LegendMarkdownEdits.toggleInline(inserted!, '**');
      expect(removed?.text, 'ab');
      expect(removed?.selection.baseOffset, 1);
    });

    test('italic never steals half of a bold delimiter', () {
      final next = LegendMarkdownEdits.toggleInline(
        _value('**bold**', 2, 6),
        '*',
      );
      // Wraps instead of corrupting the `**` marks.
      expect(next?.text, '***bold***');
      expect(next?.selection.baseOffset, 3);
      expect(next?.selection.extentOffset, 7);
    });

    test('italic wraps and unwraps cleanly on plain text', () {
      final wrapped = LegendMarkdownEdits.toggleInline(
        _value('say word now', 4, 8),
        '*',
      );
      expect(wrapped?.text, 'say *word* now');
      final unwrapped = LegendMarkdownEdits.toggleInline(wrapped!, '*');
      expect(unwrapped?.text, 'say word now');
      expect(unwrapped?.selection.baseOffset, 4);
      expect(unwrapped?.selection.extentOffset, 8);
    });
  });

  group('the editor widget', () {
    testWidgets('typing edits the plain source and reports changes', (
      tester,
    ) async {
      final controller = _controller('');
      final changes = <String>[];
      await tester.pumpWidget(
        _wrap(
          LegendMarkdownEditor(controller: controller, onChanged: changes.add),
        ),
      );
      const source = '# Hello\n\n**World** `code`';
      await tester.enterText(find.byType(EditableText), source);
      expect(controller.text, source);
      expect(changes.last, source);
      // Styling never mutated the value.
      final span = await _span(tester, controller);
      expect(span.toPlainText(), source);
    });

    testWidgets('the placeholder shows only while empty', (tester) async {
      final controller = _controller('');
      await tester.pumpWidget(
        _wrap(
          LegendMarkdownEditor(controller: controller, placeholder: 'Write…'),
        ),
      );
      expect(find.text('Write…'), findsOne);
      await tester.enterText(find.byType(EditableText), 'text');
      await tester.pump();
      expect(find.text('Write…'), findsNothing);
    });

    testWidgets('Enter continues the list through the keyboard', (
      tester,
    ) async {
      final controller = _controller('- one');
      await tester.pumpWidget(
        _wrap(LegendMarkdownEditor(controller: controller)),
      );
      await tester.showKeyboard(find.byType(EditableText));
      controller.selection = const TextSelection.collapsed(offset: 5);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(controller.text, '- one\n- ');
      expect(controller.selection.baseOffset, 8);
    });

    testWidgets('Tab and Shift-Tab indent and outdent through the keyboard', (
      tester,
    ) async {
      final controller = _controller('- one');
      await tester.pumpWidget(
        _wrap(LegendMarkdownEditor(controller: controller)),
      );
      await tester.showKeyboard(find.byType(EditableText));
      controller.selection = const TextSelection.collapsed(offset: 5);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(controller.text, '  - one');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(controller.text, '- one');
    });

    testWidgets('Cmd+B and Cmd+I toggle the delimiters', (tester) async {
      final controller = _controller('make this bold');
      await tester.pumpWidget(
        _wrap(LegendMarkdownEditor(controller: controller)),
      );
      await tester.showKeyboard(find.byType(EditableText));
      controller.selection = const TextSelection(
        baseOffset: 5,
        extentOffset: 9,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      expect(controller.text, 'make **this** bold');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(controller.text, 'make ***this*** bold');
    });

    testWidgets('readOnly declines the conveniences', (tester) async {
      final controller = _controller('- one');
      await tester.pumpWidget(
        _wrap(LegendMarkdownEditor(controller: controller, readOnly: true)),
      );
      await tester.showKeyboard(find.byType(EditableText));
      controller.selection = const TextSelection.collapsed(offset: 5);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(controller.text, '- one');
    });
  });

  group('custom syntax registry, one registration, two consumers', () {
    testWidgets('the highlight rule styles the raw source in the editor', (
      tester,
    ) async {
      final controller = _controller(
        'Per @[ref:GDPR-6] processing is lawful.',
        syntaxes: [_lawRef()],
      );
      final span = await _span(tester, controller);
      // The raw notation stays in the source, styled.
      expect(span.toPlainText(), 'Per @[ref:GDPR-6] processing is lawful.');
      final highlighted = _styleOf(span, '@[ref:GDPR-6]');
      expect(highlighted?.color, _style.linkColor);
      expect(highlighted?.fontWeight, FontWeight.w700);
    });

    testWidgets('the same registration renders in LegendMarkdown', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LegendMarkdown(
            'Per @[ref:GDPR-6] processing is lawful.',
            syntaxes: [_lawRef()],
          ),
        ),
      );
      expect(find.textContaining('§ GDPR-6', findRichText: true), findsOne);
      expect(find.textContaining('@[ref:', findRichText: true), findsNothing);
    });
  });

  group('theming ladder', () {
    const navy = Color(0xFF001F54);
    const lime = Color(0xFF32CD32);

    testWidgets('level 4: defaults derive from tokens', (tester) async {
      final controller = _controller('# x');
      await tester.pumpWidget(
        _wrap(LegendMarkdownEditor(controller: controller)),
      );
      const tokens = LegendTokens.light;
      expect(
        controller.sourceStyle.syntaxMarkColor,
        tokens.colors.foreground3,
      );
      expect(
        controller.sourceStyle.h1Style?.fontSize,
        tokens.typography.h1.fontSize,
      );
      expect(controller.sourceStyle.linkColor, tokens.colors.primary);
    });

    testWidgets('level 3: a components-map entry recolors the marks', (
      tester,
    ) async {
      final controller = _controller('# x');
      await tester.pumpWidget(
        _wrap(
          LegendMarkdownEditor(controller: controller),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendMarkdownEditor: LegendMarkdownEditorThemeNullable(
                syntaxMarkColor: navy,
              ),
            },
          ),
        ),
      );
      expect(controller.sourceStyle.syntaxMarkColor, navy);
    });

    testWidgets('level 2: a subtree override wins over the registry', (
      tester,
    ) async {
      final controller = _controller('# x');
      await tester.pumpWidget(
        _wrap(
          LegendMarkdownEditorThemeOverride(
            data: const LegendMarkdownEditorThemeNullable(
              syntaxMarkColor: lime,
            ),
            child: LegendMarkdownEditor(controller: controller),
          ),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendMarkdownEditor: LegendMarkdownEditorThemeNullable(
                syntaxMarkColor: navy,
              ),
            },
          ),
        ),
      );
      expect(controller.sourceStyle.syntaxMarkColor, lime);
    });

    testWidgets('level 1: the constructor param wins over everything', (
      tester,
    ) async {
      final controller = _controller('# x');
      await tester.pumpWidget(
        _wrap(
          LegendMarkdownEditor(controller: controller, syntaxMarkColor: lime),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendMarkdownEditor: LegendMarkdownEditorThemeNullable(
                syntaxMarkColor: navy,
              ),
            },
          ),
        ),
      );
      expect(controller.sourceStyle.syntaxMarkColor, lime);
    });
  });

  group('field-core plumbing (RFC-005 §3.4)', () {
    testWidgets('the editor configures a growing multiline EditableText', (
      tester,
    ) async {
      final controller = _controller('');
      await tester.pumpWidget(
        _wrap(LegendMarkdownEditor(controller: controller, minLines: 3)),
      );
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.maxLines, isNull);
      expect(editable.minLines, 3);
      expect(editable.keyboardType, TextInputType.multiline);
      expect(editable.textInputAction, TextInputAction.newline);
      expect(editable.controller, controller);
    });
  });
}
