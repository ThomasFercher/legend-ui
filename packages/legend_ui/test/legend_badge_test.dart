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

/// The badge's own [LegendSurface] (the stadium pill/dot).
LegendSurface _surface(WidgetTester tester) => tester.widget<LegendSurface>(
  find.descendant(
    of: find.byType(LegendBadge),
    matching: find.byType(LegendSurface),
  ),
);

void main() {
  const tokens = LegendTokens.light;

  group('standalone', () {
    testWidgets('label badge renders themed text on the token fill', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendBadge('Mainnet')));
      expect(find.text('Mainnet'), findsOneWidget);

      final surface = _surface(tester);
      expect(surface.color, tokens.colors.error);
      expect(surface.border, isNull); // ring is anchored-only
      final text = tester.widget<Text>(find.text('Mainnet'));
      expect(text.style?.color, tokens.colors.onError);
      expect(text.style?.fontSize, tokens.typography.b3.fontSize);
    });

    testWidgets('count badge renders the count and max+ overflow', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendBadge.count(5)));
      expect(find.text('5'), findsOneWidget);

      await tester.pumpWidget(_wrap(const LegendBadge.count(250)));
      expect(find.text('99+'), findsOneWidget);

      await tester.pumpWidget(_wrap(const LegendBadge.count(12, max: 9)));
      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('count of zero renders nothing', (tester) async {
      await tester.pumpWidget(_wrap(const LegendBadge.count(0)));
      expect(find.byType(LegendSurface), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('dot renders a themed-size box and no text', (tester) async {
      await tester.pumpWidget(_wrap(const LegendBadge.dot()));
      expect(find.byType(Text), findsNothing);
      expect(
        tester.getSize(find.byType(LegendSurface)),
        Size.square(tokens.sizes.sm),
      );
    });
  });

  group('anchored', () {
    testWidgets('overlays the child and draws the contrast ring', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendBadge.count(
            3,
            child: SizedBox(width: 40, height: 40, key: Key('icon')),
          ),
        ),
      );
      expect(find.byKey(const Key('icon')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      final surface = _surface(tester);
      final border = surface.border! as Border;
      expect(border.top.color, tokens.colors.surface);
      expect(border.top.width, tokens.sizes.borderWidth * 2);
    });

    testWidgets('default topEnd alignment overhangs the top-right in LTR', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendBadge.dot(
            child: SizedBox(width: 40, height: 40, key: Key('icon')),
          ),
        ),
      );
      final shift = tester.widget<FractionalTranslation>(
        find.byType(FractionalTranslation),
      );
      expect(shift.translation, const Offset(0.5, -0.5));

      final icon = tester.getRect(find.byKey(const Key('icon')));
      final dot = tester.getRect(find.byType(LegendSurface));
      // Align puts the dot inside the top-right corner; the fractional
      // shift moves it halfway outward.
      expect(dot.center.dx, icon.right);
      expect(dot.center.dy, icon.top);
    });

    testWidgets('alignment picks the anchored corner', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegendBadge.dot(
            alignment: AlignmentDirectional.bottomStart,
            child: SizedBox(width: 40, height: 40, key: Key('icon')),
          ),
        ),
      );
      final icon = tester.getRect(find.byKey(const Key('icon')));
      final dot = tester.getRect(find.byType(LegendSurface));
      expect(dot.center.dx, icon.left);
      expect(dot.center.dy, icon.bottom);
    });

    testWidgets('count of zero renders just the child', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegendBadge.count(
            0,
            child: SizedBox(width: 40, height: 40, key: Key('icon')),
          ),
        ),
      );
      expect(find.byKey(const Key('icon')), findsOneWidget);
      expect(find.byType(Stack), findsNothing);
      expect(find.byType(LegendSurface), findsNothing);
    });
  });

  group('semantics', () {
    testWidgets('count text announces itself', (tester) async {
      await tester.pumpWidget(_wrap(const LegendBadge.count(7)));
      expect(find.bySemanticsLabel('7'), findsOneWidget);
    });

    testWidgets('semanticLabel replaces the visual content', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendBadge.count(3, semanticLabel: '3 unread messages')),
      );
      expect(find.bySemanticsLabel('3 unread messages'), findsOneWidget);
      expect(find.bySemanticsLabel('3'), findsNothing);
    });

    testWidgets('dot announces its semanticLabel', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendBadge.dot(semanticLabel: 'Online')),
      );
      expect(find.bySemanticsLabel('Online'), findsOneWidget);
    });
  });

  group('theming', () {
    testWidgets('constructor param beats the registry override', (
      tester,
    ) async {
      const navy = Color(0xFF001F54);
      const lime = Color(0xFF84CC16);
      await tester.pumpWidget(
        _wrap(
          const LegendBadge('New', background: navy),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendBadge: LegendBadgeThemeNullable(background: lime),
            },
          ),
        ),
      );
      expect(_surface(tester).color, navy);
    });

    testWidgets('level-3 registry entry restyles the badge sparsely', (
      tester,
    ) async {
      const lime = Color(0xFF84CC16);
      await tester.pumpWidget(
        _wrap(
          const LegendBadge('New'),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendBadge: LegendBadgeThemeNullable(background: lime),
            },
          ),
        ),
      );
      expect(_surface(tester).color, lime);
      // Unset members keep resolving through the token defaults.
      final text = tester.widget<Text>(find.text('New'));
      expect(text.style?.color, tokens.colors.onError);
    });

    testWidgets('subtree override wins over the registry', (tester) async {
      const navy = Color(0xFF001F54);
      const lime = Color(0xFF84CC16);
      await tester.pumpWidget(
        _wrap(
          const LegendBadgeThemeOverride(
            data: LegendBadgeThemeNullable(background: navy),
            child: LegendBadge('New'),
          ),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendBadge: LegendBadgeThemeNullable(background: lime),
            },
          ),
        ),
      );
      expect(_surface(tester).color, navy);
    });
  });
}
