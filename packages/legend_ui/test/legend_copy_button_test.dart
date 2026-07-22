import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child, {Map<Type, Object> components = const {}}) {
  return LegendTheme(
    data: LegendThemeData(tokens: LegendTokens.light, components: components),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

/// Captures `Clipboard.setData` writes; returns the captured text values.
List<String> _mockClipboard(WidgetTester tester) {
  final written = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = call.arguments as Map<Object?, Object?>;
        written.add(args['text']! as String);
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
  return written;
}

/// The glyph's [CustomPaint] inside the button.
Finder _paint() => find.descendant(
  of: find.byType(LegendCopyButton),
  matching: find.byType(CustomPaint),
);

String _painterName(WidgetTester tester) =>
    tester.widget<CustomPaint>(_paint()).painter!.runtimeType.toString();

void main() {
  group('LegendCopyButton — behavior', () {
    testWidgets('tap writes the value to the clipboard and fires onCopied', (
      tester,
    ) async {
      final written = _mockClipboard(tester);
      var copied = 0;
      await tester.pumpWidget(
        _wrap(LegendCopyButton(value: '0xDEADBEEF', onCopied: () => copied++)),
      );
      await tester.tap(find.byType(LegendCopyButton));
      await tester.pump();

      expect(written, ['0xDEADBEEF']);
      expect(copied, 1);
      // Let the confirmation revert so no timer outlives the test.
      await tester.pump(const Duration(milliseconds: 1600));
    });

    testWidgets('confirmation swaps to the check glyph, then reverts', (
      tester,
    ) async {
      _mockClipboard(tester);
      await tester.pumpWidget(_wrap(const LegendCopyButton(value: 'x')));
      expect(_painterName(tester), '_CopyPainter');

      await tester.tap(find.byType(LegendCopyButton));
      await tester.pump();
      expect(_painterName(tester), '_CheckPainter');

      // Just before the default 1500 ms the check still shows...
      await tester.pump(const Duration(milliseconds: 1400));
      expect(_painterName(tester), '_CheckPainter');
      // ...and just after it the copy glyph is back.
      await tester.pump(const Duration(milliseconds: 200));
      expect(_painterName(tester), '_CopyPainter');
    });

    testWidgets('the copy is announced through a live region', (tester) async {
      final semantics = tester.ensureSemantics();
      _mockClipboard(tester);
      await tester.pumpWidget(_wrap(const LegendCopyButton(value: 'x')));
      expect(find.bySemanticsLabel('Copied'), findsNothing);

      await tester.tap(find.byType(LegendCopyButton));
      await tester.pump();
      expect(find.bySemanticsLabel('Copied'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.bySemanticsLabel('Copied'), findsNothing);
      semantics.dispose();
    });

    testWidgets('custom labels and confirmation duration are honored', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      _mockClipboard(tester);
      await tester.pumpWidget(
        _wrap(
          const LegendCopyButton(
            value: 'x',
            semanticLabel: 'Adresse kopieren',
            copiedLabel: 'Kopiert',
            confirmationDuration: Duration(milliseconds: 300),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Adresse kopieren'), findsOneWidget);

      await tester.tap(find.byType(LegendCopyButton));
      await tester.pump();
      expect(find.bySemanticsLabel('Kopiert'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.bySemanticsLabel('Kopiert'), findsNothing);
      semantics.dispose();
    });

    testWidgets('disabled button copies nothing', (tester) async {
      final written = _mockClipboard(tester);
      await tester.pumpWidget(
        _wrap(const LegendCopyButton(value: 'x', enabled: false)),
      );
      await tester.tap(find.byType(LegendCopyButton));
      await tester.pump();

      expect(written, isEmpty);
      expect(_painterName(tester), '_CopyPainter');
    });
  });

  group('LegendCopyButton — theming', () {
    testWidgets('glyph size resolves token default → registry → param', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendCopyButton(value: 'x')));
      expect(
        tester.getSize(_paint()),
        Size.square(LegendTokens.light.sizes.iconSm),
      );

      await tester.pumpWidget(
        _wrap(
          const LegendCopyButton(value: 'x'),
          components: {
            LegendCopyButton: const LegendCopyButtonThemeNullable(
              glyphSize: 24,
            ),
          },
        ),
      );
      expect(tester.getSize(_paint()), const Size(24, 24));

      await tester.pumpWidget(
        _wrap(
          const LegendCopyButton(value: 'x', glyphSize: 30),
          components: {
            LegendCopyButton: const LegendCopyButtonThemeNullable(
              glyphSize: 24,
            ),
          },
        ),
      );
      expect(tester.getSize(_paint()), const Size(30, 30));
    });

    testWidgets('confirmation keeps showing under a registry override', (
      tester,
    ) async {
      _mockClipboard(tester);
      await tester.pumpWidget(
        _wrap(
          const LegendCopyButton(value: 'x'),
          components: {
            LegendCopyButton: const LegendCopyButtonThemeNullable(
              confirmationColor: Color(0xFF001F54),
            ),
          },
        ),
      );
      await tester.tap(find.byType(LegendCopyButton));
      await tester.pump();
      expect(_painterName(tester), '_CheckPainter');
      await tester.pump(const Duration(milliseconds: 1600));
    });
  });
}
