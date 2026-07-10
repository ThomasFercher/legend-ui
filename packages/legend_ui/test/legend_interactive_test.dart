import 'dart:ui' show PointerDeviceKind, SemanticsAction, Tristate;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child) {
  return LegendTheme(
    data: const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

/// The builder paints pressed state into a color so tests can read it back.
Widget _probe({
  VoidCallback? onTap,
  bool enabled = true,
  bool? toggled,
  FocusNode? focusNode,
}) {
  return LegendInteractive(
    onTap: onTap,
    enabled: enabled,
    toggled: toggled,
    focusNode: focusNode,
    builder: (context, states) => ColoredBox(
      color: states.pressed ? const Color(0xFFFF0000) : const Color(0xFF00FF00),
      child: const SizedBox.square(dimension: 48),
    ),
  );
}

Color _probeColor(WidgetTester tester) =>
    tester.widget<ColoredBox>(find.byType(ColoredBox)).color;

void main() {
  group('LegendInteractive', () {
    testWidgets('disabling mid-press clears pressed (review I1)', (
      tester,
    ) async {
      var enabled = true;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return _probe(onTap: () {}, enabled: enabled);
            },
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(LegendInteractive)),
      );
      await tester.pump();
      expect(_probeColor(tester), const Color(0xFFFF0000));

      // Disable while the finger is still down — the release callbacks are
      // nulled, so without the didUpdateWidget reset this sticks.
      rebuild(() => enabled = false);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      rebuild(() => enabled = true);
      await tester.pump();
      expect(
        _probeColor(tester),
        const Color(0xFF00FF00),
        reason: 're-enabled widget must not resurrect stale pressed state',
      );
    });

    testWidgets('keyboard activation via Enter and Space', (tester) async {
      var taps = 0;
      final focusNode = FocusNode();
      await tester.pumpWidget(
        _wrap(_probe(onTap: () => taps++, focusNode: focusNode)),
      );
      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(taps, 2);
      focusNode.dispose();
    });

    testWidgets('non-null toggled announces toggle semantics (review I3)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(_probe(onTap: () {}, toggled: false)));
      final flags = tester
          .getSemantics(find.byType(LegendInteractive))
          .flagsCollection;
      expect(flags.isToggled, Tristate.isFalse);
      expect(flags.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('null toggled stays a plain button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(_probe(onTap: () {})));
      final flags = tester
          .getSemantics(find.byType(LegendInteractive))
          .flagsCollection;
      expect(flags.isButton, isTrue);
      expect(flags.isToggled, Tristate.none);
      handle.dispose();
    });

    testWidgets('the labeled semantics node carries the tap action', (
      tester,
    ) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(_probe(onTap: () => taps++)));
      final node = tester.getSemantics(find.byType(LegendInteractive));
      // Assistive tech (and semantics-driven tooling) activates the node it
      // announces — the action must live on the labeled node itself.
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      expect(taps, 1);
      handle.dispose();
    });
  });

  group('LegendInteractive — widened vocabulary', () {
    testWidgets('onSecondaryTap fires with the local pointer position', (
      tester,
    ) async {
      Offset? at;
      await tester.pumpWidget(
        _wrap(
          LegendInteractive(
            onSecondaryTap: (p) => at = p,
            builder: (context, states) => const SizedBox.square(dimension: 48),
          ),
        ),
      );
      final topLeft = tester.getTopLeft(find.byType(LegendInteractive));
      final gesture = await tester.startGesture(
        topLeft + const Offset(12, 8),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pump();
      expect(at, const Offset(12, 8));
    });

    testWidgets('onLongPress fires with the local press position', (
      tester,
    ) async {
      Offset? at;
      await tester.pumpWidget(
        _wrap(
          LegendInteractive(
            onLongPress: (p) => at = p,
            builder: (context, states) => const SizedBox.square(dimension: 48),
          ),
        ),
      );
      final topLeft = tester.getTopLeft(find.byType(LegendInteractive));
      await tester.longPressAt(topLeft + const Offset(20, 20));
      await tester.pump();
      expect(at, const Offset(20, 20));
    });

    testWidgets('onHoverChange reports enter and exit', (tester) async {
      final events = <bool>[];
      await tester.pumpWidget(
        _wrap(
          LegendInteractive(
            onHoverChange: events.add,
            builder: (context, states) => const SizedBox.square(dimension: 48),
          ),
        ),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(500, 500));
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byType(LegendInteractive)));
      await tester.pump();
      expect(events, [true]);
      await gesture.moveTo(const Offset(500, 500));
      await tester.pump();
      expect(events, [true, false]);
    });

    testWidgets('disabled is inert to onHoverChange (legacy "disabled '
        'buttons stay tappable" regression)', (tester) async {
      final hover = <bool>[];
      await tester.pumpWidget(
        _wrap(
          LegendInteractive(
            enabled: false,
            onHoverChange: hover.add,
            builder: (context, states) => const SizedBox.square(dimension: 48),
          ),
        ),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(500, 500));
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(LegendInteractive)));
      await tester.pump();
      expect(hover, isEmpty);
    });

    testWidgets('disabled is inert to secondary tap and long-press '
        '(legacy "disabled buttons stay tappable" regression)', (tester) async {
      var secondary = 0;
      var long = 0;
      await tester.pumpWidget(
        _wrap(
          LegendInteractive(
            enabled: false,
            onSecondaryTap: (_) => secondary++,
            onLongPress: (_) => long++,
            builder: (context, states) => const SizedBox.square(dimension: 48),
          ),
        ),
      );
      final center = tester.getCenter(find.byType(LegendInteractive));

      final secondaryTap = await tester.startGesture(
        center,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await secondaryTap.up();
      await secondaryTap.removePointer();
      await tester.pump();
      await tester.longPressAt(center);
      await tester.pump();

      expect(secondary, 0);
      expect(long, 0);
    });

    testWidgets('a context-menu-only wrapper (no onTap) still triggers on '
        'secondary tap', (tester) async {
      var opens = 0;
      await tester.pumpWidget(
        _wrap(
          LegendInteractive(
            onSecondaryTap: (_) => opens++,
            builder: (context, states) => const SizedBox.square(dimension: 48),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(LegendInteractive)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pump();
      expect(opens, 1);
    });
  });
}
