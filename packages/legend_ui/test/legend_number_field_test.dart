import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child, {Map<Type, Object> components = const {}}) {
  return LegendTheme(
    data: LegendThemeData(tokens: LegendTokens.light, components: components),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Center(child: SizedBox(width: 280, child: child)),
      ),
    ),
  );
}

Finder _editable() => find.byType(EditableText);

String _text(WidgetTester tester) =>
    tester.widget<EditableText>(_editable()).controller.text;

void main() {
  group('LegendNumberField — decimal typing', () {
    testWidgets('accepts digits and one separator; rejects everything else', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendNumberField()));
      await tester.enterText(_editable(), '12.34');
      expect(_text(tester), '12.34');

      // A second separator, letters, or embedded signs keep the old text.
      await tester.enterText(_editable(), '12.34.5');
      expect(_text(tester), '12.34');
      await tester.enterText(_editable(), '12a');
      expect(_text(tester), '12.34');
      await tester.enterText(_editable(), '1-2');
      expect(_text(tester), '12.34');
    });

    testWidgets("normalizes a typed ',' separator to '.'", (tester) async {
      await tester.pumpWidget(_wrap(const LegendNumberField()));
      await tester.enterText(_editable(), '3,5');
      expect(_text(tester), '3.5');
    });

    testWidgets('leading minus is only typable when min allows negatives', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendNumberField(min: 0)));
      await tester.enterText(_editable(), '-5');
      expect(_text(tester), '');

      await tester.pumpWidget(_wrap(const LegendNumberField(min: -10)));
      await tester.enterText(_editable(), '-5');
      expect(_text(tester), '-5');
    });

    testWidgets('decimals caps fraction digits; decimals 0 forbids the '
        'separator', (tester) async {
      await tester.pumpWidget(_wrap(const LegendNumberField(decimals: 2)));
      await tester.enterText(_editable(), '1.234');
      expect(_text(tester), '');
      await tester.enterText(_editable(), '1.23');
      expect(_text(tester), '1.23');

      await tester.pumpWidget(_wrap(const LegendNumberField(decimals: 0)));
      await tester.enterText(_editable(), '7.5');
      expect(_text(tester), '1.23');
      await tester.enterText(_editable(), '75');
      expect(_text(tester), '75');
    });

    testWidgets('typing reports the clamped value live; emptying reports '
        'null', (tester) async {
      final reported = <double?>[];
      await tester.pumpWidget(
        _wrap(LegendNumberField(max: 100, onChanged: reported.add)),
      );
      await tester.enterText(_editable(), '250');
      // Clamped in the report, but the text is not rewritten mid-typing.
      expect(reported, [100]);
      expect(_text(tester), '250');

      await tester.enterText(_editable(), '');
      expect(reported, [100, null]);
    });
  });

  group('LegendNumberField — commit (blur/Enter)', () {
    testWidgets('blur clamps to the bounds and reformats the text', (
      tester,
    ) async {
      double? committed;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _wrap(
          LegendNumberField(
            max: 100,
            focusNode: focusNode,
            onChanged: (v) => committed = v,
          ),
        ),
      );
      await tester.enterText(_editable(), '250');
      focusNode.unfocus();
      await tester.pump();
      expect(_text(tester), '100');
      expect(committed, 100);
    });

    testWidgets('Enter commits: dangling separator reformats away', (
      tester,
    ) async {
      double? committed;
      await tester.pumpWidget(
        _wrap(LegendNumberField(onChanged: (v) => committed = v)),
      );
      await tester.enterText(_editable(), '5.');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(_text(tester), '5');
      expect(committed, 5);
    });

    testWidgets('commit formats to the decimals precision', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _wrap(LegendNumberField(decimals: 2, focusNode: focusNode)),
      );
      await tester.enterText(_editable(), '3.1');
      focusNode.unfocus();
      await tester.pump();
      expect(_text(tester), '3.10');
    });

    testWidgets('unparseable leftovers revert to the last value', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _wrap(LegendNumberField(value: 4, min: -10, focusNode: focusNode)),
      );
      await tester.enterText(_editable(), '-');
      focusNode.unfocus();
      await tester.pump();
      expect(_text(tester), '4');
    });
  });

  group('LegendNumberField — steppers', () {
    testWidgets('tap on Increase/Decrease steps by step', (tester) async {
      double? next;
      await tester.pumpWidget(
        _wrap(
          LegendNumberField(value: 5, step: 2.5, onChanged: (v) => next = v),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Increase'));
      expect(next, 7.5);
      expect(_text(tester), '7.5');

      await tester.tap(find.bySemanticsLabel('Decrease'));
      // The text (7.5) is the stepping base, not the stale widget value.
      expect(next, 5);
      expect(_text(tester), '5');
    });

    testWidgets('stepping an empty field starts from 0 clamped into range', (
      tester,
    ) async {
      double? next;
      await tester.pumpWidget(
        _wrap(LegendNumberField(min: 5, max: 10, onChanged: (v) => next = v)),
      );
      await tester.tap(find.bySemanticsLabel('Increase'));
      expect(next, 5);
      expect(_text(tester), '5');
    });

    testWidgets('steppers disable at the bounds (and stay announced)', (
      tester,
    ) async {
      double? next;
      await tester.pumpWidget(
        _wrap(
          LegendNumberField(
            value: 10,
            min: 0,
            max: 10,
            onChanged: (v) => next = v,
          ),
        ),
      );
      // At max: Increase is inert, Decrease still works.
      await tester.tap(find.bySemanticsLabel('Increase'));
      expect(next, isNull);
      await tester.tap(find.bySemanticsLabel('Decrease'));
      expect(next, 9);

      await tester.pumpWidget(
        _wrap(
          LegendNumberField(
            value: 0,
            min: 0,
            max: 10,
            onChanged: (v) => next = v,
          ),
        ),
      );
      next = null;
      await tester.tap(find.bySemanticsLabel('Decrease'));
      expect(next, isNull);
    });

    testWidgets('press-and-hold repeats after the delay and a completed hold '
        'does not double-step on release', (tester) async {
      final reported = <double?>[];
      await tester.pumpWidget(
        _wrap(LegendNumberField(value: 0, onChanged: reported.add)),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('Increase')),
      );
      // Before the hold delay: no steps yet.
      await tester.pump(const Duration(milliseconds: 400));
      expect(reported, isEmpty);
      // Past the delay the first step fires, then repeats every interval.
      await tester.pump(const Duration(milliseconds: 150));
      expect(reported, [1]);
      await tester.pump(const Duration(milliseconds: 160));
      expect(reported, [1, 2, 3]);
      await gesture.up();
      await tester.pump();
      // The release tap is consumed — no extra step.
      expect(reported, [1, 2, 3]);
    });

    testWidgets('hold-repeat stops at the bound', (tester) async {
      final reported = <double?>[];
      await tester.pumpWidget(
        _wrap(LegendNumberField(value: 0, max: 2, onChanged: reported.add)),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('Increase')),
      );
      await tester.pump(const Duration(seconds: 2));
      await gesture.up();
      await tester.pump();
      expect(reported, [1, 2]);
      expect(_text(tester), '2');
    });

    testWidgets('a quick tap-and-release steps exactly once', (tester) async {
      final reported = <double?>[];
      await tester.pumpWidget(
        _wrap(LegendNumberField(value: 0, onChanged: reported.add)),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('Increase')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();
      expect(reported, [1]);
    });
  });

  group('LegendNumberField — keyboard', () {
    testWidgets('up/down arrows step the focused field', (tester) async {
      double? next;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _wrap(
          LegendNumberField(
            value: 5,
            min: 0,
            max: 6,
            focusNode: focusNode,
            onChanged: (v) => next = v,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(next, 6);
      // At max the up arrow is inert.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(next, 6);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(next, 5);
    });
  });

  group('LegendNumberField — disabled and external value', () {
    testWidgets('disabled: field is read-only, steppers are inert', (
      tester,
    ) async {
      double? next;
      await tester.pumpWidget(
        _wrap(
          LegendNumberField(
            value: 5,
            enabled: false,
            onChanged: (v) => next = v,
          ),
        ),
      );
      expect(tester.widget<EditableText>(_editable()).readOnly, isTrue);
      await tester.tap(find.bySemanticsLabel('Increase'));
      await tester.tap(find.bySemanticsLabel('Decrease'));
      expect(next, isNull);
    });

    testWidgets('an external value change rewrites the text', (tester) async {
      await tester.pumpWidget(_wrap(const LegendNumberField(value: 1)));
      expect(_text(tester), '1');
      await tester.pumpWidget(_wrap(const LegendNumberField(value: 2.5)));
      expect(_text(tester), '2.5');
    });

    testWidgets('placeholder shows only while empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendNumberField(placeholder: 'Amount')),
      );
      expect(find.text('Amount'), findsOneWidget);
      await tester.enterText(_editable(), '3');
      await tester.pump();
      expect(find.text('Amount'), findsNothing);
    });
  });

  group('LegendNumberField — theming', () {
    testWidgets('registry override recolors the stepper arrows; a '
        'constructor param wins', (tester) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          const LegendNumberField(),
          components: {
            LegendNumberField: const LegendNumberFieldThemeNullable(
              stepperForeground: navy,
            ),
          },
        ),
      );
      final carets = tester
          .widgetList<LegendCaret>(find.byType(LegendCaret))
          .toList();
      expect(carets, hasLength(2));
      expect(carets.every((c) => c.color == navy), isTrue);

      const crimson = Color(0xFFDC143C);
      await tester.pumpWidget(
        _wrap(
          const LegendNumberField(stepperForeground: crimson),
          components: {
            LegendNumberField: const LegendNumberFieldThemeNullable(
              stepperForeground: navy,
            ),
          },
        ),
      );
      final overridden = tester
          .widgetList<LegendCaret>(find.byType(LegendCaret))
          .toList();
      expect(overridden.every((c) => c.color == crimson), isTrue);
    });
  });
}
