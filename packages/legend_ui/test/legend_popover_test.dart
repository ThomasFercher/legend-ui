import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

/// Overlay harness: `TapRegionSurface` (WidgetsApp installs it in real
/// apps; dismissal depends on it) plus a hit-testable backdrop so outside
/// taps reach *something*.
Widget _app(
  Widget child, {
  LegendThemeData data = const LegendThemeData(tokens: LegendTokens.light),
  TextDirection direction = TextDirection.ltr,
}) {
  return LegendTheme(
    data: data,
    child: Directionality(
      textDirection: direction,
      child: TapRegionSurface(
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: Center(child: child),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _trigger() =>
    const SizedBox(width: 80, height: 40, child: Text('Trigger'));

void main() {
  group('open and close', () {
    testWidgets('tap toggles the panel', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendPopover(
            overlay: (context) => const Text('Panel'),
            child: _trigger(),
          ),
        ),
      );
      expect(find.text('Panel'), findsNothing);

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsOneWidget);

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsNothing);
    });

    testWidgets('outside tap dismisses and syncs the controller', (
      tester,
    ) async {
      final controller = LegendPopoverController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          LegendPopover(
            controller: controller,
            overlay: (context) => const Text('Panel'),
            child: _trigger(),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsNothing);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('Escape dismisses the focused panel', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendPopover(
            overlay: (context) => const Text('Panel'),
            child: _trigger(),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsNothing);
    });

    testWidgets('disabled trigger never opens', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendPopover(
            enabled: false,
            overlay: (context) => const Text('Panel'),
            child: _trigger(),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsNothing);
    });
  });

  group('controller and manual trigger', () {
    testWidgets('manual: taps are inert, show/hide drive the panel', (
      tester,
    ) async {
      final controller = LegendPopoverController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          LegendPopover(
            controller: controller,
            trigger: LegendPopoverTrigger.manual,
            overlay: (context) => const Text('Panel'),
            child: _trigger(),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsNothing);

      controller.show();
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsOneWidget);

      controller.hide();
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsNothing);
    });

    testWidgets('notifies listeners on open-state changes only', (
      tester,
    ) async {
      final controller = LegendPopoverController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      await tester.pumpWidget(
        _app(
          LegendPopover(
            controller: controller,
            trigger: LegendPopoverTrigger.manual,
            overlay: (context) => const Text('Panel'),
            child: _trigger(),
          ),
        ),
      );
      controller
        ..show()
        ..show(); // second call is a no-op
      await tester.pumpAndSettle();
      expect(notifications, 1);

      controller.toggle(); // open -> closed
      await tester.pumpAndSettle();
      expect(notifications, 2);
      expect(controller.isOpen, isFalse);
    });
  });

  group('placement', () {
    Future<void> pumpPlacement(
      WidgetTester tester,
      LegendPopoverPlacement placement, {
      TextDirection direction = TextDirection.ltr,
    }) async {
      await tester.pumpWidget(
        _app(
          direction: direction,
          LegendPopover(
            placement: placement,
            // Zero padding so panel geometry equals content geometry.
            padding: EdgeInsets.zero,
            overlay: (context) =>
                const SizedBox(width: 40, height: 20, child: Text('P')),
            child: _trigger(),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
    }

    testWidgets('bottom: panel top edge meets trigger bottom edge', (
      tester,
    ) async {
      await pumpPlacement(tester, LegendPopoverPlacement.bottom);
      final trigger = tester.getRect(find.text('Trigger').first);
      final panel = tester.getRect(find.byType(LegendSurface));
      expect(panel.top, trigger.bottom);
      expect(panel.center.dx, closeTo(trigger.center.dx, 0.01));
    });

    testWidgets('top: panel bottom edge meets trigger top edge', (
      tester,
    ) async {
      await pumpPlacement(tester, LegendPopoverPlacement.top);
      final trigger = tester.getRect(find.text('Trigger').first);
      final panel = tester.getRect(find.byType(LegendSurface));
      expect(panel.bottom, trigger.top);
      expect(panel.center.dx, closeTo(trigger.center.dx, 0.01));
    });

    testWidgets('end (LTR): panel sits to the right of the trigger', (
      tester,
    ) async {
      await pumpPlacement(tester, LegendPopoverPlacement.end);
      final trigger = tester.getRect(find.text('Trigger').first);
      final panel = tester.getRect(find.byType(LegendSurface));
      expect(panel.left, trigger.right);
      expect(panel.center.dy, closeTo(trigger.center.dy, 0.01));
    });

    testWidgets('end (RTL) flips to the left of the trigger', (tester) async {
      await pumpPlacement(
        tester,
        LegendPopoverPlacement.end,
        direction: TextDirection.rtl,
      );
      final trigger = tester.getRect(find.text('Trigger').first);
      final panel = tester.getRect(find.byType(LegendSurface));
      expect(panel.right, trigger.left);
    });

    testWidgets('offset shifts the panel after placement', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendPopover(
            offset: const Offset(0, 12),
            padding: EdgeInsets.zero,
            overlay: (context) =>
                const SizedBox(width: 40, height: 20, child: Text('P')),
            child: _trigger(),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      final trigger = tester.getRect(find.text('Trigger').first);
      final panel = tester.getRect(find.byType(LegendSurface));
      expect(panel.top, trigger.bottom + 12);
    });

    testWidgets('showArrow inserts the anchor wedge before the panel', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          LegendPopover(
            showArrow: true,
            padding: EdgeInsets.zero,
            overlay: (context) =>
                const SizedBox(width: 40, height: 20, child: Text('P')),
            child: _trigger(),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      final trigger = tester.getRect(find.text('Trigger').first);
      final panel = tester.getRect(find.byType(LegendSurface));
      // Panel bottom-placed: the wedge occupies sizes.sm between the two.
      expect(panel.top, trigger.bottom + LegendTokens.light.sizes.sm);
      expect(
        find.descendant(
          of: find.byType(LegendAnchoredOverlay),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    });
  });

  group('themed resolution', () {
    const navy = Color(0xFF001F54);
    const coral = Color(0xFFFF6F61);

    LegendSurface panelSurface(WidgetTester tester) =>
        tester.widget<LegendSurface>(find.byType(LegendSurface));

    testWidgets('defaults derive from tokens', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendPopover(
            overlay: (context) => const Text('Panel'),
            child: _trigger(),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      final surface = panelSurface(tester);
      expect(surface.color, LegendTokens.light.colors.surface);
      expect(surface.borderRadius, LegendTokens.light.sizes.borderRadiusMd);
      expect(surface.shadows, LegendTokens.light.shadows.medium);
      expect(surface.padding, EdgeInsets.all(LegendTokens.light.sizes.md));
    });

    testWidgets('registry entry (level 3) restyles the panel', (tester) async {
      await tester.pumpWidget(
        _app(
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendPopover: LegendPopoverThemeNullable(background: navy),
            },
          ),
          LegendPopover(
            overlay: (context) => const Text('Panel'),
            child: _trigger(),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      final surface = panelSurface(tester);
      expect(surface.color, navy);
      // Sparse: unset members keep resolving through the lower levels.
      expect(surface.borderRadius, LegendTokens.light.sizes.borderRadiusMd);
    });

    testWidgets('constructor param (level 1) wins over the registry', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendPopover: LegendPopoverThemeNullable(background: navy),
            },
          ),
          LegendPopover(
            background: coral,
            overlay: (context) => const Text('Panel'),
            child: _trigger(),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(panelSurface(tester).color, coral);
    });

    testWidgets('subtree override (level 2) beats the registry', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendPopover: LegendPopoverThemeNullable(background: navy),
            },
          ),
          LegendPopoverThemeOverride(
            data: const LegendPopoverThemeNullable(background: coral),
            child: LegendPopover(
              overlay: (context) => const Text('Panel'),
              child: _trigger(),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(panelSurface(tester).color, coral);
    });
  });
}
