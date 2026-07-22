import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return LegendApp(
    theme: const LegendThemeData(tokens: LegendTokens.light),
    home: Directionality(
      textDirection: direction,
      child: Center(child: child),
    ),
  );
}

/// The button surface (the AnimatedContainer inside `LegendSurface`) that
/// paints the given page number.
BoxDecoration _numberDecoration(WidgetTester tester, String label) {
  final container = tester.widget<AnimatedContainer>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('windowing', () {
    /// The rendered slot labels, visual order — numbers and '…' gaps.
    List<String> shown(WidgetTester tester) => [
      for (final text in tester.widgetList<Text>(find.byType(Text))) text.data!,
    ];

    testWidgets('a short range shows every page, no ellipsis', (tester) async {
      await tester.pumpWidget(
        _app(LegendPagination(page: 3, pageCount: 7, onChanged: (_) {})),
      );
      expect(shown(tester), ['1', '2', '3', '4', '5', '6', '7']);
    });

    testWidgets('the middle collapses both sides: 1 … 4 5 6 … 20', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(LegendPagination(page: 5, pageCount: 20, onChanged: (_) {})),
      );
      expect(shown(tester), ['1', '…', '4', '5', '6', '…', '20']);
    });

    testWidgets('near the start the leading run absorbs the window', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(LegendPagination(page: 2, pageCount: 20, onChanged: (_) {})),
      );
      expect(shown(tester), ['1', '2', '3', '4', '5', '…', '20']);
    });

    testWidgets('near the end the trailing run does', (tester) async {
      await tester.pumpWidget(
        _app(LegendPagination(page: 18, pageCount: 20, onChanged: (_) {})),
      );
      expect(shown(tester), ['1', '…', '16', '17', '18', '19', '20']);
    });

    testWidgets('maxVisible widens the window', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendPagination(
            page: 10,
            pageCount: 20,
            maxVisible: 9,
            onChanged: (_) {},
          ),
        ),
      );
      expect(shown(tester), ['1', '…', '8', '9', '10', '11', '12', '…', '20']);
    });
  });

  group('activation', () {
    testWidgets('tapping a number reports it; tapping the current page '
        'reports nothing', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        _app(LegendPagination(page: 3, pageCount: 7, onChanged: changes.add)),
      );

      await tester.tap(find.text('5'));
      expect(changes, [5]);

      await tester.tap(find.text('3'));
      expect(changes, [5]);
    });

    testWidgets('the chevrons step one page and disable at the ends', (
      tester,
    ) async {
      final changes = <int>[];
      Widget build(int page) => _app(
        LegendPagination(page: page, pageCount: 3, onChanged: changes.add),
      );

      await tester.pumpWidget(build(2));
      await tester.tap(find.bySemanticsLabel('Previous page'));
      expect(changes, [1]);
      await tester.tap(find.bySemanticsLabel('Next page'));
      expect(changes, [1, 3]);

      // At the first page the previous chevron is inert...
      changes.clear();
      await tester.pumpWidget(build(1));
      await tester.tap(
        find.bySemanticsLabel('Previous page'),
        warnIfMissed: false,
      );
      expect(changes, isEmpty);

      // ...and at the last page the next chevron is.
      await tester.pumpWidget(build(3));
      await tester.tap(find.bySemanticsLabel('Next page'), warnIfMissed: false);
      expect(changes, isEmpty);
    });

    testWidgets('a single-page range disables both chevrons', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(LegendPagination(page: 1, pageCount: 1, onChanged: (_) {})),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Previous page')),
        containsSemantics(isEnabled: false),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Next page')),
        containsSemantics(isEnabled: false),
      );
      handle.dispose();
    });
  });

  group('keyboard', () {
    testWidgets('standard focus traversal reaches the buttons and '
        'Enter/Space activate them', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        _app(LegendPagination(page: 2, pageCount: 3, onChanged: changes.add)),
      );

      // Tab order: previous chevron, then the page numbers.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(changes, [1]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(changes, [1, 1]);
    });
  });

  group('semantics', () {
    testWidgets('the current page announces selected; the row carries its '
        'label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          LegendPagination(
            page: 2,
            pageCount: 3,
            semanticLabel: 'Transaction pages',
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('2')),
        containsSemantics(isSelected: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.text('1')),
        containsSemantics(isSelected: false),
      );
      expect(
        tester.getSemantics(find.byType(LegendPagination)),
        containsSemantics(label: 'Transaction pages'),
      );
      handle.dispose();
    });
  });

  testWidgets('the chevrons mirror under RTL — previous points visually '
      'right', (tester) async {
    Widget build(TextDirection direction) => _app(
      LegendPagination(page: 2, pageCount: 3, onChanged: (_) {}),
      direction: direction,
    );

    await tester.pumpWidget(build(TextDirection.ltr));
    var turns = [
      for (final box in tester.widgetList<RotatedBox>(find.byType(RotatedBox)))
        box.quarterTurns,
    ];
    expect(turns, [1, 3]);

    await tester.pumpWidget(build(TextDirection.rtl));
    turns = [
      for (final box in tester.widgetList<RotatedBox>(find.byType(RotatedBox)))
        box.quarterTurns,
    ];
    expect(turns, [3, 1]);
  });

  group('theme resolution', () {
    const navy = Color(0xFF001F54);
    const coral = Color(0xFFFF6B5B);

    testWidgets('the current page paints the selected fill; unselected '
        'buttons stay transparent', (tester) async {
      await tester.pumpWidget(
        _app(LegendPagination(page: 2, pageCount: 3, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();

      const tokens = LegendTokens.light;
      expect(_numberDecoration(tester, '2').color, tokens.colors.primary);
      expect(_numberDecoration(tester, '1').color, isNull);
      expect(
        tester.widget<Text>(find.text('2')).style!.color,
        tokens.colors.onPrimary,
      );
      expect(
        tester.widget<Text>(find.text('1')).style!.color,
        tokens.colors.foreground2,
      );
    });

    testWidgets('a registry entry restyles the selected fill (level 3)', (
      tester,
    ) async {
      await tester.pumpWidget(
        LegendApp(
          theme: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendPagination: LegendPaginationThemeNullable(
                selectedFill: InteractiveColors(normal: navy),
              ),
            },
          ),
          home: Center(
            child: LegendPagination(page: 2, pageCount: 3, onChanged: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_numberDecoration(tester, '2').color, navy);
    });

    testWidgets('the selectedFill param lifts into the per-state normal '
        'member and wins over the registry (level 1)', (tester) async {
      await tester.pumpWidget(
        LegendApp(
          theme: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendPagination: LegendPaginationThemeNullable(
                selectedFill: InteractiveColors(normal: navy),
              ),
            },
          ),
          home: Center(
            child: LegendPagination(
              page: 2,
              pageCount: 3,
              selectedFill: coral,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_numberDecoration(tester, '2').color, coral);
    });
  });
}
