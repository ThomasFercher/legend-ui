import 'dart:ui' show SemanticsAction;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

/// The track is 220 wide with the default 20 thumb, so the thumb center
/// travels 200 logical pixels between x=10 and x=210.
const _width = 220.0;

Widget _wrap(
  Widget child, {
  Map<Type, Object> components = const {},
  TextDirection direction = TextDirection.ltr,
}) {
  return LegendTheme(
    data: LegendThemeData(tokens: LegendTokens.light, components: components),
    child: Directionality(
      textDirection: direction,
      child: Center(child: SizedBox(width: _width, child: child)),
    ),
  );
}

/// Global position of the point at [fraction] of the thumb's travel.
Offset _at(WidgetTester tester, double fraction) {
  final rect = tester.getRect(find.byType(LegendSlider));
  return Offset(rect.left + 10 + 200 * fraction, rect.center.dy);
}

Finder _paint() => find.descendant(
  of: find.byType(LegendSlider),
  matching: find.byType(CustomPaint),
);

/// A stateful harness owning the slider value, for drag sequences that
/// need the widget rebuilt with each change.
class _Host extends StatefulWidget {
  const _Host({
    required this.initial,
    this.divisions,
    this.onChangeStart,
    this.onChangeEnd,
    this.onChanged,
  });

  final double initial;
  final int? divisions;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final ValueChanged<double>? onChanged;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late double value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return LegendSlider(
      value: value,
      divisions: widget.divisions,
      onChangeStart: widget.onChangeStart,
      onChangeEnd: widget.onChangeEnd,
      onChanged: (next) {
        setState(() => value = next);
        widget.onChanged?.call(next);
      },
    );
  }
}

