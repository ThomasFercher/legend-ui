import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

Widget _wrap(Widget child) {
  return NomoTheme(
    data: const NomoThemeData(tokens: NomoTokens.light),
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
  return NomoInteractive(
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
  group('NomoInteractive', () {
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
        tester.getCenter(find.byType(NomoInteractive)),
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
          .getSemantics(find.byType(NomoInteractive))
          .flagsCollection;
      expect(flags.isToggled, Tristate.isFalse);
      expect(flags.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('null toggled stays a plain button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(_probe(onTap: () {})));
      final flags = tester
          .getSemantics(find.byType(NomoInteractive))
          .flagsCollection;
      expect(flags.isButton, isTrue);
      expect(flags.isToggled, Tristate.none);
      handle.dispose();
    });
  });
}
