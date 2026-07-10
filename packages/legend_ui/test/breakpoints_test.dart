import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

/// Regression tests for the LegendBreakpoints aspect split (2026-07-10
/// rebuild audit): a same-tier width change must not rebuild tier
/// consumers, and height-only media changes must not rebuild the scope's
/// dependents at all.
void main() {
  Widget host({required Size size, required Widget child}) => MediaQuery(
    data: MediaQueryData(size: size),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: LegendBreakpointScope(child: child),
    ),
  );

  testWidgets('same-tier width change rebuilds width but not tier '
      'dependents', (tester) async {
    var tierBuilds = 0;
    var widthBuilds = 0;
    var pairBuilds = 0;
    LegendTier? tier;
    double? width;

    final probes = Column(
      children: [
        Builder(
          builder: (context) {
            tierBuilds++;
            tier = LegendBreakpoints.tierOf(context);
            return const SizedBox.shrink();
          },
        ),
        Builder(
          builder: (context) {
            widthBuilds++;
            width = LegendBreakpoints.widthOf(context);
            return const SizedBox.shrink();
          },
        ),
        Builder(
          builder: (context) {
            pairBuilds++;
            LegendBreakpoints.of(context);
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(host(size: const Size(800, 600), child: probes));
    expect(tier, LegendTier.medium);
    expect(width, 800);
    expect((tierBuilds, widthBuilds, pairBuilds), (1, 1, 1));

    // 800 → 900: still medium. Tier consumers must stay untouched.
    await tester.pumpWidget(host(size: const Size(900, 600), child: probes));
    expect(width, 900);
    expect(tierBuilds, 1, reason: 'same-tier resize must not rebuild tierOf');
    expect(widthBuilds, 2);
    expect(pairBuilds, 2, reason: 'of() depends on both aspects');

    // 900 → 500: tier flips to compact — now everyone rebuilds.
    await tester.pumpWidget(host(size: const Size(500, 600), child: probes));
    expect(tier, LegendTier.compact);
    expect((tierBuilds, widthBuilds, pairBuilds), (2, 3, 3));
  });

  testWidgets('height-only change rebuilds no breakpoint dependents', (
    tester,
  ) async {
    var tierBuilds = 0;
    var widthBuilds = 0;

    final probes = Column(
      children: [
        Builder(
          builder: (context) {
            tierBuilds++;
            LegendBreakpoints.tierOf(context);
            return const SizedBox.shrink();
          },
        ),
        Builder(
          builder: (context) {
            widthBuilds++;
            LegendBreakpoints.widthOf(context);
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(host(size: const Size(800, 600), child: probes));
    // Keyboard inset / height-only resize: the scope reads widthOf, so its
    // dependents must not even be notified.
    await tester.pumpWidget(host(size: const Size(800, 400), child: probes));
    expect((tierBuilds, widthBuilds), (1, 1));
  });
}
