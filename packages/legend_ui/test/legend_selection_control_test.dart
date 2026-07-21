import 'dart:ui'
    show CheckedState, PointerDeviceKind, SemanticsAction, Tristate;

import 'package:flutter/semantics.dart' show SemanticsNode;
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

/// The builder paints its state into colors so tests can read it back:
/// red = pressed, blue = selected, yellow = indeterminate, green = rest.
Widget _probe({
  bool? selected = false,
  ValueChanged<bool?>? onChanged,
  LegendSelectionRole role = LegendSelectionRole.checkbox,
  bool enabled = true,
  bool tristate = false,
  FocusNode? focusNode,
  ValueChanged<bool>? onHoverChange,
  ValueChanged<LegendSelectionState>? onState,
}) {
  return LegendSelectionControl(
    selected: selected,
    onChanged: onChanged,
    role: role,
    enabled: enabled,
    tristate: tristate,
    focusNode: focusNode,
    onHoverChange: onHoverChange,
    builder: (context, state) {
      onState?.call(state);
      return ColoredBox(
        color: state.pressed
            ? const Color(0xFFFF0000)
            : state.indeterminate
            ? const Color(0xFFFFFF00)
            : state.selected
            ? const Color(0xFF0000FF)
            : const Color(0xFF00FF00),
        child: const SizedBox.square(dimension: 48),
      );
    },
  );
}

Color _probeColor(WidgetTester tester) =>
    tester.widget<ColoredBox>(find.byType(ColoredBox)).color;

