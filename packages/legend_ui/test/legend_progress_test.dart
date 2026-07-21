import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child, {LegendThemeData? theme}) {
  return LegendTheme(
    data: theme ?? const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 200, child: child)),
    ),
  );
}

Finder _paint() => find.descendant(
  of: find.byType(LegendProgress),
  matching: find.byType(CustomPaint),
);

void main() {
  group('LegendProgress.bar determinate', () {
    testWidgets('paints a static full-width bar at the themed thickness', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendProgress.bar(value: 0.5)));
      expect(tester.getSize(_paint()), const Size(200, 6));

      // Determinate paint is static: no ticker runs, the painter is the
      // exact same instance a frame later.
      expect(tester.hasRunningAnimations, isFalse);
      final before = tester.widget<CustomPaint>(_paint()).painter;
      await tester.pump(const Duration(milliseconds: 300));
      final after = tester.widget<CustomPaint>(_paint()).painter;
      expect(identical(after, before), isTrue);
    });

    testWidgets('a value change repaints', (tester) async {
      await tester.pumpWidget(_wrap(const LegendProgress.bar(value: 0.2)));
      final before = tester.widget<CustomPaint>(_paint()).painter;
      await tester.pumpWidget(_wrap(const LegendProgress.bar(value: 0.8)));
      final after = tester.widget<CustomPaint>(_paint()).painter;
      expect(after!.shouldRepaint(before!), isTrue);
    });

    testWidgets('announces the percentage through semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const LegendProgress.bar(value: 0.5, semanticLabel: 'Download')),
      );
      expect(
        tester.getSemantics(find.byType(LegendProgress)),
        matchesSemantics(label: 'Download', value: '50%'),
      );
      handle.dispose();
    });

    testWidgets('clamps out-of-range values', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const LegendProgress.bar(value: 1.5)));
      expect(
        tester.getSemantics(find.byType(LegendProgress)),
        matchesSemantics(value: '100%'),
      );
      handle.dispose();
    });
  });

  group('LegendProgress indeterminate', () {
    testWidgets('animates while value is null and disposes its ticker', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendProgress.bar()));
      expect(tester.hasRunningAnimations, isTrue);

      final before = tester.widget<CustomPaint>(_paint()).painter;
      await tester.pump(const Duration(milliseconds: 300));
      final after = tester.widget<CustomPaint>(_paint()).painter;
      expect(identical(after, before), isFalse);
      expect(after!.shouldRepaint(before!), isTrue);

      // The controller repeats forever: unmounting must dispose its
      // ticker (this test fails on leaked tickers otherwise).
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('stops when a value arrives and resumes when it leaves', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendProgress.circle()));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(_wrap(const LegendProgress.circle(value: 0.7)));
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(_wrap(const LegendProgress.circle()));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('has no percentage semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const LegendProgress.bar(semanticLabel: 'Working')),
      );
      expect(
        tester.getSemantics(find.byType(LegendProgress)),
        matchesSemantics(label: 'Working'),
      );
      handle.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('LegendProgress.circle', () {
    testWidgets('renders at the themed diameter', (tester) async {
      await tester.pumpWidget(
        _wrap(const Center(child: LegendProgress.circle(value: 0.3))),
      );
      expect(tester.getSize(_paint()), const Size(40, 40));
    });

    testWidgets('constructor size wins over the themed default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const Center(child: LegendProgress.circle(value: 0.3, size: 64))),
      );
      expect(tester.getSize(_paint()), const Size(64, 64));
    });
  });

  group('LegendProgress theming', () {
    testWidgets('a level-3 registry entry restyles the bar thickness', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendProgress.bar(value: 0.5),
          theme: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendProgress: LegendProgressThemeNullable(thickness: 12),
            },
          ),
        ),
      );
      expect(tester.getSize(_paint()), const Size(200, 12));
    });
  });
}
