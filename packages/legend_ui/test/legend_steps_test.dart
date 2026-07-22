import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child, {LegendThemeData? data}) {
  return LegendTheme(
    data: data ?? const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 600, child: child)),
    ),
  );
}

const _titles = ['Create', 'Verify', 'Fund', 'Done'];

LegendSteps _steps({
  int currentIndex = 1,
  Axis axis = Axis.horizontal,
  Color? completedColor,
}) {
  return LegendSteps(
    steps: [for (final title in _titles) LegendStep(title: title)],
    currentIndex: currentIndex,
    axis: axis,
    completedColor: completedColor,
  );
}

Finder _surfaceWith(Color color) => find.byWidgetPredicate(
  (widget) => widget is LegendSurface && widget.color == color,
);

void main() {
  const tokens = LegendTokens.light;

  group('LegendSteps content', () {
    testWidgets('renders every title and description', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LegendSteps(
            steps: const [
              LegendStep(title: 'Create', description: 'Pick a name'),
              LegendStep(title: 'Verify', description: 'Check your email'),
            ],
          ),
        ),
      );
      for (final text in [
        'Create',
        'Pick a name',
        'Verify',
        'Check your email',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
    });

    testWidgets('completed steps trade their number for the painted check', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_steps(currentIndex: 2)));
      // Steps 1 and 2 are completed — their numbers are gone.
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
      // Current and pending steps still show numbers.
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('currentIndex may equal steps.length — everything completed', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_steps(currentIndex: _titles.length)));
      for (var i = 1; i <= _titles.length; i++) {
        expect(find.text('$i'), findsNothing);
      }
    });

    testWidgets('a negative currentIndex clamps to the first step', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_steps(currentIndex: -3)));
      // Nothing is completed — all four numbers render.
      for (var i = 1; i <= _titles.length; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('is purely presentational — no interaction primitives', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_steps()));
      expect(find.byType(LegendInteractive), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });
  });

  group('LegendSteps status colors', () {
    testWidgets('completed/current fill primary, pending fills muted', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_steps()));
      // One completed + one current indicator on the primary fill.
      expect(_surfaceWith(tokens.colors.primary), findsNWidgets(2));
      // Two pending indicators on the muted fill.
      expect(_surfaceWith(tokens.colors.background2), findsNWidgets(2));
    });

    testWidgets('pending titles are muted, reached titles are not', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_steps()));
      TextStyle styleOf(String text) =>
          tester.widget<Text>(find.text(text)).style!;
      expect(styleOf('Create').color, tokens.colors.foreground1);
      expect(styleOf('Verify').color, tokens.colors.foreground1);
      expect(styleOf('Fund').color, tokens.colors.foreground3);
      expect(styleOf('Done').color, tokens.colors.foreground3);
    });
  });

  group('LegendSteps axes', () {
    testWidgets('horizontal divides the width equally between steps', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_steps()));
      final first = tester.getCenter(find.text('Create'));
      final second = tester.getCenter(find.text('Verify'));
      expect(second.dx - first.dx, moreOrLessEquals(150));
      expect(second.dy, first.dy);
    });

    testWidgets('vertical stacks steps below each other', (tester) async {
      await tester.pumpWidget(_wrap(_steps(axis: Axis.vertical)));
      final first = tester.getCenter(find.text('Create'));
      final second = tester.getCenter(find.text('Verify'));
      expect(second.dx, first.dx);
      expect(second.dy, greaterThan(first.dy));
    });
  });

  group('LegendSteps semantics', () {
    testWidgets('each step announces position, title and state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(_steps()));
      expect(
        find.bySemanticsLabel('Step 1 of 4: Create, completed'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Step 2 of 4: Verify, current'),
        findsOneWidget,
      );
      // Pending steps carry no state suffix.
      expect(find.bySemanticsLabel('Step 3 of 4: Fund'), findsOneWidget);
      expect(find.bySemanticsLabel('Step 4 of 4: Done'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the visual number does not announce separately', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(_steps(currentIndex: 0)));
      expect(find.bySemanticsLabel('1'), findsNothing);
      handle.dispose();
    });
  });

  group('LegendSteps theming', () {
    const navy = Color(0xFF001F54);

    testWidgets('level 3: a components-map entry restyles completed fills', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _steps(currentIndex: 2),
          data: const LegendThemeData(
            tokens: tokens,
            components: {
              LegendSteps: LegendStepsThemeNullable(completedColor: navy),
            },
          ),
        ),
      );
      expect(_surfaceWith(navy), findsNWidgets(2));
      // The current indicator keeps resolving to the token default.
      expect(_surfaceWith(tokens.colors.primary), findsOneWidget);
    });

    testWidgets('level 1: the constructor param wins over the registry', (
      tester,
    ) async {
      const crimson = Color(0xFF8B0000);
      await tester.pumpWidget(
        _wrap(
          _steps(completedColor: crimson),
          data: const LegendThemeData(
            tokens: tokens,
            components: {
              LegendSteps: LegendStepsThemeNullable(completedColor: navy),
            },
          ),
        ),
      );
      expect(_surfaceWith(crimson), findsOneWidget);
      expect(_surfaceWith(navy), findsNothing);
    });

    testWidgets('level 2: a subtree override beats the registry', (
      tester,
    ) async {
      const teal = Color(0xFF00695C);
      await tester.pumpWidget(
        _wrap(
          LegendStepsThemeOverride(
            data: const LegendStepsThemeNullable(completedColor: teal),
            child: _steps(),
          ),
          data: const LegendThemeData(
            tokens: tokens,
            components: {
              LegendSteps: LegendStepsThemeNullable(completedColor: navy),
            },
          ),
        ),
      );
      expect(_surfaceWith(teal), findsOneWidget);
      expect(_surfaceWith(navy), findsNothing);
    });
  });
}
