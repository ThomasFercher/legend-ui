import 'dart:ui' show Tristate;
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child) {
  return LegendTheme(
    data: const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

/// Overlay harness for anchored-overlay components: `TapRegionSurface`
/// (WidgetsApp installs it in real apps; dismissal depends on it) plus a
/// hit-testable backdrop so outside taps reach *something*.
Widget _overlayApp(Widget child) {
  return LegendTheme(
    data: const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: TapRegionSurface(
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: Center(child: child),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('LegendDivider', () {
    testWidgets('horizontal renders themed thickness and spacing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const SizedBox(width: 200, child: LegendDivider())),
      );
      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(LegendDivider),
          matching: find.byType(SizedBox),
        ),
      );
      expect(box.height, LegendTokens.light.sizes.borderWidth);
      expect(box.width, double.infinity);

      // .first: LegendSurface's Container contributes an inner zero Padding.
      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(LegendDivider),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding,
        EdgeInsets.symmetric(vertical: LegendTokens.light.sizes.md),
      );
    });

    testWidgets('vertical swaps the axes', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            height: 100,
            child: LegendDivider(axis: Axis.vertical, thickness: 3),
          ),
        ),
      );
      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(LegendDivider),
          matching: find.byType(SizedBox),
        ),
      );
      expect(box.width, 3);
      expect(box.height, double.infinity);

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(LegendDivider),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding,
        EdgeInsets.symmetric(horizontal: LegendTokens.light.sizes.md),
      );
    });
  });

  group('LegendExpandable', () {
    testWidgets('uncontrolled: header taps expand and collapse', (
      tester,
    ) async {
      final toggles = <bool>[];
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 300,
            child: LegendExpandable(
              title: 'More',
              onToggle: toggles.add,
              child: const Text('Body'),
            ),
          ),
        ),
      );
      expect(find.text('Body'), findsNothing);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsOneWidget);
      expect(toggles, [true]);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
      expect(toggles, [true, false]);
    });

    testWidgets('controlled: renders the given state, taps only report', (
      tester,
    ) async {
      var expanded = false;
      late StateSetter setOuter;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return LegendExpandable(
                  title: 'More',
                  expanded: expanded,
                  // Owner ignores the request on purpose first.
                  onToggle: (_) {},
                  child: const Text('Body'),
                );
              },
            ),
          ),
        ),
      );
      // A tap alone must not expand a controlled widget.
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);

      setOuter(() => expanded = true);
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsOneWidget);

      setOuter(() => expanded = false);
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
    });

    testWidgets('themes the title style and caret color', (tester) async {
      const coral = Color(0xFFFF6B57);
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 300,
            child: LegendExpandable(
              title: 'More',
              titleStyle: const TextStyle(color: coral),
              caretColor: navy,
              child: const Text('Body'),
            ),
          ),
        ),
      );
      expect(tester.widget<Text>(find.text('More')).style?.color, coral);
      expect(tester.widget<LegendCaret>(find.byType(LegendCaret)).color, navy);
    });

    testWidgets('header announces its expanded state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 300,
            child: LegendExpandable(title: 'More', child: const Text('Body')),
          ),
        ),
      );
      // The expanded flag lives on the announced button node — the inner
      // focus node getSemantics finds first merges up into it.
      SemanticsFlags header() {
        var node = tester.getSemantics(find.text('More'));
        while (!node.getSemanticsData().flagsCollection.isButton) {
          node = node.parent!;
        }
        return node.getSemanticsData().flagsCollection;
      }

      expect(header().isExpanded, Tristate.isFalse);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(header().isExpanded, Tristate.isTrue);
      handle.dispose();
    });
  });

  group('LegendInfoItem', () {
    testWidgets('shows label, value and slot widgets with themed styles', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 300,
            child: LegendInfoItem(
              label: 'Network',
              value: 'Mainnet',
              leading: Text('L'),
              trailing: Text('T'),
            ),
          ),
        ),
      );
      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Mainnet'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
      expect(find.text('T'), findsOneWidget);

      final label = tester.widget<Text>(find.text('Network'));
      final value = tester.widget<Text>(find.text('Mainnet'));
      expect(label.style?.fontSize, LegendTokens.light.typography.b3.fontSize);
      expect(label.style?.color, LegendTokens.light.colors.foreground2);
      expect(value.style?.fontSize, LegendTokens.light.typography.b2.fontSize);
    });
  });

  group('LegendContextMenu', () {
    Widget menuApp({required List<LegendContextMenuEntry> entries}) {
      return _overlayApp(
        LegendContextMenu(
          entries: entries,
          child: const SizedBox(width: 120, height: 60, child: Text('Area')),
        ),
      );
    }

    testWidgets('long-press opens, selecting fires callback and closes', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        menuApp(
          entries: [
            LegendContextMenuEntry(
              label: 'Copy',
              onSelected: () => picked = 'copy',
            ),
            LegendContextMenuEntry(
              label: 'Delete',
              onSelected: () => picked = 'delete',
            ),
          ],
        ),
      );
      expect(find.text('Copy'), findsNothing);

      await tester.longPress(find.text('Area'));
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(picked, 'copy');
      expect(find.text('Copy'), findsNothing);
    });

    testWidgets('secondary tap opens, outside tap dismisses', (tester) async {
      await tester.pumpWidget(
        menuApp(
          entries: [LegendContextMenuEntry(label: 'Copy', onSelected: () {})],
        ),
      );
      await tester.tap(find.text('Area'), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsNothing);
    });
  });
}
