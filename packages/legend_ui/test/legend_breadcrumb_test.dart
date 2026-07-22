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

List<LegendBreadcrumbItem> _trail(
  List<String> labels, {
  void Function(String label)? onTap,
}) {
  return [
    for (final label in labels)
      LegendBreadcrumbItem(
        label: label,
        onTap: onTap == null ? null : () => onTap(label),
      ),
  ];
}

void main() {
  testWidgets('renders every label with a chevron between items and '
      'reports the tapped link', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      _app(
        LegendBreadcrumb(
          items: _trail(['Home', 'Wallet', 'Balances'], onTap: taps.add),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Balances'), findsOneWidget);
    // One separator per link — none after the current page.
    expect(find.byType(LegendCaret), findsNWidgets(2));

    await tester.tap(find.text('Wallet'));
    expect(taps, ['Wallet']);
  });

  testWidgets('the last item is inert with selected semantics — tapping '
      'it never fires, even with an onTap', (tester) async {
    final handle = tester.ensureSemantics();
    final taps = <String>[];
    await tester.pumpWidget(
      _app(
        LegendBreadcrumb(
          semanticLabel: 'You are here',
          items: _trail(['Home', 'Settings'], onTap: taps.add),
        ),
      ),
    );

    await tester.tap(find.text('Settings'), warnIfMissed: false);
    expect(taps, isEmpty);

    expect(
      tester.getSemantics(find.text('Settings')),
      containsSemantics(isSelected: true, hasTapAction: false),
    );
    expect(
      tester.getSemantics(find.text('Home')),
      containsSemantics(hasTapAction: true, isFocusable: true),
    );
    expect(
      tester.getSemantics(find.byType(LegendBreadcrumb)),
      containsSemantics(label: 'You are here'),
    );
    handle.dispose();
  });

  testWidgets('link and current-page items use their respective styles', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(LegendBreadcrumb(items: _trail(['Home', 'Wallet'], onTap: (_) {}))),
    );

    const tokens = LegendTokens.light;
    expect(
      tester.widget<Text>(find.text('Home')).style!.color,
      tokens.colors.foreground2,
    );
    final current = tester.widget<Text>(find.text('Wallet')).style!;
    expect(current.color, tokens.colors.foreground1);
    expect(current.fontWeight, FontWeight.w600);
  });

  testWidgets('a link-less ancestor renders as plain text, not a button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        LegendBreadcrumb(
          items: const [
            LegendBreadcrumbItem(label: 'Home'),
            LegendBreadcrumbItem(label: 'Wallet'),
          ],
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Home')),
      containsSemantics(hasTapAction: false, isFocusable: false),
    );
    handle.dispose();
  });

  group('maxVisible', () {
    testWidgets('collapses the middle into a non-tappable ellipsis, keeping '
        'the first item and the tail', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(
        _app(
          LegendBreadcrumb(
            maxVisible: 4,
            items: _trail([
              'Home',
              'Wallet',
              'Tokens',
              'ETH',
              'Details',
            ], onTap: taps.add),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('…'), findsOneWidget);
      expect(find.text('Wallet'), findsNothing);
      expect(find.text('Tokens'), findsNothing);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);

      await tester.tap(find.text('…'), warnIfMissed: false);
      expect(taps, isEmpty);
    });

    testWidgets('a trail within the limit never collapses', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendBreadcrumb(
            maxVisible: 3,
            items: _trail(['Home', 'Wallet', 'Tokens'], onTap: (_) {}),
          ),
        ),
      );
      expect(find.text('…'), findsNothing);
      expect(find.text('Wallet'), findsOneWidget);
    });
  });

  testWidgets('a custom separator replaces the painted chevron', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        LegendBreadcrumb(
          separator: const Text('/'),
          items: _trail(['Home', 'Wallet'], onTap: (_) {}),
        ),
      ),
    );
    expect(find.text('/'), findsOneWidget);
    expect(find.byType(LegendCaret), findsNothing);
  });

  testWidgets('the chevron points along the reading direction — forward '
      'flips under RTL', (tester) async {
    Widget build(TextDirection direction) => _app(
      LegendBreadcrumb(items: _trail(['Home', 'Wallet'], onTap: (_) {})),
      direction: direction,
    );

    await tester.pumpWidget(build(TextDirection.ltr));
    expect(tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns, 3);

    await tester.pumpWidget(build(TextDirection.rtl));
    expect(tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns, 1);
  });

  group('theme resolution', () {
    const navy = Color(0xFF001F54);
    const coral = Color(0xFFFF6B5B);

    testWidgets('a registry entry restyles the separator (level 3)', (
      tester,
    ) async {
      await tester.pumpWidget(
        LegendApp(
          theme: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendBreadcrumb: LegendBreadcrumbThemeNullable(
                separatorColor: navy,
              ),
            },
          ),
          home: Center(
            child: LegendBreadcrumb(
              items: _trail(['Home', 'Wallet'], onTap: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<LegendCaret>(find.byType(LegendCaret)).color, navy);
    });

    testWidgets('the constructor param wins over the registry (level 1)', (
      tester,
    ) async {
      await tester.pumpWidget(
        LegendApp(
          theme: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendBreadcrumb: LegendBreadcrumbThemeNullable(
                separatorColor: navy,
              ),
            },
          ),
          home: Center(
            child: LegendBreadcrumb(
              separatorColor: coral,
              items: _trail(['Home', 'Wallet'], onTap: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<LegendCaret>(find.byType(LegendCaret)).color, coral);
    });
  });
}
