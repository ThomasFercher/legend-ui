import 'dart:ui' show Tristate;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child, {LegendThemeData? data}) {
  return LegendTheme(
    data: data ?? const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 400, child: child)),
    ),
  );
}

const _items = [
  LegendAccordionItem(title: 'One', child: Text('Body one')),
  LegendAccordionItem(title: 'Two', child: Text('Body two')),
  LegendAccordionItem(title: 'Three', child: Text('Body three')),
];

void main() {
  group('single-open mode', () {
    testWidgets('expanding a section collapses the open one', (tester) async {
      final changes = <Set<int>>[];
      await tester.pumpWidget(
        _wrap(LegendAccordion(items: _items, onChanged: changes.add)),
      );
      expect(find.text('Body one'), findsNothing);

      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      expect(find.text('Body one'), findsOneWidget);

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(find.text('Body one'), findsNothing);
      expect(find.text('Body two'), findsOneWidget);
      expect(changes, [
        {0},
        {1},
      ]);
    });

    testWidgets('tapping the open section collapses it', (tester) async {
      final changes = <Set<int>>[];
      await tester.pumpWidget(
        _wrap(
          LegendAccordion(
            items: _items,
            initiallyExpanded: const {0},
            onChanged: changes.add,
          ),
        ),
      );
      expect(find.text('Body one'), findsOneWidget);

      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      expect(find.text('Body one'), findsNothing);
      expect(changes, [<int>{}]);
    });
  });

  group('multi-open mode', () {
    testWidgets('allowMultiple keeps several sections open', (tester) async {
      final changes = <Set<int>>[];
      await tester.pumpWidget(
        _wrap(
          LegendAccordion(
            items: _items,
            allowMultiple: true,
            onChanged: changes.add,
          ),
        ),
      );

      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Three'));
      await tester.pumpAndSettle();
      expect(find.text('Body one'), findsOneWidget);
      expect(find.text('Body three'), findsOneWidget);

      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      expect(find.text('Body one'), findsNothing);
      expect(find.text('Body three'), findsOneWidget);
      expect(changes, [
        {0},
        {0, 2},
        {2},
      ]);
    });
  });

  group('controlled mode', () {
    testWidgets('renders the given set; taps only report', (tester) async {
      final changes = <Set<int>>[];
      var expanded = const <int>{0};
      late StateSetter setOuter;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return LegendAccordion(
                items: _items,
                expandedIndices: expanded,
                onChanged: changes.add,
              );
            },
          ),
        ),
      );
      expect(find.text('Body one'), findsOneWidget);

      // A tap alone must not move a controlled accordion.
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(find.text('Body one'), findsOneWidget);
      expect(find.text('Body two'), findsNothing);
      expect(changes, [
        {1},
      ]);

      setOuter(() => expanded = const {1});
      await tester.pumpAndSettle();
      expect(find.text('Body one'), findsNothing);
      expect(find.text('Body two'), findsOneWidget);
    });
  });

  group('keyboard and semantics', () {
    testWidgets('Enter and Space toggle the focused header', (tester) async {
      await tester.pumpWidget(_wrap(LegendAccordion(items: _items)));

      Focus.of(tester.element(find.text('One'))).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Body one'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('Body one'), findsNothing);
    });

    testWidgets('headers announce their expanded/collapsed state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(LegendAccordion(items: _items)));

      // The expanded flag lives on the announced button node — the inner
      // focus node getSemantics finds first merges up into it.
      SemanticsFlags header() {
        var node = tester.getSemantics(find.text('One'));
        while (!node.getSemanticsData().flagsCollection.isButton) {
          node = node.parent!;
        }
        return node.getSemanticsData().flagsCollection;
      }

      expect(header().isExpanded, Tristate.isFalse);

      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      expect(header().isExpanded, Tristate.isTrue);
      handle.dispose();
    });
  });

  group('theming', () {
    testWidgets('renders dividers between sections in the themed color', (
      tester,
    ) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          LegendAccordion(items: _items),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendAccordion: LegendAccordionThemeNullable(dividerColor: navy),
            },
          ),
        ),
      );
      final dividers = tester
          .widgetList<LegendDivider>(find.byType(LegendDivider))
          .toList();
      expect(dividers, hasLength(_items.length - 1));
      expect(dividers.map((divider) => divider.color), everyElement(navy));
    });

    testWidgets('header style and caret color reach every section', (
      tester,
    ) async {
      const coral = Color(0xFFFF6B57);
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          LegendAccordion(
            items: _items,
            headerStyle: const TextStyle(color: coral),
            caretColor: navy,
          ),
        ),
      );
      final title = tester.widget<Text>(find.text('Two'));
      expect(title.style?.color, coral);
      final carets = tester.widgetList<LegendCaret>(find.byType(LegendCaret));
      expect(carets.map((caret) => caret.color), everyElement(navy));
    });

    testWidgets('a level-3 background override tints the sections', (
      tester,
    ) async {
      const mint = Color(0xFFD1FAE5);
      await tester.pumpWidget(
        _wrap(
          LegendAccordion(items: _items),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendAccordion: LegendAccordionThemeNullable(
                background: InteractiveColors(normal: mint),
              ),
            },
          ),
        ),
      );
      final expandable = tester.widget<LegendExpandable>(
        find.byType(LegendExpandable).first,
      );
      expect(expandable.backgroundColor, isNull);
      // The accordion pushes its resolved background to the sections
      // through the subtree override, not constructor params — assert on
      // the injected override data.
      final override = tester.widget<LegendExpandableThemeOverride>(
        find.byType(LegendExpandableThemeOverride),
      );
      expect(override.data.backgroundColor?.normal, mint);
    });
  });
}
