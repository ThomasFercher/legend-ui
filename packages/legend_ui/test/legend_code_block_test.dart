import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _colors = LegendColors.light;

Widget _wrap(Widget child, {LegendThemeData? data}) {
  return LegendTheme(
    data: data ?? const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

/// The panel's fill, read off the [LegendSurface]'s container.
Color _fill(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(LegendCodeBlock),
          matching: find.byType(Container),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color!;
}

/// Captures every `Clipboard.setData` payload the widget writes.
List<String> _mockClipboard(WidgetTester tester) {
  final writes = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = call.arguments as Map<Object?, Object?>;
        writes.add(args['text']! as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return writes;
}

void main() {
  group('LegendCodeBlock — rendering', () {
    testWidgets('renders the code in the mono style with a language label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendCodeBlock('final x = 1;', language: 'dart')),
      );
      expect(find.text('final x = 1;'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
      final text = tester.widget<Text>(find.text('final x = 1;'));
      expect(text.style!.fontFamily, 'monospace');
      // The panel rests on the background2 token, like markdown's fences.
      expect(_fill(tester), _colors.background2);
      // Long lines scroll horizontally inside the panel.
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scroll.scrollDirection, Axis.horizontal);
    });

    testWidgets('language label and copy affordance are both optional', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendCodeBlock('x', showCopyButton: false)),
      );
      // No header at all: no interactive control, no label row.
      expect(find.byType(LegendInteractive), findsNothing);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('maxHeight bounds the panel and adds a vertical scroll', (
      tester,
    ) async {
      final tallCode = List.generate(60, (i) => 'line $i').join('\n');
      await tester.pumpWidget(_wrap(LegendCodeBlock(tallCode, maxHeight: 120)));
      final vertical = tester.widgetList<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(
        vertical.map((s) => s.scrollDirection),
        containsAll([Axis.vertical, Axis.horizontal]),
      );
      const tokens = LegendTokens.light;
      final size = tester.getSize(find.byType(LegendCodeBlock));
      // Header + paddings on top of the bounded code viewport — well under
      // the unbounded 60-line height either way.
      expect(size.height, lessThan(120 + tokens.sizes.md * 2 + 40));

      // Without maxHeight there is no vertical scrollable.
      await tester.pumpWidget(_wrap(const LegendCodeBlock('a\nb\nc')));
      expect(
        tester
            .widgetList<SingleChildScrollView>(
              find.byType(SingleChildScrollView),
            )
            .map((s) => s.scrollDirection),
        isNot(contains(Axis.vertical)),
      );
    });

    testWidgets('highlighter builds the spans instead of plain text', (
      tester,
    ) async {
      const accent = Color(0xFF123456);
      await tester.pumpWidget(
        _wrap(
          LegendCodeBlock(
            'final x = 1;',
            highlighter: (code) => [
              const TextSpan(
                text: 'final',
                style: TextStyle(color: accent),
              ),
              TextSpan(text: code.substring('final'.length)),
            ],
          ),
        ),
      );
      expect(find.text('final x = 1;', findRichText: true), findsOneWidget);
      var found = false;
      tester.widget<Text>(find.byType(Text).first).textSpan!.visitChildren((
        span,
      ) {
        if (span is TextSpan && span.text == 'final') {
          expect(span.style!.color, accent);
          found = true;
          return false;
        }
        return true;
      });
      expect(found, isTrue);
    });
  });

  group('LegendCodeBlock — copy affordance', () {
    testWidgets(
      'tap writes the full code to the clipboard and shows the transient '
      'copied feedback',
      (tester) async {
        final writes = _mockClipboard(tester);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _wrap(const LegendCodeBlock('final x = 1;\nfinal y = 2;')),
        );
        expect(find.bySemanticsLabel('Copy code'), findsOneWidget);

        await tester.tap(find.byType(LegendInteractive));
        await tester.pump();
        expect(writes, ['final x = 1;\nfinal y = 2;']);
        expect(find.bySemanticsLabel('Copied'), findsOneWidget);
        expect(find.bySemanticsLabel('Copy code'), findsNothing);

        // The feedback is transient — the affordance rests again after
        // ~1.5 s.
        await tester.pump(const Duration(seconds: 2));
        expect(find.bySemanticsLabel('Copy code'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('copying again while copied restarts the feedback window', (
      tester,
    ) async {
      _mockClipboard(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const LegendCodeBlock('x')));
      await tester.tap(find.byType(LegendInteractive));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byType(LegendInteractive));
      // One second into the second window the feedback still shows...
      await tester.pump(const Duration(seconds: 1));
      expect(find.bySemanticsLabel('Copied'), findsOneWidget);
      // ...and it clears once that window elapses.
      await tester.pump(const Duration(seconds: 1));
      expect(find.bySemanticsLabel('Copy code'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('copy labels are overridable', (tester) async {
      _mockClipboard(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const LegendCodeBlock(
            'x',
            copyLabel: 'Code kopieren',
            copiedLabel: 'Kopiert',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Code kopieren'), findsOneWidget);
      await tester.tap(find.byType(LegendInteractive));
      await tester.pump();
      expect(find.bySemanticsLabel('Kopiert'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      semantics.dispose();
    });
  });

  group('LegendCodeBlock — theming', () {
    testWidgets('constructor param wins over every theme level', (
      tester,
    ) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(const LegendCodeBlock('x', background: navy)),
      );
      expect(_fill(tester), navy);
    });

    testWidgets('level-3 registry override restyles the panel', (tester) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          const LegendCodeBlock('x'),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendCodeBlock: LegendCodeBlockThemeNullable(background: navy),
            },
          ),
        ),
      );
      expect(_fill(tester), navy);
    });
  });
}
