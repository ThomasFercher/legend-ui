import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _items = [
  LegendNavItem(label: 'Tokens'),
  LegendNavItem(label: 'NFTs'),
  LegendNavItem(label: 'Activity'),
];

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return LegendApp(
    theme: const LegendThemeData(tokens: LegendTokens.light),
    home: Directionality(
      textDirection: direction,
      child: Center(child: child),
    ),
  );
}

/// The tab surface (the AnimatedContainer inside [LegendSurface]) that
/// paints the given label's tab.
BoxDecoration _tabDecoration(WidgetTester tester, String label) {
  final container = tester.widget<AnimatedContainer>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('renders every label and reports the tapped index', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      _app(
        LegendTabs(
          items: _items,
          selectedIndex: 0,
          onSelected: (i) => selected = i,
        ),
      ),
    );

    expect(find.text('Tokens'), findsOneWidget);
    expect(find.text('NFTs'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);

    await tester.tap(find.text('NFTs'));
    expect(selected, 1);
  });

  testWidgets('is controlled — tapping does not move the indicator until '
      'the caller rebuilds with the new index', (tester) async {
    await tester.pumpWidget(
      _app(LegendTabs(items: _items, selectedIndex: 0, onSelected: (_) {})),
    );
    await tester.tap(find.text('NFTs'));
    await tester.pumpAndSettle();

    final tokens = LegendTokens.light;
    expect(
      _tabDecoration(tester, 'Tokens').border!.bottom.color,
      tokens.colors.primary,
    );
    expect(
      _tabDecoration(tester, 'NFTs').border!.bottom.color,
      const Color(0x00000000),
    );
  });

  testWidgets('selected tab shows the indicator and the selected label '
      'color; unselected tabs do not', (tester) async {
    await tester.pumpWidget(
      _app(LegendTabs(items: _items, selectedIndex: 1, onSelected: (_) {})),
    );
    await tester.pumpAndSettle();

    final tokens = LegendTokens.light;
    expect(
      _tabDecoration(tester, 'NFTs').border!.bottom.color,
      tokens.colors.primary,
    );
    expect(
      _tabDecoration(tester, 'Tokens').border!.bottom.color,
      const Color(0x00000000),
    );
    expect(
      tester.widget<Text>(find.text('NFTs')).style!.color,
      tokens.colors.primary,
    );
    expect(
      tester.widget<Text>(find.text('Tokens')).style!.color,
      tokens.colors.foreground2,
    );
  });

  group('theme resolution', () {
    const navy = Color(0xFF001F54);
    const coral = Color(0xFFFF6B5B);

    testWidgets('a registry entry restyles the indicator (level 3)', (
      tester,
    ) async {
      await tester.pumpWidget(
        LegendApp(
          theme: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendTabs: LegendTabsThemeNullable(indicator: navy),
            },
          ),
          home: Center(
            child: LegendTabs(
              items: _items,
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_tabDecoration(tester, 'Tokens').border!.bottom.color, navy);
    });

    testWidgets('the constructor param wins over the registry (level 1)', (
      tester,
    ) async {
      await tester.pumpWidget(
        LegendApp(
          theme: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendTabs: LegendTabsThemeNullable(indicator: navy),
            },
          ),
          home: Center(
            child: LegendTabs(
              items: _items,
              selectedIndex: 0,
              onSelected: (_) {},
              indicator: coral,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_tabDecoration(tester, 'Tokens').border!.bottom.color, coral);
    });

    testWidgets('the background param lifts into the per-state normal '
        'member', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendTabs(
            items: _items,
            selectedIndex: 0,
            onSelected: (_) {},
            background: navy,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_tabDecoration(tester, 'NFTs').color, navy);
    });
  });

  group('keyboard', () {
    testWidgets('Tab focuses in, arrows rove with wrap-around, Enter and '
        'Space activate the focused tab', (tester) async {
      final activations = <int>[];
      await tester.pumpWidget(
        _app(
          LegendTabs(
            items: _items,
            selectedIndex: 0,
            onSelected: activations.add,
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(activations, [1]);

      // Wraps left off the first tab onto the last.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(activations, [1, 2]);

      // ...and right off the last back onto the first.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(activations, [1, 2, 0]);
    });

    testWidgets('Home and End jump to the first and last tab', (tester) async {
      final activations = <int>[];
      await tester.pumpWidget(
        _app(
          LegendTabs(
            items: _items,
            selectedIndex: 0,
            onSelected: activations.add,
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(activations, [2]);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(activations, [2, 0]);
    });

    testWidgets('arrows mirror under RTL — arrowLeft moves to the visually '
        'left (next) tab', (tester) async {
      final activations = <int>[];
      await tester.pumpWidget(
        _app(
          LegendTabs(
            items: _items,
            selectedIndex: 0,
            onSelected: activations.add,
          ),
          direction: TextDirection.rtl,
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(activations, [1]);
    });
  });

  group('semantics', () {
    testWidgets('each tab announces the tab role with its selected state '
        'and label under a tabBar node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          LegendTabs(
            items: _items,
            selectedIndex: 1,
            onSelected: (_) {},
            semanticLabel: 'Wallet sections',
          ),
        ),
      );
      // Settling flushes the debug role checks (tab needs selected state
      // and a tap action; a tabBar's children must all be tabs).
      await tester.pumpAndSettle();

      final selected = tester.getSemantics(find.text('NFTs'));
      expect(selected.getSemanticsData().role, SemanticsRole.tab);
      expect(
        selected,
        containsSemantics(
          label: 'NFTs',
          isSelected: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );

      final unselected = tester.getSemantics(find.text('Tokens'));
      expect(unselected.getSemanticsData().role, SemanticsRole.tab);
      expect(unselected, containsSemantics(isSelected: false));

      final bar = tester.getSemantics(find.byType(LegendTabs));
      expect(bar.getSemanticsData().role, SemanticsRole.tabBar);
      expect(bar, containsSemantics(label: 'Wallet sections'));

      handle.dispose();
    });
  });

  testWidgets('survives the item list growing and shrinking', (tester) async {
    Widget build(List<LegendNavItem> items) =>
        _app(LegendTabs(items: items, selectedIndex: 0, onSelected: (_) {}));

    await tester.pumpWidget(build(_items.sublist(0, 2)));
    // Focus the last tab, then shrink the list past it.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    await tester.pumpWidget(build(_items.sublist(0, 1)));
    expect(find.text('Tokens'), findsOneWidget);
    expect(find.text('NFTs'), findsNothing);

    await tester.pumpWidget(build(_items));
    expect(find.text('Activity'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
