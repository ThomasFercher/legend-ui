import 'package:example/main.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Icons, SelectionArea;
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

  testWidgets('overlays page: menu opens, selects, and shows the choice', (
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
      find.text('File actions'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible stops as soon as the sliver cache builds the
    // target, which can still be off-screen — align it for the tap.
    await tester.ensureVisible(find.text('File actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('File actions'));
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    expect(find.text('Duplicate'), findsNothing);
    expect(find.text('Ran: Duplicate'), findsOneWidget);
  });

  testWidgets('playground: menu destructive knob restyles the live menu', (
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

    // Register the level-3 override through the panel's menu knob.
    await tester.scrollUntilVisible(
      find.textContaining('Menu destructive color'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    // Swatch 4 is violet (0xFF8B5CF6).
    await tester.tap(
      find.bySemanticsLabel(RegExp('Menu destructive color .* #8B5CF6')),
    );
    await settleTheme();

    // The live menu in the preview column picks it up.
    await tester.scrollUntilVisible(
      find.text('Tap for an action menu'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Tap for an action menu'));
    await settleTheme();
    await tester.tap(find.text('Tap for an action menu'));
    await settleTheme();
    final label = tester.widget<Text>(find.text('Delete'));
    expect(label.style?.color, const Color(0xFF8B5CF6));
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

  testWidgets('layout page: stat demo shows deltas in direction colors', (
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
      find.text(r'$12,480.30'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    const tokens = LegendTokens.light;
    final up = tester.widget<Text>(find.text('4.2%'));
    expect(up.style?.color, tokens.colors.secondary);
    final down = tester.widget<Text>(find.text('1.8%'));
    expect(down.style?.color, tokens.colors.error);
    final flat = tester.widget<Text>(find.text('0.0%'));
    expect(flat.style?.color, tokens.colors.foreground2);
    // One merged node per stat, with the arrow spoken as a direction.
    expect(
      find.bySemanticsLabel('Balance\n\$12,480.30\nup 4.2%\nvs last week'),
      findsOneWidget,
    );
  });

  testWidgets('playground: stat positive-color knob restyles the live stat', (
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

    // Register the level-3 override through the panel's stat swatch.
    await tester.scrollUntilVisible(
      find.text('Stat positive-delta color (LegendStat.positiveColor)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(
        'Stat positive-delta color (LegendStat.positiveColor) #D97706',
      ),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(
        'Stat positive-delta color (LegendStat.positiveColor) #D97706',
      ),
    );
    await settleTheme();

    // The live stat's upward delta in the preview column picks it up; the
    // downward one keeps its token color.
    await tester.scrollUntilVisible(
      find.text('4.2%'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final up = tester.widget<Text>(find.text('4.2%'));
    expect(up.style?.color, const Color(0xFFD97706));
    final down = tester.widget<Text>(find.text('1.8%'));
    expect(down.style?.color, LegendTokens.light.colors.error);
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

  testWidgets('playground: radio fill knob restyles the live radio group', (
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

    // Register the level-3 override through the panel's radio knob.
    await tester.scrollUntilVisible(
      find.textContaining('Radio fill'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible stops as soon as the sliver cache builds the
    // target, which can still be off-screen — align it for the tap.
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Radio fill .*#8B5CF6')),
    );
    await settleTheme();
    await tester.tap(find.bySemanticsLabel(RegExp('Radio fill .*#8B5CF6')));
    await settleTheme();

    // The selected radio in the preview column picks it up — a sparse
    // InteractiveColors(normal: …) whose other states keep deriving.
    await tester.scrollUntilVisible(
      find.text('Monthly'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final circle = tester.widget<LegendSurface>(
      find.descendant(
        of: find.ancestor(
          of: find.text('Monthly'),
          matching: find.byType(LegendSelectionControl),
        ),
        matching: find.byType(LegendSurface),
      ),
    );
    expect(circle.color, const Color(0xFF8B5CF6));
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

  testWidgets('playground: chip selected-fill knob restyles the live chip', (
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

    // Register the level-3 override through the panel's chip knob.
    await tester.scrollUntilVisible(
      find.textContaining('Chip selected fill'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final swatch = find.bySemanticsLabel(RegExp('Chip selected fill #')).at(3);
    // scrollUntilVisible stops as soon as the sliver cache builds the
    // target, which can still be off-screen — align it for the tap.
    await tester.ensureVisible(swatch);
    await settleTheme();
    await tester.tap(swatch);
    await settleTheme();

    // The live selected chip in the preview column picks it up; the
    // unselected background is untouched by the sparse override.
    await tester.scrollUntilVisible(
      find.text('Filter'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Filter'));
    await settleTheme();
    expect(
      _primaryButtonColor(tester, 'Filter'),
      const Color(0xFFDC2626),
      reason: 'level-3 components map restyles the selected fill',
    );
  });

  testWidgets('playground: tabs indicator knob restyles the live tabs', (
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

    Color indicatorColor(String label) {
      final container = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return (container.decoration! as BoxDecoration).border!.bottom.color;
    }

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    await tester.tap(find.text('Playground'));
    await settleTheme();

    // The live LegendTabs starts on the token default and tracks taps.
    await tester.scrollUntilVisible(
      find.text('NFTs'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('NFTs'));
    await settleTheme();
    expect(indicatorColor('Tokens'), LegendTokens.light.colors.primary);
    await tester.tap(find.text('NFTs'));
    await settleTheme();
    expect(indicatorColor('NFTs'), LegendTokens.light.colors.primary);

    // Register the level-3 override through the panel's tabs knob.
    await tester.scrollUntilVisible(
      find.textContaining('Tabs indicator color'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Tabs indicator color #')).at(3),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Tabs indicator color #')).at(3),
    );
    await settleTheme();

    // The live tabs in the preview column pick it up.
    await tester.scrollUntilVisible(
      find.text('NFTs'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('NFTs'));
    await settleTheme();
    expect(indicatorColor('NFTs'), const Color(0xFFDC2626));
  });

  testWidgets('playground: breadcrumb separator knob recolors the live '
      'chevrons', (tester) async {
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

    // The live trail starts on the token default.
    await tester.scrollUntilVisible(
      find.text('Portfolio'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Portfolio'));
    await settleTheme();
    Color separatorColor() => tester
        .widget<LegendCaret>(
          find
              .descendant(
                of: find.byType(LegendBreadcrumb),
                matching: find.byType(LegendCaret),
              )
              .first,
        )
        .color;
    expect(separatorColor(), LegendTokens.light.colors.foreground3);

    // Register the level-3 override through the panel's breadcrumb knob
    // (swatch 3 is 0xFFDC2626 in ColorField.defaultSwatches).
    await tester.scrollUntilVisible(
      find.textContaining('Breadcrumb separator color'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    final swatch = find
        .bySemanticsLabel(RegExp('Breadcrumb separator color .* #'))
        .at(3);
    await tester.ensureVisible(swatch);
    await settleTheme();
    await tester.tap(swatch);
    await settleTheme();

    // The live trail in the preview column picks it up.
    await tester.scrollUntilVisible(
      find.text('Portfolio'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Portfolio'));
    await settleTheme();
    expect(separatorColor(), const Color(0xFFDC2626));
  });

  testWidgets('playground: pagination selected-fill knob restyles the '
      'live pagination', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The playground preview contains LegendLoading (an unbounded
    // animation), so pumpAndSettle would never settle.
    Future<void> settleTheme() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Color currentPageFill(String label) {
      final container = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    await tester.tap(find.text('Playground'));
    await settleTheme();

    // The live pagination starts on the token default and tracks taps.
    await tester.scrollUntilVisible(
      find.byType(LegendPagination),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byType(LegendPagination));
    await settleTheme();
    expect(currentPageFill('5'), LegendTokens.light.colors.primary);
    await tester.tap(find.text('6'));
    await settleTheme();
    expect(currentPageFill('6'), LegendTokens.light.colors.primary);

    // Register the level-3 override through the panel's pagination knob
    // (swatch 3 is 0xFFDC2626 in ColorField.defaultSwatches).
    await tester.scrollUntilVisible(
      find.textContaining('Pagination selected fill'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    final swatch = find
        .bySemanticsLabel(RegExp('Pagination selected fill .* #'))
        .at(3);
    await tester.ensureVisible(swatch);
    await settleTheme();
    await tester.tap(swatch);
    await settleTheme();

    // The live pagination in the preview column picks it up.
    await tester.scrollUntilVisible(
      find.byType(LegendPagination),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byType(LegendPagination));
    await settleTheme();
    expect(currentPageFill('6'), const Color(0xFFDC2626));
  });

  testWidgets('playground: banner knob restyles the live banner', (
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

    // Register the level-3 override through the panel's banner knob
    // (swatch 3 is 0xFFDC2626 in ColorField.defaultSwatches).
    await tester.scrollUntilVisible(
      find.textContaining('Banner info background'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible stops as soon as the sliver cache builds the
    // target, which can still be off-screen — align it for the tap.
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Banner info background .* #')).at(3),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Banner info background .* #')).at(3),
    );
    await settleTheme();

    // The live banner in the preview column picks it up.
    await tester.scrollUntilVisible(
      find.text('LegendBanner'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final strip = tester.widget<LegendSurface>(
      find
          .ancestor(
            of: find.text('LegendBanner'),
            matching: find.byType(LegendSurface),
          )
          .first,
    );
    expect(strip.color, const Color(0xFFDC2626));
  });

  testWidgets('playground: empty-state icon knob recolors the live glyph', (
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

    // Register the level-3 override through the panel's empty-state knob
    // (swatch 3 is 0xFFDC2626 in ColorField.defaultSwatches).
    await tester.scrollUntilVisible(
      find.textContaining('Empty-state icon color'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible stops as soon as the sliver cache builds the
    // target, which can still be off-screen — align it for the tap.
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Empty-state icon color .* #')).at(3),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Empty-state icon color .* #')).at(3),
    );
    await settleTheme();

    // The live empty state in the preview column picks it up through the
    // IconTheme its icon slot inherits.
    await tester.scrollUntilVisible(
      find.text('LegendEmpty'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final iconTheme = tester.widget<IconTheme>(
      find
          .ancestor(
            of: find.byIcon(Icons.inbox_outlined),
            matching: find.byType(IconTheme),
          )
          .first,
    );
    expect(iconTheme.data.color, const Color(0xFFDC2626));
  });

  testWidgets('overlays page: tooltip shows on hover and hides on exit', (
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
      find.text('Hover me'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible stops as soon as the sliver cache builds the
    // target, which can still be off-screen — align it for the hover.
    await tester.ensureVisible(find.text('Hover me'));
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Hover me')));
    // Default showDelay is 500 ms.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('hovering pointer'), findsOneWidget);

    await gesture.moveTo(Offset.zero);
    // Default hideDelay grace period is 100 ms.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('hovering pointer'), findsNothing);
  });

  testWidgets('playground: tooltip delay knob retunes the live tooltip', (
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

    // Register the level-3 override through the panel's tooltip knob.
    await tester.scrollUntilVisible(
      find.textContaining('Tooltip show delay'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Theme default (500 ms)'));
    await settleTheme();
    await tester.tap(find.text('Theme default (500 ms)'));
    await settleTheme();
    await tester.tap(find.text('Instant (0 ms)'));
    await settleTheme();

    // The live tooltip in the preview column now shows without the wait.
    await tester.scrollUntilVisible(
      find.text('Hover for a tooltip'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Hover for a tooltip'));
    await settleTheme();
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Hover for a tooltip')));
    // A zero-delay timer still fires asynchronously — elapse one tick.
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.textContaining('follows the tooltip knob'), findsOneWidget);
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

  testWidgets('playground: segmented thumb knob restyles the live segmented', (
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

    // Register the level-3 override through the panel's segmented knob
    // (swatch 4 is the violet, unused by any active preset).
    await tester.scrollUntilVisible(
      find.textContaining('Segmented thumb color'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Segmented thumb color #')).at(4),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Segmented thumb color #')).at(4),
    );
    await settleTheme();

    // The live segmented in the preview column picks it up as its thumb.
    // (Scoped to the control — the ColorField swatches paint the same
    // violet on their own LegendSurfaces.)
    await tester.scrollUntilVisible(
      find.text('1H'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    expect(
      find.descendant(
        of: find.byType(LegendSegmented<String>),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is LegendSurface &&
              widget.color == const Color(0xFF8B5CF6),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('playground: slider active-track knob restyles the live '
      'slider', (tester) async {
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

    // The slider paints privately, so the assertion goes through the
    // painter's own shouldRepaint: capture it before the knob, compare
    // after.
    Finder paint() => find.descendant(
      of: find.byType(LegendSlider),
      matching: find.byType(CustomPaint),
    );
    await tester.scrollUntilVisible(
      find.byType(LegendSlider),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final before = tester.widget<CustomPaint>(paint()).painter;

    // Register the level-3 override through the panel's slider knob
    // (swatch 4 is the violet, unused by any active preset).
    await tester.scrollUntilVisible(
      find.textContaining('Slider active-track color'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Slider active-track color #')).at(4),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Slider active-track color #')).at(4),
    );
    await settleTheme();

    // The live slider in the preview column repaints with the new
    // active-track color.
    await tester.scrollUntilVisible(
      find.byType(LegendSlider),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final after = tester.widget<CustomPaint>(paint()).painter;
    expect(after!.shouldRepaint(before!), isTrue);
  });

  testWidgets('playground: split-pane divider knob restyles the live '
      'split pane', (tester) async {
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

    // Register the level-3 override through the panel's split-pane knob
    // (swatch 4 is the violet, unused by any active preset).
    await tester.scrollUntilVisible(
      find.textContaining('Split-pane divider color'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Split-pane divider color .* #')).at(4),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Split-pane divider color .* #')).at(4),
    );
    await settleTheme();

    // The live split pane's divider line picks it up. (Scoped to the
    // split pane — the ColorField swatches paint the same violet on
    // their own LegendSurfaces; the preview's panes stay background1.)
    await tester.scrollUntilVisible(
      find.byType(LegendSplitPane),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    expect(
      find.descendant(
        of: find.byType(LegendSplitPane),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is LegendSurface &&
              widget.color == const Color(0xFF8B5CF6),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('playground: drawer width knob restyles the live drawer', (
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

    // Register the level-3 override through the panel's drawer knob.
    await tester.scrollUntilVisible(
      find.text('Standard (320)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Standard (320)'));
    await settleTheme();
    await tester.tap(find.text('Standard (320)'));
    await settleTheme();
    await tester.tap(find.text('Narrow (280)'));
    await settleTheme();

    // The live drawer opener in the preview column picks it up.
    await tester.scrollUntilVisible(
      find.text('Open side drawer'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Open side drawer'));
    await settleTheme();
    await tester.tap(find.text('Open side drawer'));
    await settleTheme();
    expect(
      tester.getRect(find.byType(LegendDrawer)).width,
      280,
      reason: 'level-3 components map restyles the side-drawer width',
    );

    // Escape closes it again (the modal engine's dismissal).
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleTheme();
    expect(find.byType(LegendDrawer), findsNothing);
  });

  testWidgets('playground: combobox highlight knob restyles the live panel', (
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

    // Register the level-3 override through the panel's combobox knob
    // (swatch 4 is the violet, unused by any active preset).
    await tester.scrollUntilVisible(
      find.textContaining('Combobox option highlight'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Combobox option highlight.* #')).at(4),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Combobox option highlight.* #')).at(4),
    );
    await settleTheme();

    // Open the live combobox; its highlighted option paints the override.
    await tester.scrollUntilVisible(
      find.text('Combobox — type to filter'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    await tester.tap(find.byType(LegendCombobox<String>));
    await settleTheme();

    // (Scoped to the combobox — the ColorField swatches paint the same
    // violet on their own LegendSurfaces.)
    expect(
      find.descendant(
        of: find.byType(LegendCombobox<String>),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is LegendSurface &&
              widget.color == const Color(0xFF8B5CF6),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('playground: number-field stepper knob recolors the live '
      'stepper arrows', (tester) async {
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

    // Register the level-3 override through the panel's number-field knob.
    await tester.scrollUntilVisible(
      find.textContaining('Number-field stepper color'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Number-field stepper color .*#8B5CF6')),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Number-field stepper color .*#8B5CF6')),
    );
    await settleTheme();

    // The live number field in the preview column picks it up on both
    // stepper arrows.
    await tester.scrollUntilVisible(
      find.byType(LegendNumberField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final carets = tester.widgetList<LegendCaret>(
      find.descendant(
        of: find.byType(LegendNumberField),
        matching: find.byType(LegendCaret),
      ),
    );
    expect(carets, hasLength(2));
    expect(
      carets.every((caret) => caret.color == const Color(0xFF8B5CF6)),
      isTrue,
    );
  });

  testWidgets('playground: PIN-field knob recolors the live active-cell '
      'border', (tester) async {
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

    // Register the level-3 override through the panel's PIN-field knob.
    await tester.scrollUntilVisible(
      find.textContaining('PIN-field active-cell border'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('PIN-field active-cell border .*#8B5CF6')),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('PIN-field active-cell border .*#8B5CF6')),
    );
    await settleTheme();

    // Focus the live pin field; its active cell shows the override.
    await tester.scrollUntilVisible(
      find.byType(LegendPinField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    await tester.tap(find.byType(LegendPinField));
    await settleTheme();
    final firstCell = tester
        .widgetList<LegendSurface>(
          find.descendant(
            of: find.byType(LegendPinField),
            matching: find.byType(LegendSurface),
          ),
        )
        .first;
    expect((firstCell.border! as Border).top.color, const Color(0xFF8B5CF6));
  });

  testWidgets('playground: markdown link knob restyles the live markdown', (
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

    // Register the level-3 override through the panel's markdown knob
    // (swatch 4 is the violet, unused by any active preset).
    await tester.scrollUntilVisible(
      find.textContaining('Markdown link color'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Markdown link color .* #')).at(4),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Markdown link color .* #')).at(4),
    );
    await settleTheme();

    // The live markdown in the preview column recolors its link span.
    await tester.scrollUntilVisible(
      find.byType(LegendMarkdown),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    // visitChildren skips text-less wrapper spans (the link wrapper that
    // carries the color), so walk the span tree by hand.
    bool hasViolet(InlineSpan span) =>
        span is TextSpan &&
        (span.style?.color == const Color(0xFF8B5CF6) ||
            (span.children ?? const []).any(hasViolet));
    final texts = tester.widgetList<Text>(
      find.descendant(
        of: find.byType(LegendMarkdown),
        matching: find.byType(Text),
      ),
    );
    expect(
      texts.any((text) {
        final span = text.textSpan;
        return span != null && hasViolet(span);
      }),
      isTrue,
    );
  });

  testWidgets('playground: editor mark knob restyles the live editor', (
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

    // Register the level-3 override through the panel's editor knob
    // (swatch 4 is the violet, unused by any active preset).
    await tester.scrollUntilVisible(
      find.textContaining('Markdown editor mark color'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Markdown editor mark color .* #')).at(4),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Markdown editor mark color .* #')).at(4),
    );
    await settleTheme();

    // The live editor hands its resolved source style to the controller —
    // the syntax marks now carry the override.
    await tester.scrollUntilVisible(
      find.byType(LegendMarkdownEditor),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final editable = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(LegendMarkdownEditor),
        matching: find.byType(EditableText),
      ),
    );
    final controller = editable.controller as LegendMarkdownEditingController;
    expect(controller.sourceStyle.syntaxMarkColor, const Color(0xFF8B5CF6));
  });

  testWidgets('playground: code-block fill knob restyles the live panel', (
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

    // Register the level-3 override through the panel's code-block knob
    // (swatch 4 is the violet, unused by any active preset).
    await tester.scrollUntilVisible(
      find.textContaining('Code-block panel fill'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Code-block panel fill .* #')).at(4),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Code-block panel fill .* #')).at(4),
    );
    await settleTheme();

    // The live code block in the preview column refills its panel.
    await tester.scrollUntilVisible(
      find.byType(LegendCodeBlock),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(LegendCodeBlock),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (container.decoration! as BoxDecoration).color,
      const Color(0xFF8B5CF6),
    );
  });

  testWidgets('playground: copy confirmation knob restyles the live address', (
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

    // Register the level-3 override through the panel's copy knob
    // (swatch 4 is the violet, unused by any active preset).
    await tester.scrollUntilVisible(
      find.textContaining('Copy confirmation color'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Copy confirmation color .*#8B5CF6')),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Copy confirmation color .*#8B5CF6')),
    );
    await settleTheme();

    // The live LegendAddress's built-in copy button resolves it — the
    // truncated run itself is untouched by the knob.
    await tester.scrollUntilVisible(
      find.byType(LegendAddress),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    expect(find.text('0x8f3C…A063'), findsOneWidget);
    final buttonContext = tester.element(
      find
          .descendant(
            of: find.byType(LegendAddress),
            matching: find.byType(LegendCopyButton),
          )
          .first,
    );
    expect(
      LegendCopyButtonTheme.of(buttonContext).confirmationColor,
      const Color(0xFF8B5CF6),
    );
  });

  testWidgets('playground: preview sections render every new live demo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The playground preview contains LegendLoading and LegendShimmer
    // (unbounded animations), so pumpAndSettle would never settle.
    Future<void> settleTheme() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> reach(Finder finder) async {
      await tester.scrollUntilVisible(
        finder.first,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(finder.first);
      await settleTheme();
    }

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    await tester.tap(find.text('Playground'));
    await settleTheme();

    // Buttons & actions: the standalone copy button.
    await reach(find.text('Copy a value with the standalone button'));
    expect(find.byType(LegendCopyButton), findsWidgets);

    // Inputs & forms: the live two-field form gates submit on validity.
    await reach(find.text('Submit form'));
    final submit = tester.widget<PrimaryLegendButton>(
      find.ancestor(
        of: find.text('Submit form'),
        matching: find.byType(PrimaryLegendButton),
      ),
    );
    expect(submit.enabled, isFalse, reason: 'empty form is invalid');

    // Selection controls: the local switch flips independently.
    await reach(find.text('Switch — on'));
    await tester.tap(find.bySemanticsLabel('Playground switch'));
    await settleTheme();
    expect(find.text('Switch — off'), findsOneWidget);

    // Overlay surfaces: the context-menu target renders.
    await reach(find.textContaining('Right-click or long-press'));

    // The dialog opener runs the real modal route.
    await reach(find.text('Open dialog'));
    await tester.tap(find.text('Open dialog'));
    await settleTheme();
    expect(find.text('Playground dialog'), findsOneWidget);
    await tester.tap(find.text('Close dialog'));
    await settleTheme();
    expect(find.text('Playground dialog'), findsNothing);

    // The toast trigger fires the site-wide host.
    await tester.tap(find.text('Show a toast'));
    await settleTheme();
    expect(find.text('Toast from the playground'), findsOneWidget);
    // Elapse the toast's auto-dismiss timer before moving on.
    await tester.pump(const Duration(seconds: 6));

    // Navigation & shell: the embedded bottom bar tracks taps.
    await reach(find.text('Feed'));
    await tester.tap(find.text('Feed'));
    await settleTheme();

    // Layout & data display: info items, the divider demo, and the
    // expandable's tap-to-toggle reveal.
    await reach(find.text('Chain'));
    expect(find.text('Polygon'), findsOneWidget);
    await reach(find.text('Above the divider rule'));
    await reach(find.text('Expandable — tap to toggle'));
    await tester.tap(find.text('Expandable — tap to toggle'));
    await settleTheme();
    expect(find.textContaining('revealed content animates'), findsOneWidget);

    // Feedback & status: shimmer placeholders are live.
    await reach(find.byType(LegendShimmer));

    // Content & typography closes the column.
    await reach(find.text('Content & typography'));
  });

  testWidgets('docs pages: every shipped widget exposes a theme-surface '
      'table', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Feedback (LegendLoading/LegendShimmer) animates unbounded, so pump
    // explicitly instead of pumpAndSettle.
    Future<void> settleTheme() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    // Nav label -> theme-surface sections that page must carry (the
    // buttons/selection pages keep their older hand-written tables for
    // Primary/Radio/Chip/Dropdown/Segmented on top of these).
    const expectations = {
      'Buttons': ['SecondaryLegendButton', 'LegendTextButton'],
      'Typography': [
        'LegendMarkdown',
        'LegendMarkdownEditor',
        'LegendCodeBlock',
        'LegendAddress',
        'LegendCopyButton',
      ],
      'Inputs': [
        'LegendTextField',
        'LegendCombobox',
        'LegendNumberField',
        'LegendPinField',
        'LegendSlider',
      ],
      'Selection': ['LegendCheckbox', 'LegendSwitch'],
      'Overlays': [
        'LegendDialog',
        'LegendDrawer',
        'LegendToast',
        'LegendPopover',
        'LegendTooltip',
        'LegendMenu',
        'LegendContextMenu',
      ],
      'Layout': [
        'LegendCard',
        'LegendDivider',
        'LegendSplitPane',
        'LegendExpandable',
        'LegendAccordion',
        'LegendBody',
        'LegendAvatar',
        'LegendInfoItem',
        'LegendStat',
        'LegendList',
        'LegendListItem',
        'LegendTimeline',
        'LegendBadge',
      ],
      'Feedback': [
        'LegendBanner',
        'LegendEmpty',
        'LegendLoading',
        'LegendProgress',
        'LegendSteps',
        'LegendShimmer',
      ],
      'Shell': [
        'LegendScaffold',
        'LegendAppBar',
        'LegendSider',
        'LegendBottomBar',
        'LegendTabs',
        'LegendBreadcrumb',
        'LegendPagination',
        'LegendVerticalMenu',
      ],
    };

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    for (final page in expectations.entries) {
      await tester.tap(find.text(page.key).first);
      await settleTheme();
      for (final component in page.value) {
        expect(
          find.text('$component theme surface'),
          findsOneWidget,
          reason: '${page.key} page must document $component',
        );
      }
    }
  });

  testWidgets('typography page: one custom syntax registration feeds the '
      'editor and the renderer', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> settleTheme() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    await tester.tap(find.text('Typography'));
    await settleTheme();

    // Renderer side: the #LEG-42 reference renders as the custom span —
    // semibold, not plain prose.
    bool hasTicket(InlineSpan span) =>
        span is TextSpan &&
        ((span.text == '#LEG-42' &&
                span.style?.fontWeight == FontWeight.w600) ||
            (span.children ?? const []).any(hasTicket));
    final texts = tester.widgetList<Text>(
      find.descendant(
        of: find.byType(LegendMarkdown),
        matching: find.byType(Text),
      ),
    );
    expect(
      texts.any((text) {
        final span = text.textSpan;
        return span != null && hasTicket(span);
      }),
      isTrue,
      reason: 'the renderer must build the ticketRef span',
    );

    // Editor side: the very same registration is wired into the editing
    // controller, so the raw source highlights while typing.
    final controller = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((editable) => editable.controller)
        .whereType<LegendMarkdownEditingController>()
        .firstWhere((candidate) => candidate.text.contains('#LEG-42'));
    expect(controller.syntaxes.single.tag, 'ticketRef');
    expect(controller.syntaxes.single.highlight, isNotNull);
  });

  testWidgets('playground: steps completed knob restyles the live steps', (
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

    // Register the level-3 override through the panel's steps knob.
    await tester.scrollUntilVisible(
      find.textContaining('Steps completed fill'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Steps completed fill .*#8B5CF6')),
    );
    await settleTheme();
    await tester.tap(
      find.bySemanticsLabel(RegExp('Steps completed fill .*#8B5CF6')),
    );
    await settleTheme();

    // The live steps in the preview column repaint their completed
    // indicators; the pending one keeps resolving downward.
    await tester.scrollUntilVisible(
      find.byType(LegendSteps),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleTheme();
    final completed = find.descendant(
      of: find.byType(LegendSteps),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is LegendSurface && widget.color == const Color(0xFF8B5CF6),
      ),
    );
    expect(completed, findsNWidgets(2));
  });
}
