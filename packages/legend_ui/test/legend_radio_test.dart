import 'dart:ui' show CheckedState;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  Map<Type, Object> components = const {},
}) {
  return LegendTheme(
    data: LegendThemeData(tokens: LegendTokens.light, components: components),
    child: Directionality(
      textDirection: direction,
      child: Center(child: child),
    ),
  );
}

/// A three-radio group over the given [value] and [onChanged].
Widget _group(
  String? value,
  ValueChanged<String>? onChanged, {
  bool enabled = true,
  bool middleEnabled = true,
  TextDirection direction = TextDirection.ltr,
}) {
  return _wrap(
    LegendRadioGroup<String>(
      value: value,
      onChanged: onChanged,
      enabled: enabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LegendRadio(value: 'monthly', label: 'Monthly'),
          LegendRadio(value: 'yearly', label: 'Yearly', enabled: middleEnabled),
          const LegendRadio(value: 'lifetime', label: 'Lifetime'),
        ],
      ),
    ),
    direction: direction,
  );
}

/// The circle surface of the radio labeled [label].
LegendSurface _surface(WidgetTester tester, String label) =>
    tester.widget<LegendSurface>(
      find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(LegendSelectionControl),
        ),
        matching: find.byType(LegendSurface),
      ),
    );

double _dotOpacity(WidgetTester tester, String label) => tester
    .widget<AnimatedOpacity>(
      find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(LegendSelectionControl),
        ),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

List<FocusableActionDetector> _detectors(WidgetTester tester) => tester
    .widgetList<FocusableActionDetector>(find.byType(FocusableActionDetector))
    .toList();

