import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child) {
  return LegendTheme(
    data: const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

const _leafA = LegendNavItem(label: 'Overview');
const _child1 = LegendNavItem(label: 'Balances');
const _child2 = LegendNavItem(label: 'History');
const _section = LegendNavItem(label: 'Wallet', children: [_child1, _child2]);

void main() {
  group('LegendVerticalMenu', () {
    testWidgets('leaf activation reports the item; parents do not select', (
      tester,
    ) async {
      final selections = <LegendNavItem>[];
      await tester.pumpWidget(
        _wrap(
          LegendVerticalMenu(
            items: const [_leafA, _section],
            onSelected: selections.add,
          ),
        ),
      );

      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();
      expect(selections, [_leafA]);
    });

    testWidgets('a section expands and collapses on tap without a post-frame '
        'callback (legacy nomo_vertical_tile setState-storm regression)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(LegendVerticalMenu(items: const [_section], onSelected: (_) {})),
      );

      // Collapsed initially: children not laid out.
      expect(find.text('Balances'), findsNothing);

      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();
      expect(find.text('Balances'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();
      expect(find.text('Balances'), findsNothing);

      // The whole sequence must settle with no pending timers/frames — a
      // post-frame reveal storm (legacy) would leave pumpAndSettle unable to
      // reach a steady state or throw a pending-timer error.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a selected leaf inside an expanded section fires onSelected', (
      tester,
    ) async {
      final selections = <LegendNavItem>[];
      await tester.pumpWidget(
        _wrap(
          LegendVerticalMenu(
            items: const [_section],
            selected: _child1,
            initiallyExpanded: const {_section},
            onSelected: selections.add,
          ),
        ),
      );

      expect(find.text('Balances'), findsOneWidget);
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(selections, [_child2]);
    });

    testWidgets('selected row uses the themed selected foreground color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LegendVerticalMenu(
            items: const [_leafA, _child1],
            selected: _leafA,
            onSelected: (_) {},
          ),
        ),
      );
      final selectedLabel = tester.widget<Text>(find.text('Overview'));
      final unselectedLabel = tester.widget<Text>(find.text('Balances'));
      expect(selectedLabel.style?.color, LegendTokens.light.colors.primary);
      expect(
        unselectedLabel.style?.color,
        LegendTokens.light.colors.foreground2,
      );
    });

    testWidgets('initiallyExpanded opens the named sections up front', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LegendVerticalMenu(
            items: const [_section],
            initiallyExpanded: const {_section},
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.text('Balances'), findsOneWidget);
    });
  });
}
