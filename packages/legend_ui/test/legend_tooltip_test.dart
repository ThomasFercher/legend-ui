import 'package:flutter/gestures.dart';
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
}) {
  return LegendTheme(
    data: data,
    child: Directionality(
      textDirection: TextDirection.ltr,
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

/// A mouse pointer parked away from the trigger, cleaned up on teardown.
Future<TestGesture> _mouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  return gesture;
}

void main() {
  group('hover', () {
    testWidgets('shows after showDelay, not before', (tester) async {
      await tester.pumpWidget(
        _app(LegendTooltip(message: 'Hint', child: _trigger())),
      );
      final gesture = await _mouse(tester);
      await gesture.moveTo(tester.getCenter(find.text('Trigger')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hint'), findsNothing);

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Hint'), findsOneWidget);
    });

    testWidgets('exit before showDelay cancels the pending show', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(LegendTooltip(message: 'Hint', child: _trigger())),
      );
      final gesture = await _mouse(tester);
      await gesture.moveTo(tester.getCenter(find.text('Trigger')));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.moveTo(Offset.zero);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Hint'), findsNothing);
    });

    testWidgets('hides hideDelay after the pointer leaves', (tester) async {
      await tester.pumpWidget(
        _app(LegendTooltip(message: 'Hint', child: _trigger())),
      );
      final gesture = await _mouse(tester);
      await gesture.moveTo(tester.getCenter(find.text('Trigger')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Hint'), findsOneWidget);

      await gesture.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 50));
      // Still inside the grace period.
      expect(find.text('Hint'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Hint'), findsNothing);
    });

    testWidgets('re-entering within hideDelay keeps the hint up', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(LegendTooltip(message: 'Hint', child: _trigger())),
      );
      final gesture = await _mouse(tester);
      final center = tester.getCenter(find.text('Trigger'));
      await gesture.moveTo(center);
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(center);
      // Well past the grace period: the pending hide must be cancelled.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Hint'), findsOneWidget);
    });

    testWidgets('disabled: hover never shows', (tester) async {
      await tester.pumpWidget(
        _app(LegendTooltip(message: 'Hint', enabled: false, child: _trigger())),
      );
      final gesture = await _mouse(tester);
      await gesture.moveTo(tester.getCenter(find.text('Trigger')));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Hint'), findsNothing);
    });
  });

  group('focus and keyboard', () {
    testWidgets('shows immediately on focus, hides on blur', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _app(
          LegendTooltip(
            message: 'Hint',
            child: Focus(focusNode: node, child: _trigger()),
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Hint'), findsOneWidget);

      node.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('Hint'), findsNothing);
    });

    testWidgets('Escape hides the hint while the trigger keeps focus', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _app(
          LegendTooltip(
            message: 'Hint',
            child: Focus(focusNode: node, child: _trigger()),
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Hint'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Hint'), findsNothing);
      expect(node.hasFocus, isTrue);
    });
  });

  group('touch', () {
    testWidgets('long-press shows; an outside tap dismisses', (tester) async {
      await tester.pumpWidget(
        _app(LegendTooltip(message: 'Hint', child: _trigger())),
      );
      await tester.longPress(find.text('Trigger'));
      await tester.pump();
      expect(find.text('Hint'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(find.text('Hint'), findsNothing);
    });
  });

  group('content and semantics', () {
    testWidgets('message renders through LegendText in the themed style', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(LegendTooltip(message: 'Hint', child: _trigger())),
      );
      await tester.longPress(find.text('Trigger'));
      await tester.pump();
      final text = tester.widget<LegendText>(
        find.widgetWithText(LegendText, 'Hint'),
      );
      expect(text.style, LegendTokens.light.typography.b3);
    });

    testWidgets('richMessage renders arbitrary content', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendTooltip(
            richMessage: const SizedBox(
              key: Key('rich'),
              width: 120,
              height: 60,
            ),
            semanticLabel: 'Preview',
            child: _trigger(),
          ),
        ),
      );
      await tester.longPress(find.text('Trigger'));
      await tester.pump();
      expect(find.byKey(const Key('rich')), findsOneWidget);
    });

    testWidgets('maxWidth bounds the panel; long messages wrap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          LegendTooltip(
            message: 'A very long explanation ' * 20,
            child: _trigger(),
          ),
        ),
      );
      await tester.longPress(find.text('Trigger'));
      await tester.pump();
      final panel = tester.getRect(find.byType(LegendSurface));
      final padding = EdgeInsets.all(LegendTokens.light.sizes.md);
      expect(panel.width, lessThanOrEqualTo(320 + padding.horizontal));
    });

    testWidgets('announces the message as the semantic tooltip', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(LegendTooltip(message: 'Hint', child: _trigger())),
      );
      expect(
        tester.getSemantics(find.text('Trigger')),
        containsSemantics(tooltip: 'Hint'),
      );
      handle.dispose();
    });
  });

  group('themed resolution', () {
    testWidgets('registry entry (level 3) retunes the delays', (tester) async {
      await tester.pumpWidget(
        _app(
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendTooltip: LegendTooltipThemeNullable(
                showDelay: Duration.zero,
              ),
            },
          ),
          LegendTooltip(message: 'Hint', child: _trigger()),
        ),
      );
      final gesture = await _mouse(tester);
      await gesture.moveTo(tester.getCenter(find.text('Trigger')));
      // A zero-delay timer still fires asynchronously — elapse one tick.
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Hint'), findsOneWidget);
    });

    testWidgets('constructor param (level 1) wins over the registry', (
      tester,
    ) async {
      const coral = TextStyle(color: Color(0xFFFF6F61), fontSize: 11);
      await tester.pumpWidget(
        _app(
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendTooltip: LegendTooltipThemeNullable(
                textStyle: TextStyle(fontSize: 9),
              ),
            },
          ),
          LegendTooltip(message: 'Hint', textStyle: coral, child: _trigger()),
        ),
      );
      await tester.longPress(find.text('Trigger'));
      await tester.pump();
      final text = tester.widget<LegendText>(
        find.widgetWithText(LegendText, 'Hint'),
      );
      expect(text.style, coral);
    });

    testWidgets('subtree override (level 2) beats the registry', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendTooltip: LegendTooltipThemeNullable(maxWidth: 500),
            },
          ),
          LegendTooltipThemeOverride(
            data: const LegendTooltipThemeNullable(maxWidth: 120),
            child: LegendTooltip(
              message: 'A very long explanation ' * 20,
              child: _trigger(),
            ),
          ),
        ),
      );
      await tester.longPress(find.text('Trigger'));
      await tester.pump();
      final panel = tester.getRect(find.byType(LegendSurface));
      final padding = EdgeInsets.all(LegendTokens.light.sizes.md);
      expect(panel.width, lessThanOrEqualTo(120 + padding.horizontal));
    });
  });

  group('placement', () {
    testWidgets('default: above the trigger with a token-sized gap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(LegendTooltip(message: 'Hint', child: _trigger())),
      );
      await tester.longPress(find.text('Trigger'));
      await tester.pump();
      final trigger = tester.getRect(find.text('Trigger').first);
      final panel = tester.getRect(find.byType(LegendSurface));
      expect(panel.bottom, trigger.top - LegendTokens.light.sizes.xs);
      expect(panel.center.dx, closeTo(trigger.center.dx, 0.01));
    });

    testWidgets('bottom placement flips the gap below', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendTooltip(
            message: 'Hint',
            placement: LegendPopoverPlacement.bottom,
            child: _trigger(),
          ),
        ),
      );
      await tester.longPress(find.text('Trigger'));
      await tester.pump();
      final trigger = tester.getRect(find.text('Trigger').first);
      final panel = tester.getRect(find.byType(LegendSurface));
      expect(panel.top, trigger.bottom + LegendTokens.light.sizes.xs);
    });
  });
}
