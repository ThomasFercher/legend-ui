import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

/// The pane is 401 wide (or tall) with the default 1-thick divider, so the
/// panes share 400 logical pixels of available extent.
const _extent = 401.0;
const _cross = 200.0;

const _firstKey = Key('first');
const _secondKey = Key('second');

Widget _wrap(
  Widget child, {
  Map<Type, Object> components = const {},
  TextDirection direction = TextDirection.ltr,
  Size size = const Size(_extent, _cross),
}) {
  return LegendTheme(
    data: LegendThemeData(tokens: LegendTokens.light, components: components),
    child: Directionality(
      textDirection: direction,
      child: Center(
        child: SizedBox.fromSize(size: size, child: child),
      ),
    ),
  );
}

LegendSplitPane _pane({
  Axis axis = Axis.horizontal,
  double initialFraction = 0.5,
  double? fraction,
  ValueChanged<double>? onFractionChanged,
  double minFirst = 0,
  double minSecond = 0,
  bool? collapsed,
  double? collapseBreakpoint,
  String? semanticLabel,
  FocusNode? focusNode,
}) {
  return LegendSplitPane(
    axis: axis,
    initialFraction: initialFraction,
    fraction: fraction,
    onFractionChanged: onFractionChanged,
    minFirst: minFirst,
    minSecond: minSecond,
    collapsed: collapsed,
    collapseBreakpoint: collapseBreakpoint,
    semanticLabel: semanticLabel,
    focusNode: focusNode,
    first: const SizedBox(key: _firstKey),
    second: const SizedBox(key: _secondKey),
  );
}

double _firstWidth(WidgetTester tester) =>
    tester.getSize(find.byKey(_firstKey)).width;

/// Global position of the divider line's center.
Offset _divider(WidgetTester tester, {Axis axis = Axis.horizontal}) {
  final rect = tester.getRect(find.byType(LegendSplitPane));
  return axis == Axis.horizontal
      ? Offset(rect.left + _firstWidth(tester) + 0.5, rect.center.dy)
      : Offset(
          rect.center.dx,
          rect.top + tester.getSize(find.byKey(_firstKey)).height + 0.5,
        );
}

/// The divider line — the only [LegendSurface] inside the split pane.
Color? _lineColor(WidgetTester tester) => tester
    .widget<LegendSurface>(
      find.descendant(
        of: find.byType(LegendSplitPane),
        matching: find.byType(LegendSurface),
      ),
    )
    .color;

