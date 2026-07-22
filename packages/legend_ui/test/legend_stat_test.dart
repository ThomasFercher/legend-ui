import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child, {LegendThemeData? data}) {
  return LegendTheme(
    data: data ?? const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

/// The stat's delta caret (the painted up/down arrow).
LegendCaret _caret(WidgetTester tester) =>
    tester.widget<LegendCaret>(find.byType(LegendCaret));

Text _text(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text));

void main() {
  const tokens = LegendTokens.light;

  group('layout', () {
    testWidgets('renders label small/muted and value large/emphasized', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendStat(label: 'Balance', value: r'$12,480.30')),
      );

      final label = _text(tester, 'Balance');
      expect(label.style?.fontSize, tokens.typography.b3.fontSize);
      expect(label.style?.color, tokens.colors.foreground2);

      final value = _text(tester, r'$12,480.30');
      expect(value.style?.fontSize, tokens.typography.h2.fontSize);
      expect(value.style?.color, tokens.colors.foreground1);
    });

    testWidgets('no delta and no caption renders just the two lines', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendStat(label: 'Sources', value: '12')),
      );
      expect(find.byType(Text), findsNWidgets(2));
      expect(find.byType(LegendCaret), findsNothing);
    });

    testWidgets('caption renders faint, alone on its line without a delta', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendStat(
            label: 'Members',
            value: '48',
            caption: 'across 3 teams',
          ),
        ),
      );
      final caption = _text(tester, 'across 3 teams');
      expect(caption.style?.color, tokens.colors.foreground3);
      expect(caption.style?.fontSize, tokens.typography.b3.fontSize);
      expect(find.byType(LegendCaret), findsNothing);
    });

    testWidgets('leading slot renders before the texts', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegendStat(
            label: 'ETH',
            value: '2.4801',
            leading: SizedBox(width: 32, height: 32, key: Key('icon')),
          ),
        ),
      );
      final icon = tester.getRect(find.byKey(const Key('icon')));
      final label = tester.getRect(find.text('ETH'));
      expect(icon.left, lessThan(label.left));
    });
  });

  group('delta', () {
    testWidgets('up renders an upward caret and text in positiveColor', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendStat(
            label: 'Balance',
            value: r'$12,480.30',
            delta: '4.2%',
            deltaDirection: LegendStatDirection.up,
          ),
        ),
      );
      final caret = _caret(tester);
      expect(caret.open, isTrue); // open caret points up
      expect(caret.color, tokens.colors.secondary);
      expect(_text(tester, '4.2%').style?.color, tokens.colors.secondary);
    });

    testWidgets('down renders a downward caret and text in negativeColor', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendStat(
            label: 'SOL',
            value: r'$142.87',
            delta: '1.8%',
            deltaDirection: LegendStatDirection.down,
          ),
        ),
      );
      final caret = _caret(tester);
      expect(caret.open, isFalse);
      expect(caret.color, tokens.colors.error);
      expect(_text(tester, '1.8%').style?.color, tokens.colors.error);
    });

    testWidgets('flat renders no caret and text in neutralColor', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendStat(label: 'USDC', value: r'$1.00', delta: '0.0%')),
      );
      expect(find.byType(LegendCaret), findsNothing);
      expect(_text(tester, '0.0%').style?.color, tokens.colors.foreground2);
    });

    test('fromChange maps the sign of a change to a direction', () {
      expect(LegendStatDirection.fromChange(4.2), LegendStatDirection.up);
      expect(LegendStatDirection.fromChange(-0.1), LegendStatDirection.down);
      expect(LegendStatDirection.fromChange(0), LegendStatDirection.flat);
      expect(
        LegendStatDirection.fromChange(double.nan),
        LegendStatDirection.flat,
      );
    });
  });

  group('semantics', () {
    testWidgets('announces one merged node with the direction spoken', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendStat(
            label: 'Balance',
            value: r'$12,480.30',
            delta: '4.2%',
            deltaDirection: LegendStatDirection.up,
            caption: 'vs last week',
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(LegendStat));
      expect(node.label, 'Balance\n\$12,480.30\nup 4.2%\nvs last week');
    });

    testWidgets('a downward delta is spoken as "down"', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegendStat(
            label: 'SOL',
            value: r'$142.87',
            delta: '1.8%',
            deltaDirection: LegendStatDirection.down,
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(LegendStat));
      expect(node.label, 'SOL\n\$142.87\ndown 1.8%');
    });

    testWidgets('a flat delta is spoken without a direction word', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendStat(label: 'USDC', value: r'$1.00', delta: '0.0%')),
      );
      final node = tester.getSemantics(find.byType(LegendStat));
      expect(node.label, 'USDC\n\$1.00\n0.0%');
    });
  });

  group('theming', () {
    const navy = Color(0xFF001F54);
    const lime = Color(0xFF84CC16);

    testWidgets('constructor param beats the registry override', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendStat(
            label: 'Balance',
            value: r'$1.00',
            delta: '4.2%',
            deltaDirection: LegendStatDirection.up,
            positiveColor: navy,
          ),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendStat: LegendStatThemeNullable(positiveColor: lime),
            },
          ),
        ),
      );
      expect(_caret(tester).color, navy);
    });

    testWidgets('level-3 registry entry restyles the stat sparsely', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendStat(
            label: 'Balance',
            value: r'$1.00',
            delta: '4.2%',
            deltaDirection: LegendStatDirection.up,
          ),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendStat: LegendStatThemeNullable(positiveColor: lime),
            },
          ),
        ),
      );
      expect(_caret(tester).color, lime);
      // Unset members keep resolving through the token defaults.
      expect(_text(tester, 'Balance').style?.color, tokens.colors.foreground2);
    });

    testWidgets('subtree override wins over the registry', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegendStatThemeOverride(
            data: LegendStatThemeNullable(positiveColor: navy),
            child: LegendStat(
              label: 'Balance',
              value: r'$1.00',
              delta: '4.2%',
              deltaDirection: LegendStatDirection.up,
            ),
          ),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendStat: LegendStatThemeNullable(positiveColor: lime),
            },
          ),
        ),
      );
      expect(_caret(tester).color, navy);
    });

    testWidgets('spacing themes the gap between the stacked lines', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendStat(label: 'Balance', value: r'$1.00', spacing: 20)),
      );
      final label = tester.getRect(find.text('Balance'));
      final value = tester.getRect(find.text(r'$1.00'));
      expect(value.top - label.bottom, 20);
    });
  });
}
