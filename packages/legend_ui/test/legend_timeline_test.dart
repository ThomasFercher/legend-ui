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

const _entries = [
  LegendTimelineEntry(
    title: 'Sent 0.4 ETH',
    description: 'To 0x12ab…89cd',
    timestamp: '2 min ago',
  ),
  LegendTimelineEntry(title: 'Swapped SOL for USDC', timestamp: 'Yesterday'),
  LegendTimelineEntry(title: 'Wallet created'),
];

Finder _surfaceWith(Color color) => find.byWidgetPredicate(
  (widget) => widget is LegendSurface && widget.color == color,
);

void main() {
  const tokens = LegendTokens.light;

  group('LegendTimeline content', () {
    testWidgets('renders titles, descriptions and timestamps', (tester) async {
      await tester.pumpWidget(_wrap(LegendTimeline(entries: _entries)));
      for (final text in [
        'Sent 0.4 ETH',
        'To 0x12ab…89cd',
        '2 min ago',
        'Swapped SOL for USDC',
        'Yesterday',
        'Wallet created',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
    });

    testWidgets('entries stack vertically in display order', (tester) async {
      await tester.pumpWidget(_wrap(LegendTimeline(entries: _entries)));
      final first = tester.getTopLeft(find.text('Sent 0.4 ETH'));
      final second = tester.getTopLeft(find.text('Swapped SOL for USDC'));
      final third = tester.getTopLeft(find.text('Wallet created'));
      expect(second.dy, greaterThan(first.dy));
      expect(third.dy, greaterThan(second.dy));
    });

    testWidgets('the free-form child slot renders below the texts', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LegendTimeline(
            entries: const [
              LegendTimelineEntry(
                title: 'Sent 0.4 ETH',
                child: Text('View on explorer'),
              ),
            ],
          ),
        ),
      );
      final title = tester.getTopLeft(find.text('Sent 0.4 ETH'));
      final child = tester.getTopLeft(find.text('View on explorer'));
      expect(child.dy, greaterThan(title.dy));
    });

    testWidgets('is purely presentational — no interaction primitives', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(LegendTimeline(entries: _entries)));
      expect(find.byType(LegendInteractive), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });
  });

  group('LegendTimeline indicators', () {
    testWidgets('every entry gets the themed dot by default', (tester) async {
      await tester.pumpWidget(_wrap(LegendTimeline(entries: _entries)));
      expect(_surfaceWith(tokens.colors.primary), findsNWidgets(3));
    });

    testWidgets('a custom indicator replaces the dot for its entry', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LegendTimeline(
            entries: const [
              LegendTimelineEntry(title: 'Sent', indicator: Text('!')),
              LegendTimelineEntry(title: 'Received'),
            ],
          ),
        ),
      );
      expect(find.text('!'), findsOneWidget);
      // Only the second entry paints the default dot.
      expect(_surfaceWith(tokens.colors.primary), findsOneWidget);
    });

    testWidgets('connectors run between entries, none after the last', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(LegendTimeline(entries: _entries)));
      expect(_surfaceWith(tokens.colors.background3), findsNWidgets(2));
    });
  });

  group('LegendTimeline semantics', () {
    testWidgets('an entry reads as one merged node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(LegendTimeline(entries: _entries)));
      final node = tester.getSemantics(find.text('Sent 0.4 ETH'));
      final label = node.getSemanticsData().label;
      expect(label, contains('Sent 0.4 ETH'));
      expect(label, contains('2 min ago'));
      expect(label, contains('To 0x12ab…89cd'));
      handle.dispose();
    });
  });

  group('LegendTimeline theming', () {
    const navy = Color(0xFF001F54);

    testWidgets('level 3: a components-map entry recolors the dots', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LegendTimeline(entries: _entries),
          data: const LegendThemeData(
            tokens: tokens,
            components: {
              LegendTimeline: LegendTimelineThemeNullable(indicatorColor: navy),
            },
          ),
        ),
      );
      expect(_surfaceWith(navy), findsNWidgets(3));
      expect(_surfaceWith(tokens.colors.primary), findsNothing);
    });

    testWidgets('level 1: the constructor param wins over the registry', (
      tester,
    ) async {
      const crimson = Color(0xFF8B0000);
      await tester.pumpWidget(
        _wrap(
          LegendTimeline(entries: _entries, indicatorColor: crimson),
          data: const LegendThemeData(
            tokens: tokens,
            components: {
              LegendTimeline: LegendTimelineThemeNullable(indicatorColor: navy),
            },
          ),
        ),
      );
      expect(_surfaceWith(crimson), findsNWidgets(3));
      expect(_surfaceWith(navy), findsNothing);
    });

    testWidgets('level 2: a subtree override beats the registry', (
      tester,
    ) async {
      const teal = Color(0xFF00695C);
      await tester.pumpWidget(
        _wrap(
          LegendTimelineThemeOverride(
            data: const LegendTimelineThemeNullable(indicatorColor: teal),
            child: LegendTimeline(entries: _entries),
          ),
          data: const LegendThemeData(
            tokens: tokens,
            components: {
              LegendTimeline: LegendTimelineThemeNullable(indicatorColor: navy),
            },
          ),
        ),
      );
      expect(_surfaceWith(teal), findsNWidgets(3));
      expect(_surfaceWith(navy), findsNothing);
    });
  });
}