void main() {
  group('LegendSplitPane — layout', () {
    testWidgets('splits the available extent at initialFraction', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_pane(initialFraction: 0.25)));
      expect(_firstWidth(tester), 100);
      expect(tester.getSize(find.byKey(_secondKey)).width, 300);
      // Panes stretch the cross axis.
      expect(tester.getSize(find.byKey(_firstKey)).height, _cross);
    });

    testWidgets('a vertical axis stacks the panes', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _pane(axis: Axis.vertical, initialFraction: 0.25),
          size: const Size(_cross, _extent),
        ),
      );
      expect(tester.getSize(find.byKey(_firstKey)).height, 100);
      expect(tester.getSize(find.byKey(_secondKey)).height, 300);
      expect(tester.getSize(find.byKey(_firstKey)).width, _cross);
    });

    testWidgets('min extents clamp the initial fraction', (tester) async {
      await tester.pumpWidget(
        _wrap(_pane(initialFraction: 0.1, minFirst: 100)),
      );
      expect(_firstWidth(tester), 100);
    });

    testWidgets('unsatisfiable mins split proportionally to them', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_pane(minFirst: 300, minSecond: 900)));
      // 400 available cannot give 300+900 — first gets 300/1200 of it.
      expect(_firstWidth(tester), 100);
    });
  });

  group('LegendSplitPane — drag', () {
    testWidgets('dragging the divider moves the split and reports the '
        'clamped fraction', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(_wrap(_pane(onFractionChanged: changes.add)));
      expect(_firstWidth(tester), 200);

      final gesture = await tester.startGesture(_divider(tester));
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      expect(_firstWidth(tester), 300);
      expect(changes.last, closeTo(0.75, 0.001));

      await gesture.up();
      await tester.pump();
      // The adjustment persists after the drag (uncontrolled mode).
      expect(_firstWidth(tester), 300);
    });

    testWidgets('a drag never crosses the min bounds, and overshoot must '
        'be dragged back', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _wrap(
          _pane(minFirst: 100, minSecond: 100, onFractionChanged: changes.add),
        ),
      );
      final gesture = await tester.startGesture(_divider(tester));
      await gesture.moveBy(const Offset(-500, 0));
      await tester.pump();
      expect(_firstWidth(tester), 100);
      expect(changes.last, 0.25);

      // The pointer is 400 past the bound — a small return drag must not
      // move the divider yet.
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      expect(_firstWidth(tester), 100);
      await gesture.up();
    });

    testWidgets('RTL mirrors the drag direction', (tester) async {
      await tester.pumpWidget(_wrap(_pane(), direction: TextDirection.rtl));
      // In RTL the first pane sits at the end (right); its divider is at
      // 200 from the right edge — drag left to grow it.
      final rect = tester.getRect(find.byType(LegendSplitPane));
      final gesture = await tester.startGesture(
        Offset(rect.right - 200.5, rect.center.dy),
      );
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(_firstWidth(tester), 300);
      await gesture.up();
    });

    testWidgets('a vertical axis drags along the vertical', (tester) async {
      await tester.pumpWidget(
        _wrap(_pane(axis: Axis.vertical), size: const Size(_cross, _extent)),
      );
      final gesture = await tester.startGesture(
        _divider(tester, axis: Axis.vertical),
      );
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      expect(tester.getSize(find.byKey(_firstKey)).height, 100);
      await gesture.up();
    });

    testWidgets('controlled mode pins the split to fraction and only '
        'reports the drags', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _wrap(_pane(fraction: 0.25, onFractionChanged: changes.add)),
      );
      expect(_firstWidth(tester), 100);

      final gesture = await tester.startGesture(_divider(tester));
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      // The divider did not move — the parent owns the fraction.
      expect(_firstWidth(tester), 100);
      expect(changes.last, closeTo(0.5, 0.001));
      await gesture.up();

      // The parent rebuilding with the reported value moves the split.
      await tester.pumpWidget(
        _wrap(_pane(fraction: 0.5, onFractionChanged: changes.add)),
      );
      expect(_firstWidth(tester), 200);
    });
  });

  group('LegendSplitPane — keyboard', () {
    testWidgets('arrows nudge 5%; Home/End collapse to the min bounds', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final changes = <double>[];
      await tester.pumpWidget(
        _wrap(
          _pane(
            minFirst: 40,
            minSecond: 40,
            focusNode: node,
            onFractionChanged: changes.add,
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();

      // The widget owns the fraction, so each press builds on the last —
      // pump between events to let the rebuilt handle land.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(changes.last, closeTo(0.55, 0.0001));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(changes.last, closeTo(0.5, 0.0001));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(changes.last, closeTo(0.55, 0.0001));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(changes.last, closeTo(0.5, 0.0001));

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(changes.last, 0.1); // minFirst 40 of 400 available
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(changes.last, 0.9);
    });

    testWidgets('RTL flips the main-axis arrows only', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final changes = <double>[];
      await tester.pumpWidget(
        _wrap(
          _pane(focusNode: node, onFractionChanged: changes.add),
          direction: TextDirection.rtl,
        ),
      );
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(changes.last, closeTo(0.55, 0.0001));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(changes.last, closeTo(0.6, 0.0001));
    });

    testWidgets('a vertical axis maps up/down to the divider direction', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final changes = <double>[];
      await tester.pumpWidget(
        _wrap(
          _pane(
            axis: Axis.vertical,
            focusNode: node,
            onFractionChanged: changes.add,
          ),
          size: const Size(_cross, _extent),
        ),
      );
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(changes.last, closeTo(0.55, 0.0001));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(changes.last, closeTo(0.5, 0.0001));
    });
  });

  group('LegendSplitPane — collapse', () {
    testWidgets('collapsed: true shows only the first pane, full size', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_pane(collapsed: true)));
      expect(find.byKey(_secondKey), findsNothing);
      expect(
        tester.getSize(find.byKey(_firstKey)),
        const Size(_extent, _cross),
      );
    });

    testWidgets('a collapseBreakpoint above the available width '
        'auto-collapses; collapsed: false vetoes it', (tester) async {
      await tester.pumpWidget(_wrap(_pane(collapseBreakpoint: 500)));
      expect(find.byKey(_secondKey), findsNothing);

      await tester.pumpWidget(
        _wrap(_pane(collapseBreakpoint: 500, collapsed: false)),
      );
      expect(find.byKey(_secondKey), findsOneWidget);
    });

    testWidgets('auto-collapse is off by default', (tester) async {
      await tester.pumpWidget(_wrap(_pane(), size: const Size(240, _cross)));
      expect(find.byKey(_secondKey), findsOneWidget);
    });
  });

  group('LegendSplitPane — semantics', () {
    testWidgets('announces an adjustable slider node valued at the '
        'fraction, with working increase/decrease', (tester) async {
      final handle = tester.ensureSemantics();
      final changes = <double>[];
      await tester.pumpWidget(
        _wrap(
          _pane(semanticLabel: 'Sources panel', onFractionChanged: changes.add),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Sources panel'));
      expect(
        node,
        containsSemantics(
          isSlider: true,
          label: 'Sources panel',
          value: '50%',
          increasedValue: '55%',
          decreasedValue: '45%',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );

      // The widget owns the fraction — pump between actions so the second
      // one adjusts from the updated value.
      node.owner!.performAction(node.id, SemanticsAction.increase);
      await tester.pump();
      expect(changes.last, closeTo(0.55, 0.0001));
      node.owner!.performAction(node.id, SemanticsAction.decrease);
      await tester.pump();
      expect(changes.last, closeTo(0.5, 0.0001));
      handle.dispose();
    });
  });

  group('LegendSplitPane — theming', () {
    testWidgets('a level-3 registry entry restyles thickness and line '
        'color', (tester) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          _pane(),
          components: const {
            LegendSplitPane: LegendSplitPaneThemeNullable(
              divider: navy,
              dividerThickness: 9,
            ),
          },
        ),
      );
      // (401 - 9) * 0.5 per pane, 9 for the divider gap.
      expect(_firstWidth(tester), 196);
      expect(_lineColor(tester), navy);
    });

    testWidgets('hovering paints the handle color over the divider line '
        'and shows a resize cursor', (tester) async {
      // Hover highlights are gated on the focus highlight mode, which the
      // test platform defaults to `touch` — force the desktop behavior so
      // FocusableActionDetector reports hover.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          _pane(),
          components: const {
            LegendSplitPane: LegendSplitPaneThemeNullable(
              handle: InteractiveColors(hovered: navy),
            ),
          },
        ),
      );
      final rest = _lineColor(tester);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(_divider(tester));
      await tester.pump();

      expect(_lineColor(tester), navy);
      expect(_lineColor(tester), isNot(rest));
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.resizeColumn,
      );
    });

    testWidgets('a constructor param beats the theme', (tester) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          const LegendSplitPane(
            divider: navy,
            first: SizedBox(key: _firstKey),
            second: SizedBox(key: _secondKey),
          ),
          components: const {
            LegendSplitPane: LegendSplitPaneThemeNullable(
              divider: Color(0xFFDC2626),
            ),
          },
        ),
      );
      expect(_lineColor(tester), navy);
    });
  });
}