void main() {
  group('LegendRadio — standalone behavior', () {
    testWidgets('tapping an unselected radio reports its value', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(
          LegendRadio<String>(
            value: 'monthly',
            groupValue: 'yearly',
            onChanged: (v) => selected = v,
          ),
        ),
      );
      await tester.tap(find.byType(LegendRadio<String>));
      expect(selected, 'monthly');
    });

    testWidgets('tapping the selected radio never deselects', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          LegendRadio<String>(
            value: 'monthly',
            groupValue: 'monthly',
            onChanged: (_) => calls++,
          ),
        ),
      );
      await tester.tap(find.byType(LegendRadio<String>));
      expect(calls, 0, reason: 'an exclusive control has no off gesture');
    });

    testWidgets('the inline label is part of the tap target', (tester) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(
          LegendRadio<String>(
            value: 'monthly',
            label: 'Monthly billing',
            onChanged: (v) => selected = v,
          ),
        ),
      );
      await tester.tap(find.text('Monthly billing'));
      expect(selected, 'monthly');
    });

    testWidgets('disabled and null-onChanged radios are inert', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(
          LegendRadio<String>(
            value: 'monthly',
            enabled: false,
            onChanged: (_) => called = true,
          ),
        ),
      );
      await tester.tap(find.byType(LegendRadio<String>));
      expect(called, isFalse);

      await tester.pumpWidget(
        _wrap(const LegendRadio<String>(value: 'monthly')),
      );
      await tester.tap(find.byType(LegendRadio<String>));
      // No throw, no callback — nothing to assert beyond arriving here.
    });
  });

  group('LegendRadioGroup — behavior', () {
    testWidgets('the group value selects the matching radio', (tester) async {
      await tester.pumpWidget(_group('yearly', (_) {}));
      expect(_dotOpacity(tester, 'Yearly'), 1);
      expect(_dotOpacity(tester, 'Monthly'), 0);
      expect(_dotOpacity(tester, 'Lifetime'), 0);
    });

    testWidgets('tapping a radio reports its value through the group', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(_group('monthly', (v) => selected = v));
      await tester.tap(find.text('Lifetime'));
      expect(selected, 'lifetime');
    });

    testWidgets('tapping the selected radio never deselects', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_group('monthly', (_) => calls++));
      await tester.tap(find.text('Monthly'));
      expect(calls, 0);
    });

    testWidgets('the group value and handler win over per-radio wiring', (
      tester,
    ) async {
      String? viaGroup;
      var viaRadio = false;
      await tester.pumpWidget(
        _wrap(
          LegendRadioGroup<String>(
            value: 'b',
            onChanged: (v) => viaGroup = v,
            child: LegendRadio<String>(
              value: 'a',
              label: 'A',
              // Ignored inside the group: 'a' would read selected here.
              groupValue: 'a',
              onChanged: (_) => viaRadio = true,
            ),
          ),
        ),
      );
      expect(_dotOpacity(tester, 'A'), 0);
      await tester.tap(find.text('A'));
      expect(viaGroup, 'a');
      expect(viaRadio, isFalse);
    });

    testWidgets('a disabled group makes every radio inert', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _group('monthly', (_) => called = true, enabled: false),
      );
      await tester.tap(find.text('Yearly'));
      expect(called, isFalse);
    });

    testWidgets('a null group handler makes every radio inert', (tester) async {
      await tester.pumpWidget(_group('monthly', null));
      await tester.tap(find.text('Yearly'));
      expect(
        _surface(tester, 'Monthly').color,
        LegendTokens.light.colors.disabled,
      );
    });
  });

  group('LegendRadioGroup — keyboard', () {
    testWidgets('arrows move focus and selection, wrapping at the ends', (
      tester,
    ) async {
      var value = 'monthly';
      await tester.pumpWidget(_group(value, (v) => value = v));
      _detectors(tester).first.focusNode!.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(value, 'yearly');
      expect(_detectors(tester)[1].focusNode!.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(value, 'monthly');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(
        value,
        'lifetime',
        reason: 'arrow-up from the first radio wraps to the last',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(
        value,
        'monthly',
        reason: 'arrow-down from the last radio wraps to the first',
      );
    });

    testWidgets('arrow movement skips disabled radios', (tester) async {
      var value = 'monthly';
      await tester.pumpWidget(
        _group(value, (v) => value = v, middleEnabled: false),
      );
      _detectors(tester).first.focusNode!.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(value, 'lifetime', reason: 'the disabled middle radio is skipped');
    });

    testWidgets('arrow keys are visual under RTL — right moves up the list', (
      tester,
    ) async {
      var value = 'yearly';
      await tester.pumpWidget(
        _group(value, (v) => value = v, direction: TextDirection.rtl),
      );
      _detectors(tester)[1].focusNode!.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, 'monthly');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(value, 'yearly');
    });

    testWidgets('Enter and Space select the focused radio', (tester) async {
      String? value;
      await tester.pumpWidget(_group(value, (v) => value = v));
      _detectors(tester)[1].focusNode!.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(value, 'yearly');

      await tester.pumpWidget(_group('yearly', (v) => value = v));
      _detectors(tester).first.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(value, 'monthly');
    });

    testWidgets('with a selection made, only the selected radio is a tab '
        'stop', (tester) async {
      await tester.pumpWidget(_group('yearly', (_) {}));
      final detectors = _detectors(tester);
      expect(detectors[0].focusNode!.skipTraversal, isTrue);
      expect(detectors[1].focusNode!.skipTraversal, isFalse);
      expect(detectors[2].focusNode!.skipTraversal, isTrue);

      // No selection yet — every radio stays reachable by Tab.
      await tester.pumpWidget(_group(null, (_) {}));
      for (final detector in _detectors(tester)) {
        expect(detector.focusNode!.skipTraversal, isFalse);
      }
    });
  });

  group('LegendRadio — visuals', () {
    testWidgets('the dot fades in when selected and out when unselected', (
      tester,
    ) async {
      await tester.pumpWidget(_group('monthly', (_) {}));
      expect(_dotOpacity(tester, 'Monthly'), 1);
      expect(_surface(tester, 'Monthly').border, isNull);
      expect(_dotOpacity(tester, 'Yearly'), 0);
      expect(_surface(tester, 'Yearly').color, isNull);
      expect(_surface(tester, 'Yearly').border, isNotNull);
    });

    testWidgets('the selected circle fills with the primary token by default', (
      tester,
    ) async {
      await tester.pumpWidget(_group('monthly', (_) {}));
      expect(
        _surface(tester, 'Monthly').color,
        LegendTokens.light.colors.primary,
      );
    });

    testWidgets('disabled swaps fill, border and dot to the disabled tokens', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LegendRadio<String>(
                value: 'a',
                groupValue: 'a',
                label: 'Selected',
              ),
              LegendRadio<String>(
                value: 'b',
                groupValue: 'a',
                label: 'Unselected',
              ),
            ],
          ),
        ),
      );
      expect(
        _surface(tester, 'Selected').color,
        LegendTokens.light.colors.disabled,
      );
      final border = _surface(tester, 'Unselected').border! as Border;
      expect(border.top.color, LegendTokens.light.colors.disabled);
    });

    testWidgets('themed size and border width apply', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LegendRadio<String>(
            value: 'a',
            groupValue: 'b',
            onChanged: (_) {},
            size: 32,
            borderWidth: 3,
          ),
        ),
      );
      final circleSize = tester.getSize(find.byType(CustomPaint).first);
      expect(circleSize, const Size(32, 32));
      final border =
          tester.widget<LegendSurface>(find.byType(LegendSurface)).border!
              as Border;
      expect(border.top.width, 3);
    });
  });

  group('LegendRadio — theming', () {
    testWidgets('constructor fill param wins over the default', (tester) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          LegendRadio<String>(
            value: 'a',
            groupValue: 'a',
            onChanged: (_) {},
            fill: const InteractiveColors(normal: navy),
          ),
        ),
      );
      expect(
        tester.widget<LegendSurface>(find.byType(LegendSurface)).color,
        navy,
      );
    });

    testWidgets('level-3 components-map override restyles the fill', (
      tester,
    ) async {
      const green = Color(0xFF059669);
      await tester.pumpWidget(
        _wrap(
          LegendRadio<String>(value: 'a', groupValue: 'a', onChanged: (_) {}),
          components: {
            LegendRadio: const LegendRadioThemeNullable(
              fill: InteractiveColors(normal: green),
            ),
          },
        ),
      );
      expect(
        tester.widget<LegendSurface>(find.byType(LegendSurface)).color,
        green,
      );
    });

    testWidgets('subtree override (level 2) restyles the dot color', (
      tester,
    ) async {
      const gold = Color(0xFFFFD700);
      await tester.pumpWidget(
        _wrap(
          LegendRadioThemeOverride(
            data: const LegendRadioThemeNullable(dotColor: gold),
            child: LegendRadio<String>(
              value: 'a',
              groupValue: 'a',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(
        tester.renderObject(
          find.descendant(
            of: find.byType(LegendRadio<String>),
            matching: find.byType(CustomPaint),
          ),
        ),
        paints..circle(color: gold),
      );
    });
  });

  group('LegendRadio — semantics', () {
    testWidgets('announces checked state in a mutually exclusive group, with '
        'the label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_group('yearly', (_) {}));
      final node = tester.getSemantics(
        find.ancestor(
          of: find.text('Yearly'),
          matching: find.byType(LegendSelectionControl),
        ),
      );
      expect(node.flagsCollection.isChecked, CheckedState.isTrue);
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(node.label, 'Yearly');
      // The visual label text is excluded — one announcement, not two.
      expect(find.bySemanticsLabel('Yearly'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an unselected radio announces unchecked', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_group('yearly', (_) {}));
      final node = tester.getSemantics(
        find.ancestor(
          of: find.text('Monthly'),
          matching: find.byType(LegendSelectionControl),
        ),
      );
      expect(node.flagsCollection.isChecked, CheckedState.isFalse);
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      handle.dispose();
    });
  });

  group('LegendRadio — form integration', () {
    testWidgets('works inside LegendFormField<String> with validation', (
      tester,
    ) async {
      final controller = LegendFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: LegendFormField<String>(
              name: 'plan',
              validator: (v) => v == null ? 'Pick a plan.' : null,
              builder: (context, field) => LegendRadioGroup<String>(
                value: field.value,
                onChanged: field.didChange,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LegendRadio(value: 'monthly', label: 'Monthly'),
                    LegendRadio(value: 'yearly', label: 'Yearly'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(controller.validate(), isFalse);

      await tester.tap(find.text('Yearly'));
      await tester.pump();
      expect(controller.values, {'plan': 'yearly'});
      expect(controller.validate(), isTrue);
    });
  });
}