void main() {
  group('LegendSelectionControl — state transitions', () {
    testWidgets('tap toggles false → true and true → false', (tester) async {
      bool? next;
      await tester.pumpWidget(_wrap(_probe(onChanged: (v) => next = v)));
      await tester.tap(find.byType(LegendSelectionControl));
      expect(next, isTrue);

      await tester.pumpWidget(
        _wrap(_probe(selected: true, onChanged: (v) => next = v)),
      );
      await tester.tap(find.byType(LegendSelectionControl));
      expect(next, isFalse);
    });

    testWidgets('tristate cycles false → true → null → false', (tester) async {
      bool? next;
      Future<void> pumpAndTap({required bool? value}) async {
        await tester.pumpWidget(
          _wrap(
            _probe(selected: value, tristate: true, onChanged: (v) => next = v),
          ),
        );
        await tester.tap(find.byType(LegendSelectionControl));
      }

      await pumpAndTap(value: false);
      expect(next, isTrue);
      await pumpAndTap(value: true);
      expect(next, isNull);
      await pumpAndTap(value: null);
      expect(next, isFalse);
    });

    testWidgets('builder receives selected and indeterminate values', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_probe(onChanged: (_) {})));
      expect(_probeColor(tester), const Color(0xFF00FF00));

      await tester.pumpWidget(_wrap(_probe(selected: true, onChanged: (_) {})));
      expect(_probeColor(tester), const Color(0xFF0000FF));

      await tester.pumpWidget(
        _wrap(_probe(selected: null, tristate: true, onChanged: (_) {})),
      );
      expect(_probeColor(tester), const Color(0xFFFFFF00));
    });

    testWidgets('press paints the pressed state and releases clean', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_probe(onChanged: (_) {})));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(LegendSelectionControl)),
      );
      await tester.pump();
      expect(_probeColor(tester), const Color(0xFFFF0000));
      await gesture.up();
      await tester.pump();
      expect(_probeColor(tester), const Color(0xFF00FF00));
    });

    testWidgets('effective maps the ladder — disabled beats pressed beats '
        'hovered beats focused beats normal', (tester) async {
      const state = LegendSelectionState(
        selected: true,
        indeterminate: false,
        hovered: true,
        pressed: true,
        focused: true,
        disabled: true,
      );
      expect(state.effective, isA<LegendStateDisabled>());
      const pressed = LegendSelectionState(
        selected: false,
        indeterminate: false,
        hovered: true,
        pressed: true,
        focused: true,
        disabled: false,
      );
      expect(pressed.effective, isA<LegendStatePressed>());
      const hovered = LegendSelectionState(
        selected: false,
        indeterminate: false,
        hovered: true,
        pressed: false,
        focused: true,
        disabled: false,
      );
      expect(hovered.effective, isA<LegendStateHovered>());
      const focused = LegendSelectionState(
        selected: false,
        indeterminate: false,
        hovered: false,
        pressed: false,
        focused: true,
        disabled: false,
      );
      expect(focused.effective, isA<LegendStateFocused>());
      const normal = LegendSelectionState(
        selected: false,
        indeterminate: false,
        hovered: false,
        pressed: false,
        focused: false,
        disabled: false,
      );
      expect(normal.effective, isA<LegendStateNormal>());
    });

    testWidgets('non-tristate null selected asserts', (tester) async {
      expect(
        () => LegendSelectionControl(
          selected: null,
          onChanged: (_) {},
          role: LegendSelectionRole.checkbox,
          builder: (context, state) => const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('LegendSelectionControl — keyboard activation', () {
    testWidgets('Enter and Space activate with the next value', (tester) async {
      final values = <bool?>[];
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _wrap(_probe(onChanged: values.add, focusNode: focusNode)),
      );
      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(values, [true]);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(values, [true, true]);
    });

    testWidgets('focus paints the focused state', (tester) async {
      // The focus highlight only shows in traditional (keyboard) highlight
      // mode; the test platform defaults to touch.
      final strategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = strategy);
      LegendSelectionState? last;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _wrap(
          _probe(
            onChanged: (_) {},
            focusNode: focusNode,
            onState: (s) => last = s,
          ),
        ),
      );
      expect(last!.focused, isFalse);
      focusNode.requestFocus();
      // One pump applies the focus change, a second rebuilds with the
      // highlight callback's setState.
      await tester.pump();
      await tester.pump();
      expect(last!.focused, isTrue);
    });
  });

  group('LegendSelectionControl — disabled is fully inert', () {
    testWidgets('no tap, no keyboard, no focus while disabled (legacy '
        '"disabled buttons stay tappable" regression)', (tester) async {
      final values = <bool?>[];
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _wrap(
          _probe(enabled: false, onChanged: values.add, focusNode: focusNode),
        ),
      );

      await tester.tap(find.byType(LegendSelectionControl));
      await tester.pump();
      expect(values, isEmpty);

      // A disabled control must refuse focus entirely — so keyboard
      // activation has nothing to land on.
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(values, isEmpty);
    });

    testWidgets('null onChanged is disabled too', (tester) async {
      await tester.pumpWidget(_wrap(_probe()));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(LegendSelectionControl)),
      );
      await tester.pump();
      expect(
        _probeColor(tester),
        const Color(0xFF00FF00),
        reason: 'an onChanged-less control must not paint pressed',
      );
      await gesture.up();
    });

    testWidgets('disabled is inert to onHoverChange', (tester) async {
      final hover = <bool>[];
      await tester.pumpWidget(
        _wrap(
          _probe(enabled: false, onChanged: (_) {}, onHoverChange: hover.add),
        ),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(500, 500));
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(
        tester.getCenter(find.byType(LegendSelectionControl)),
      );
      await tester.pump();
      expect(hover, isEmpty);
    });

    testWidgets('disabling mid-press clears pressed', (tester) async {
      var enabled = true;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return _probe(enabled: enabled, onChanged: (_) {});
            },
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(LegendSelectionControl)),
      );
      await tester.pump();
      expect(_probeColor(tester), const Color(0xFFFF0000));

      rebuild(() => enabled = false);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      rebuild(() => enabled = true);
      await tester.pump();
      expect(
        _probeColor(tester),
        const Color(0xFF00FF00),
        reason: 're-enabled control must not resurrect stale pressed state',
      );
    });

    testWidgets('hover still reports on an enabled control', (tester) async {
      final hover = <bool>[];
      await tester.pumpWidget(
        _wrap(_probe(onChanged: (_) {}, onHoverChange: hover.add)),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(500, 500));
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(
        tester.getCenter(find.byType(LegendSelectionControl)),
      );
      await tester.pump();
      expect(hover, [true]);
      await gesture.moveTo(const Offset(500, 500));
      await tester.pump();
      expect(hover, [true, false]);
    });
  });

  group('LegendSelectionControl — semantics', () {
    SemanticsNode node(WidgetTester tester) =>
        tester.getSemantics(find.byType(LegendSelectionControl));

    testWidgets('checkbox role announces checked state, not a button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(_probe(selected: true, onChanged: (_) {})));
      final flags = node(tester).flagsCollection;
      expect(flags.isChecked, CheckedState.isTrue);
      expect(flags.isButton, isFalse);
      expect(flags.isInMutuallyExclusiveGroup, isFalse);

      await tester.pumpWidget(_wrap(_probe(onChanged: (_) {})));
      expect(node(tester).flagsCollection.isChecked, CheckedState.isFalse);
      handle.dispose();
    });

    testWidgets('tristate null announces the mixed checked state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(_probe(selected: null, tristate: true, onChanged: (_) {})),
      );
      expect(node(tester).flagsCollection.isChecked, CheckedState.mixed);
      handle.dispose();
    });

    testWidgets('radio role announces checked in a mutually exclusive group', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          _probe(
            selected: true,
            role: LegendSelectionRole.radio,
            onChanged: (_) {},
          ),
        ),
      );
      final flags = node(tester).flagsCollection;
      expect(flags.isChecked, CheckedState.isTrue);
      expect(flags.isInMutuallyExclusiveGroup, isTrue);
      handle.dispose();
    });

    testWidgets('toggle role announces toggled state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          _probe(
            selected: true,
            role: LegendSelectionRole.toggle,
            onChanged: (_) {},
          ),
        ),
      );
      final flags = node(tester).flagsCollection;
      expect(flags.isToggled, Tristate.isTrue);
      expect(flags.isChecked, CheckedState.none);
      handle.dispose();
    });

    testWidgets('selectable role announces selected state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          _probe(
            selected: true,
            role: LegendSelectionRole.selectable,
            onChanged: (_) {},
          ),
        ),
      );
      final flags = node(tester).flagsCollection;
      expect(flags.isSelected, Tristate.isTrue);
      expect(flags.isChecked, CheckedState.none);
      handle.dispose();
    });

    testWidgets('the labeled node carries the tap action and activates', (
      tester,
    ) async {
      bool? next;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(_probe(onChanged: (v) => next = v)));
      final n = node(tester);
      expect(n.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      n.owner!.performAction(n.id, SemanticsAction.tap);
      await tester.pump();
      expect(next, isTrue);
      handle.dispose();
    });

    testWidgets('disabled control drops the tap action and enabled flag', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(_probe(enabled: false, onChanged: (_) {})));
      final data = node(tester).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(node(tester).flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });
  });
}
