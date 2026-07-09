import 'package:example/main.dart';
import 'package:flutter/material.dart' show SelectionArea;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Color _primaryButtonColor(WidgetTester tester, String text) {
  final container = tester.widget<AnimatedContainer>(
    find
        .ancestor(of: find.text(text), matching: find.byType(AnimatedContainer))
        .first,
  );
  return (container.decoration! as BoxDecoration).color!;
}

void main() {
  testWidgets('docs site renders, navigates sections, toggles theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DocsApp());
    await tester.pumpAndSettle();

    // Landing page.
    expect(find.text('Getting started'), findsOneWidget);

    // Sider navigation to the Buttons docs.
    await tester.tap(find.text('Buttons'));
    await tester.pumpAndSettle();
    expect(find.text('Variants'), findsOneWidget);
    expect(
      _primaryButtonColor(tester, 'Primary'),
      LegendTokens.light.colors.primary,
    );

    // Dark toggle in the app bar animates the tokens.
    await tester.tap(find.byType(LegendSwitch).first);
    await tester.pumpAndSettle();
    expect(
      _primaryButtonColor(tester, 'Primary'),
      LegendTokens.dark.colors.primary,
    );
  });

  testWidgets('docs prose is web-selectable (under a SelectionArea)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DocsApp());
    await tester.pumpAndSettle();

    // Page prose sits inside a SelectionArea, so CanvasKit-painted text is
    // selectable on web. SelectionArea needs MaterialLocalizations, supplied
    // through LegendApp's localizations passthrough — if that regresses,
    // pumping DocsApp throws here.
    expect(
      find.ancestor(
        of: find.textContaining('Material-free'),
        matching: find.byType(SelectionArea),
      ),
      findsOneWidget,
    );
  });

  testWidgets('resolution ladder: nearest enabled level wins', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DocsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theming'));
    await tester.pumpAndSettle();

    Future<void> toggle(String key) async {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(key)),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
    }

    await tester.scrollUntilVisible(
      find.text('Resolved'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // All levels off: token default.
    expect(
      _primaryButtonColor(tester, 'Resolved'),
      LegendTokens.light.colors.primary,
    );

    // Mid-tree LegendTheme (level 3) beats tokens.
    await toggle('ladder-midtree');
    expect(_primaryButtonColor(tester, 'Resolved'), const Color(0xFF0D9488));

    // Subtree override (level 2) beats the mid-tree theme.
    await toggle('ladder-subtree');
    expect(_primaryButtonColor(tester, 'Resolved'), const Color(0xFFD97706));

    // Constructor param (level 1) beats everything.
    await toggle('ladder-constructor');
    expect(_primaryButtonColor(tester, 'Resolved'), const Color(0xFF8B5CF6));

    // Dropping the nearer levels falls back down the ladder.
    await toggle('ladder-constructor');
    await toggle('ladder-subtree');
    expect(_primaryButtonColor(tester, 'Resolved'), const Color(0xFF0D9488));
  });

  testWidgets(
    'playground: preset, brand color, and component override restyle live',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // The playground preview contains LegendLoading (an unbounded
      // animation), so pumpAndSettle would never settle — pump through the
      // 250 ms theme animation explicitly instead.
      Future<void> settleTheme() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      await tester.pumpWidget(const DocsApp());
      await settleTheme();

      await tester.tap(find.text('Playground'));
      await settleTheme();

      // Emerald preset changes the primary token everywhere.
      await tester.tap(find.text('Emerald'));
      await settleTheme();
      expect(_primaryButtonColor(tester, 'Primary'), const Color(0xFF059669));

      // A custom primary via swatch beats the preset.
      await tester.tap(find.bySemanticsLabel(RegExp('Primary color #')).first);
      await settleTheme();
      expect(_primaryButtonColor(tester, 'Primary'), const Color(0xFF2563EB));

      // Component override: registers a sparse PrimaryLegendButton theme in
      // the components map (level 3) without touching other components.
      await tester.tap(
        find.bySemanticsLabel(RegExp('Primary button background #')).at(3),
      );
      await settleTheme();
      expect(
        _primaryButtonColor(tester, 'Primary'),
        const Color(0xFFDC2626),
        reason: 'level-3 components map beats token defaults',
      );
      expect(
        _primaryButtonColor(tester, 'Secondary'),
        isNot(const Color(0xFFDC2626)),
        reason: 'other components are untouched by a sparse override',
      );
    },
  );
}
