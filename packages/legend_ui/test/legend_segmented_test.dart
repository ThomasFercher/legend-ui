import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _timeframes = [
  LegendSegment(value: '1h', label: '1H'),
  LegendSegment(value: '1d', label: '1D'),
  LegendSegment(value: '1w', label: '1W'),
  LegendSegment(value: '1m', label: '1M'),
  LegendSegment(value: '1y', label: '1Y'),
];

Widget _wrap(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  LegendThemeData data = const LegendThemeData(tokens: LegendTokens.light),
}) {
  return LegendTheme(
    data: data,
    child: Directionality(
      textDirection: direction,
      child: Center(child: child),
    ),
  );
}

List<FocusableActionDetector> _detectors(WidgetTester tester) => tester
    .widgetList<FocusableActionDetector>(find.byType(FocusableActionDetector))
    .toList();

void main() {
  group('LegendSegmented — selection', () {
    testWidgets('renders every segment label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1d',
            onChanged: (_) {},
          ),
        ),
      );
      for (final segment in _timeframes) {
        expect(find.text(segment.label), findsOneWidget);
      }
    });

    testWidgets('tapping an unselected segment reports its value', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1d',
            onChanged: (v) => selected = v,
          ),
        ),
      );
      await tester.tap(find.text('1Y'));
      expect(selected, '1y');
    });

    testWidgets('tapping the selected segment never deselects (exclusive)', (
      tester,
    ) async {
      final values = <String>[];
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1d',
            onChanged: values.add,
          ),
        ),
      );
      await tester.tap(find.text('1D'));
      expect(values, isEmpty);
    });

    testWidgets('exactly the selected segment announces selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1w',
            onChanged: (_) {},
          ),
        ),
      );
      for (final segment in _timeframes) {
        // .first: the control's own Semantics node — the inner Text
        // contributes a second node with the same label.
        final node = tester.getSemantics(
          find.bySemanticsLabel(segment.label).first,
        );
        expect(
          node.flagsCollection.isSelected,
          segment.value == '1w' ? Tristate.isTrue : Tristate.isFalse,
          reason: '${segment.label} selected flag',
        );
      }
      handle.dispose();
    });

    testWidgets('the thumb slides to the selected segment', (tester) async {
      Widget build(String value) => _wrap(
        LegendSegmented<String>(
          segments: _timeframes,
          value: value,
          onChanged: (_) {},
        ),
      );
      await tester.pumpWidget(build('1h'));
      expect(
        tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment,
        const AlignmentDirectional(-1, 0),
      );

      await tester.pumpWidget(build('1y'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment,
        const AlignmentDirectional(1, 0),
      );
    });

    testWidgets('a value outside the segments renders without a thumb', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: 'nope',
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(AnimatedAlign), findsNothing);
    });

    testWidgets('empty segments assert', (tester) async {
      expect(
        () => LegendSegmented<String>(
          segments: const [],
          value: 'x',
          onChanged: (_) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('LegendSegmented — keyboard', () {
    testWidgets('arrows move focus between segments and wrap at the ends', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1d',
            onChanged: (_) {},
          ),
        ),
      );
      final detectors = _detectors(tester);
      detectors.first.focusNode!.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(detectors[1].focusNode!.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(detectors[0].focusNode!.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(
        detectors.last.focusNode!.hasFocus,
        isTrue,
        reason: 'arrow-left from the first segment wraps to the last',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        detectors.first.focusNode!.hasFocus,
        isTrue,
        reason: 'arrow-right from the last segment wraps to the first',
      );
    });

    testWidgets('Enter and Space select the focused segment', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1h',
            onChanged: values.add,
          ),
        ),
      );
      final detectors = _detectors(tester);
      detectors.first.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(values, ['1d']);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(values, ['1d', '1w']);
    });

    testWidgets('arrow keys are visual under RTL — right moves left in '
        'index space', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1d',
            onChanged: (_) {},
          ),
          direction: TextDirection.rtl,
        ),
      );
      final detectors = _detectors(tester);
      detectors[1].focusNode!.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(detectors[0].focusNode!.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(detectors[1].focusNode!.hasFocus, isTrue);
    });
  });

  group('LegendSegmented — disabled is fully inert', () {
    testWidgets('no tap, no focus, no keyboard while disabled', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1d',
            enabled: false,
            onChanged: values.add,
          ),
        ),
      );
      await tester.tap(find.text('1Y'));
      await tester.pump();
      expect(values, isEmpty);

      final detectors = _detectors(tester);
      detectors.first.focusNode!.requestFocus();
      await tester.pump();
      expect(detectors.first.focusNode!.hasFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(values, isEmpty);
    });

    testWidgets('null onChanged is disabled too', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1d',
            onChanged: null,
          ),
        ),
      );
      final track = tester.widget<LegendSurface>(
        find.byType(LegendSurface).first,
      );
      expect(track.color, LegendTokens.light.colors.disabled);
    });
  });

  group('LegendSegmented — theming', () {
    testWidgets('constructor thumb color lifts into the per-state field '
        '(level 1)', (tester) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1d',
            onChanged: (_) {},
            thumb: navy,
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is LegendSurface && widget.color == navy,
        ),
        findsOneWidget,
      );
    });

    testWidgets('registry override keyed by the widget type restyles the '
        'track (level 3)', (tester) async {
      const mint = Color(0xFF00C896);
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1d',
            onChanged: (_) {},
          ),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendSegmented: LegendSegmentedThemeNullable(background: mint),
            },
          ),
        ),
      );
      final track = tester.widget<LegendSurface>(
        find.byType(LegendSurface).first,
      );
      expect(track.color, mint);
    });

    testWidgets('hovering the selected segment tints the thumb through the '
        'state overlays', (tester) async {
      const tokens = LegendTokens.light;
      await tester.pumpWidget(
        _wrap(
          LegendSegmented<String>(
            segments: _timeframes,
            value: '1d',
            onChanged: (_) {},
          ),
        ),
      );
      final hovered = InteractiveColors(
        normal: tokens.colors.surface,
      ).resolve(const LegendStateHovered(), tokens.states);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('1D')));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) => widget is LegendSurface && widget.color == hovered,
        ),
        findsOneWidget,
      );
    });
  });
}
