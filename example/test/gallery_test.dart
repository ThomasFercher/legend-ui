import 'package:example/main.dart';
import 'package:flutter/material.dart' show SelectionArea;
import 'package:flutter/services.dart';
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

  testWidgets('overlays page: popover opens and Escape dismisses', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DocsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overlays'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Below'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible stops as soon as the sliver cache builds the
    // target, which can still be off-screen — align it for the tap.
    await tester.ensureVisible(find.text('Below'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Below'));
    await tester.pumpAndSettle();
    expect(find.textContaining('same overlay engine'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.textContaining('same overlay engine'), findsNothing);
  });

  testWidgets('playground: popover radius knob restyles the live popover', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The playground preview contains LegendLoading (an unbounded
    // animation), so pumpAndSettle would never settle.
    Future<void> settleTheme() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    await tester.tap(find.text('Playground'));
    await settleTheme();

    // Register the level-3 override through the panel's popover knob.
    // (.last: the button-radius dropdown shares the placeholder text.)
    await tester.scrollUntilVisible(
      find.textContaining('Popover panel radius'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible stops as soon as the sliver cache builds the
    // target, which can still be off-screen — align it for the tap.
    await tester.ensureVisible(find.text('Theme default').last);
    await settleTheme();
    await tester.tap(find.text('Theme default').last);
    await settleTheme();
    await tester.tap(find.text('Rounded (12)'));
    await settleTheme();

    // The live popover in the preview column picks it up.
    await tester.scrollUntilVisible(
      find.text('Tap for a popover'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Tap for a popover'));
    await settleTheme();
    await tester.tap(find.text('Tap for a popover'));
    await settleTheme();
    final panel = tester.widget<LegendSurface>(
      find
          .ancestor(
            of: find.text('Popover'),
            matching: find.byType(LegendSurface),
          )
          .first,
    );
    expect(panel.borderRadius, BorderRadius.circular(12));
  });

  testWidgets('layout page: badge demo shows label, counts, and overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DocsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Layout'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Mainnet'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mainnet'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // 250 overflows the default max.
    expect(find.text('99+'), findsOneWidget);
    // The anchored dot announces its semantic label.
    expect(find.bySemanticsLabel('Online'), findsOneWidget);
  });

  testWidgets('playground: badge background knob restyles the live badge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The playground preview contains LegendLoading (an unbounded
    // animation), so pumpAndSettle would never settle.
    Future<void> settleTheme() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    await tester.tap(find.text('Playground'));
    await settleTheme();

    // Register the level-3 override through the panel's badge swatch.
    await tester.scrollUntilVisible(
      find.text('Badge background'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel('Badge background #2563EB'),
    );
    await settleTheme();
    await tester.tap(find.bySemanticsLabel('Badge background #2563EB'));
    await settleTheme();

    // The live badges in the preview column pick it up.
    await tester.scrollUntilVisible(
      find.text('Mainnet'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final pill = tester.widget<LegendSurface>(
      find
          .ancestor(
            of: find.text('Mainnet'),
            matching: find.byType(LegendSurface),
          )
          .first,
    );
    expect(pill.color, const Color(0xFF2563EB));
  });

  testWidgets('playground: checkbox fill knob restyles the live checkbox', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The playground preview contains LegendLoading (an unbounded
    // animation), so pumpAndSettle would never settle.
    Future<void> settleTheme() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    await tester.tap(find.text('Playground'));
    await settleTheme();

    // Register the level-3 override through the panel's checkbox knob.
    await tester.scrollUntilVisible(
      find.textContaining('Checkbox fill'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible stops as soon as the sliver cache builds the
    // target, which can still be off-screen — align it for the tap.
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Checkbox fill .*#8B5CF6')),
    );
    await settleTheme();
    await tester.tap(find.bySemanticsLabel(RegExp('Checkbox fill .*#8B5CF6')));
    await settleTheme();

    // The live checkbox in the preview column picks it up — a sparse
    // InteractiveColors(normal: …) whose other states keep deriving.
    await tester.scrollUntilVisible(
      find.byType(LegendCheckbox),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final box = tester.widget<LegendSurface>(
      find.descendant(
        of: find.byType(LegendCheckbox),
        matching: find.byType(LegendSurface),
      ),
    );
    expect(box.color, const Color(0xFF8B5CF6));
  });

  testWidgets('playground: avatar shape knob restyles the live avatars', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The playground preview contains LegendLoading (an unbounded
    // animation), so pumpAndSettle would never settle.
    Future<void> settleTheme() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    await tester.tap(find.text('Playground'));
    await settleTheme();

    // Register the level-3 override through the panel's avatar knob.
    await tester.scrollUntilVisible(
      find.textContaining('Avatar shape'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Circle (default)'));
    await settleTheme();
    await tester.tap(find.text('Circle (default)'));
    await settleTheme();
    await tester.tap(find.text('Squircle (8)'));
    await settleTheme();

    // Every live avatar in the preview column picks it up.
    await tester.scrollUntilVisible(
      find.byType(LegendAvatar).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final surface = tester.widget<LegendSurface>(
      find
          .descendant(
            of: find.byType(LegendAvatar).first,
            matching: find.byType(LegendSurface),
          )
          .first,
    );
    expect(surface.borderRadius, BorderRadius.circular(8));
  });

  testWidgets('playground: list selected-background knob restyles the live '
      'list', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The playground preview contains LegendLoading (an unbounded
    // animation), so pumpAndSettle would never settle.
    Future<void> settleTheme() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    await tester.tap(find.text('Playground'));
    await settleTheme();

    // Register the level-3 override through the panel's list knob.
    await tester.scrollUntilVisible(
      find.textContaining('List-item selected background'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final swatch = find
        .bySemanticsLabel(RegExp('List-item selected background #'))
        .at(3);
    await tester.ensureVisible(swatch);
    await settleTheme();
    await tester.tap(swatch);
    await settleTheme();

    // The live list's selected row in the preview column picks it up.
    await tester.scrollUntilVisible(
      find.text('Ethereum'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Ethereum'));
    await settleTheme();
    final row = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Ethereum'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(
      (row.decoration! as BoxDecoration).color,
      const Color(0xFFDC2626),
      reason: 'level-3 components map restyles the selected row fill',
    );
  });
}