void main() {
  group('LegendSlider — pointer', () {
    testWidgets('tap positions the value, wrapped in change start/end', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        _wrap(
          LegendSlider(
            value: 0,
            onChanged: (v) => log.add('changed $v'),
            onChangeStart: (v) => log.add('start $v'),
            onChangeEnd: (v) => log.add('end $v'),
          ),
        ),
      );
      await tester.tapAt(_at(tester, 0.5));
      expect(log, ['start 0.0', 'changed 0.5', 'end 0.5']);
    });

    testWidgets('drag moves the value continuously and reports the final '
        'value once through onChangeEnd', (tester) async {
      final starts = <double>[];
      final ends = <double>[];
      final changes = <double>[];
      await tester.pumpWidget(
        _wrap(
          _Host(
            initial: 0.25,
            onChangeStart: starts.add,
            onChangeEnd: ends.add,
            onChanged: changes.add,
          ),
        ),
      );
      final gesture = await tester.startGesture(_at(tester, 0.5));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(starts, [0.25]);
      expect(changes, isNotEmpty);
      expect(changes.last, closeTo(1, 0.01));
      expect(ends.length, 1);
      expect(ends.single, closeTo(1, 0.01));
    });

    testWidgets('divisions snap every delivered value', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _wrap(_Host(initial: 0, divisions: 4, onChanged: changes.add)),
      );
      await tester.tapAt(_at(tester, 0.6));
      expect(changes, [0.5]);
    });

    testWidgets('a custom min/max range maps positions linearly', (
      tester,
    ) async {
      double? next;
      await tester.pumpWidget(
        _wrap(
          LegendSlider(
            value: 0,
            min: -50,
            max: 50,
            onChanged: (v) => next = v,
          ),
        ),
      );
      await tester.tapAt(_at(tester, 0.75));
      expect(next, closeTo(25, 0.5));
    });

    testWidgets('RTL mirrors the tap-to-position mapping', (tester) async {
      double? next;
      await tester.pumpWidget(
        _wrap(
          LegendSlider(value: 0, onChanged: (v) => next = v),
          direction: TextDirection.rtl,
        ),
      );
      await tester.tapAt(_at(tester, 0.25));
      expect(next, closeTo(0.75, 0.01));
    });

    testWidgets('disabled and null-onChanged sliders are inert', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(
          LegendSlider(
            value: 0,
            enabled: false,
            onChanged: (_) => called = true,
          ),
        ),
      );
      await tester.tapAt(_at(tester, 0.5));
      expect(called, isFalse);

      await tester.pumpWidget(
        _wrap(const LegendSlider(value: 0, onChanged: null)),
      );
      await tester.tapAt(_at(tester, 0.5));
      // No throw, no callback — nothing to assert beyond arriving here.
    });
  });

  group('LegendSlider — keyboard', () {
    testWidgets('arrows step 5% of the range; Home/End jump to the ends', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      double? next;
      Future<void> pump(double value) => tester.pumpWidget(
        _wrap(
          LegendSlider(
            value: value,
            focusNode: node,
            onChanged: (v) => next = v,
          ),
        ),
      );

      await pump(0.4);
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(next, closeTo(0.45, 0.0001));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(next, closeTo(0.45, 0.0001));

      await pump(0.4);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(next, closeTo(0.35, 0.0001));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(next, closeTo(0.35, 0.0001));

      await pump(0.4);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      expect(next, 0);
      await pump(0.4);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      expect(next, 1);
    });

    testWidgets('divisions make the arrow step one division', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      double? next;
      await tester.pumpWidget(
        _wrap(
          LegendSlider(
            value: 0.5,
            divisions: 4,
            focusNode: node,
            onChanged: (v) => next = v,
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(next, 0.75);
    });

    testWidgets('RTL flips the left/right arrows, not up/down', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      double? next;
      await tester.pumpWidget(
        _wrap(
          LegendSlider(
            value: 0.4,
            focusNode: node,
            onChanged: (v) => next = v,
          ),
          direction: TextDirection.rtl,
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(next, closeTo(0.45, 0.0001));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(next, closeTo(0.45, 0.0001));
    });
  });

  group('LegendSlider — semantics', () {
    testWidgets('announces a slider with a percent value and working '
        'increase/decrease actions', (tester) async {
      final handle = tester.ensureSemantics();
      double? next;
      await tester.pumpWidget(
        _wrap(
          LegendSlider(
            value: 0.4,
            semanticLabel: 'Volume',
            onChanged: (v) => next = v,
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(LegendSlider));
      expect(
        node,
        containsSemantics(
          isSlider: true,
          label: 'Volume',
          value: '40%',
          increasedValue: '45%',
          decreasedValue: '35%',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );

      node.owner!.performAction(node.id, SemanticsAction.increase);
      expect(next, closeTo(0.45, 0.0001));
      node.owner!.performAction(node.id, SemanticsAction.decrease);
      expect(next, closeTo(0.35, 0.0001));
      handle.dispose();
    });

    testWidgets('clamps an out-of-range value and honors a custom '
        'formatter', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(LegendSlider(value: 1.5, onChanged: (_) {})),
      );
      expect(
        tester.getSemantics(find.byType(LegendSlider)),
        containsSemantics(isSlider: true, value: '100%'),
      );

      await tester.pumpWidget(
        _wrap(
          LegendSlider(
            value: 30,
            max: 100,
            semanticFormatter: (v) => '${v.round()} px',
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(LegendSlider)),
        containsSemantics(isSlider: true, value: '30 px'),
      );
      handle.dispose();
    });

    testWidgets('a disabled slider exposes no increase/decrease actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const LegendSlider(value: 0.4, onChanged: null)),
      );
      expect(
        tester.getSemantics(find.byType(LegendSlider)),
        containsSemantics(
          isSlider: true,
          hasIncreaseAction: false,
          hasDecreaseAction: false,
        ),
      );
      handle.dispose();
    });
  });

  group('LegendSlider — theming', () {
    testWidgets('a level-3 registry entry resizes track and thumb', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LegendSlider(value: 0.5, onChanged: (_) {}),
          components: const {
            LegendSlider: LegendSliderThemeNullable(
              thumbSize: 30,
              trackHeight: 8,
            ),
          },
        ),
      );
      // Height is max(trackHeight, thumbSize * 2).
      expect(tester.getSize(_paint()), const Size(_width, 60));
    });

    testWidgets('a constructor param beats the theme and reaches the '
        'painter', (tester) async {
      await tester.pumpWidget(
        _wrap(LegendSlider(value: 0.5, onChanged: (_) {})),
      );
      final before = tester.widget<CustomPaint>(_paint()).painter;

      await tester.pumpWidget(
        _wrap(
          LegendSlider(
            value: 0.5,
            activeTrack: const Color(0xFF001F54),
            onChanged: (_) {},
          ),
        ),
      );
      final after = tester.widget<CustomPaint>(_paint()).painter;
      expect(after!.shouldRepaint(before!), isTrue);
    });
  });
}
