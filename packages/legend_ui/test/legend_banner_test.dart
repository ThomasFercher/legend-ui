import 'package:flutter/semantics.dart';
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

/// The banner strip surface (the [Container] a `LegendSurface` builds)
/// filled with [color].
Finder _strip(Color color) => find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration! as BoxDecoration).color == color,
);

/// The severity tint the annotation defaults derive: hue at 12% over the
/// surface token.
Color _tint(Color hue, LegendTokens tokens) =>
    Color.alphaBlend(hue.withValues(alpha: 0.12), tokens.colors.surface);

Color _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  group('LegendBanner content', () {
    testWidgets('renders message, title, icon and action slots', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendBanner(
            message: 'Verify the address before signing.',
            title: 'Security warning',
            severity: LegendBannerSeverity.warning,
            icon: Text('!'),
            action: Text('Review'),
          ),
        ),
      );
      expect(find.text('Verify the address before signing.'), findsOneWidget);
      expect(find.text('Security warning'), findsOneWidget);
      expect(find.text('!'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('announces its content as a live region, dismissible via '
        'the semantic dismiss action', (tester) async {
      final semantics = tester.ensureSemantics();
      var dismissed = 0;
      await tester.pumpWidget(
        _wrap(
          LegendBanner(message: 'Quota low', onDismissed: () => dismissed++),
        ),
      );
      final node = tester.getSemantics(find.text('Quota low'));
      expect(node, containsSemantics(isLiveRegion: true, label: 'Quota low'));

      node.owner!.performAction(node.id, SemanticsAction.dismiss);
      expect(dismissed, 1);
      semantics.dispose();
    });

    testWidgets('sizes the icon slot to the themed iconSize', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendBanner(message: 'm', icon: Text('!'), iconSize: 32)),
      );
      final slot = find.ancestor(
        of: find.text('!'),
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(slot.first), const Size(32, 32));
    });
  });

  group('LegendBanner severity colors', () {
    const tokens = LegendTokens.light;

    testWidgets('info (default) tints with primary and accents the title', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendBanner(message: 'm', title: 't')),
      );
      expect(_strip(_tint(tokens.colors.primary, tokens)), findsOneWidget);
      expect(_textColor(tester, 't'), tokens.colors.primary);
    });

    testWidgets('success uses the secondary token', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegendBanner(
            message: 'm',
            title: 't',
            severity: LegendBannerSeverity.success,
          ),
        ),
      );
      expect(_strip(_tint(tokens.colors.secondary, tokens)), findsOneWidget);
      expect(_textColor(tester, 't'), tokens.colors.secondary);
    });

    testWidgets('error uses the error token', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegendBanner(
            message: 'm',
            title: 't',
            severity: LegendBannerSeverity.error,
          ),
        ),
      );
      expect(_strip(_tint(tokens.colors.error, tokens)), findsOneWidget);
      expect(_textColor(tester, 't'), tokens.colors.error);
    });

    testWidgets('warning picks the amber for the palette brightness', (
      tester,
    ) async {
      const banner = LegendBanner(
        message: 'm',
        title: 't',
        severity: LegendBannerSeverity.warning,
      );
      await tester.pumpWidget(_wrap(banner));
      expect(_textColor(tester, 't'), const Color(0xFFD97706));

      await tester.pumpWidget(
        _wrap(banner, data: const LegendThemeData(tokens: LegendTokens.dark)),
      );
      expect(_textColor(tester, 't'), const Color(0xFFFBBF24));
    });
  });

  group('LegendBanner dismiss affordance', () {
    testWidgets('absent without onDismissed, taps through when present', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const LegendBanner(message: 'm')));
      expect(find.byType(LegendInteractive), findsNothing);

      var dismissed = 0;
      await tester.pumpWidget(
        _wrap(
          LegendBanner(
            message: 'm',
            dismissLabel: 'Dismiss notice',
            onDismissed: () => dismissed++,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(LegendInteractive)),
        containsSemantics(label: 'Dismiss notice', isButton: true),
      );
      await tester.tap(find.byType(LegendInteractive));
      expect(dismissed, 1);
      semantics.dispose();
    });
  });

  group('LegendBanner theme resolution', () {
    const navy = Color(0xFF001F54);

    testWidgets('constructor param wins over the annotation default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendBanner(message: 'm', infoBackground: navy)),
      );
      expect(_strip(navy), findsOneWidget);
    });

    testWidgets('components-map entry (level 3) restyles the strip', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendBanner(message: 'm'),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendBanner: LegendBannerThemeNullable(infoBackground: navy),
            },
          ),
        ),
      );
      expect(_strip(navy), findsOneWidget);
    });

    testWidgets('subtree override (level 2) beats the registry', (
      tester,
    ) async {
      const violet = Color(0xFF5B21B6);
      await tester.pumpWidget(
        _wrap(
          const LegendBannerThemeOverride(
            data: LegendBannerThemeNullable(infoBackground: violet),
            child: LegendBanner(message: 'm'),
          ),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendBanner: LegendBannerThemeNullable(infoBackground: navy),
            },
          ),
        ),
      );
      expect(_strip(violet), findsOneWidget);
      expect(_strip(navy), findsNothing);
    });
  });
}
