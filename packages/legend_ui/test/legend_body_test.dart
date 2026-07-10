import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child, {EdgeInsets viewInsets = EdgeInsets.zero}) {
  return LegendTheme(
    data: const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(viewInsets: viewInsets),
        child: child,
      ),
    ),
  );
}

void main() {
  group('LegendBody — controller ownership (legacy leak closed)', () {
    testWidgets('owns one controller across rebuilds and publishes it via '
        'PrimaryScrollController', (tester) async {
      ScrollController? seen;
      final probe = Builder(
        builder: (context) {
          seen = PrimaryScrollController.of(context);
          return const SizedBox(height: 10);
        },
      );

      await tester.pumpWidget(_wrap(LegendBody(children: [probe])));
      final first = seen;
      expect(first, isNotNull);
      expect(first!.hasClients, isTrue);

      // Regression (legacy: `scrollController ?? ScrollController()` per
      // build): a rebuild must reuse the same state-owned controller.
      await tester.pumpWidget(_wrap(LegendBody(children: [probe])));
      expect(identical(seen, first), isTrue);

      // Disposal happens with the state — pumping the body away must not
      // leak or throw (a leaked controller with clients would assert on
      // position detach in a later frame).
      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an external controller is used, not wrapped or replaced', (
      tester,
    ) async {
      final external = ScrollController();
      addTearDown(external.dispose);
      await tester.pumpWidget(
        _wrap(
          LegendBody(
            controller: external,
            children: const [SizedBox(height: 10)],
          ),
        ),
      );
      expect(external.hasClients, isTrue);
      final context = tester.element(find.byType(SizedBox));
      expect(identical(PrimaryScrollController.of(context), external), isTrue);
    });
  });

  group('LegendBody — single padding source', () {
    testWidgets('theme default padding (t.sizes.lg) is applied once around '
        'the content', (tester) async {
      const probe = SizedBox(key: Key('probe'), height: 10);
      await tester.pumpWidget(
        _wrap(const LegendBody(safeArea: false, children: [probe])),
      );

      final lg = LegendTokens.light.sizes.lg;
      expect(tester.getTopLeft(find.byKey(const Key('probe'))), Offset(lg, lg));
      // Exactly one SliverPadding carries the content padding — the legacy
      // half-half split across padding + spacer slivers is gone.
      final paddings = tester
          .widgetList<SliverPadding>(find.byType(SliverPadding))
          .where((p) => p.padding == EdgeInsets.all(lg));
      expect(paddings.length, 1);
    });

    testWidgets('constructor padding wins over the theme default', (
      tester,
    ) async {
      const probe = SizedBox(key: Key('probe'), height: 10);
      await tester.pumpWidget(
        _wrap(
          const LegendBody(
            safeArea: false,
            padding: EdgeInsets.all(4),
            children: [probe],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('probe'))),
        const Offset(4, 4),
      );
    });
  });

  group('LegendBody — maxContentWidth', () {
    testWidgets('content is constrained and centered', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const probe = SizedBox(key: Key('probe'), height: 10);
      await tester.pumpWidget(
        _wrap(
          const LegendBody(
            safeArea: false,
            padding: EdgeInsets.zero,
            maxContentWidth: 400,
            children: [probe],
          ),
        ),
      );
      final rect = tester.getRect(find.byKey(const Key('probe')));
      expect(rect.width, 400);
      expect(rect.left, 200); // (800 - 400) / 2 — centered.
    });

    testWidgets('null (the default) leaves the content unconstrained', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const probe = SizedBox(key: Key('probe'), height: 10);
      await tester.pumpWidget(
        _wrap(
          const LegendBody(
            safeArea: false,
            padding: EdgeInsets.zero,
            children: [probe],
          ),
        ),
      );
      expect(tester.getRect(find.byKey(const Key('probe'))).width, 800);
    });

    testWidgets('resolves through the components registry (level 3)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const probe = SizedBox(key: Key('probe'), height: 10);
      await tester.pumpWidget(
        const LegendTheme(
          data: LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendBody: LegendBodyThemeNullable(maxContentWidth: 300),
            },
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData(),
              child: LegendBody(
                safeArea: false,
                padding: EdgeInsets.zero,
                children: [probe],
              ),
            ),
          ),
        ),
      );
      expect(tester.getRect(find.byKey(const Key('probe'))).width, 300);
    });
  });

  group('LegendBody.pinnedFooter — the form archetype', () {
    testWidgets('footer pins to the viewport bottom while content is short', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          const LegendBody.pinnedFooter(
            safeArea: false,
            padding: EdgeInsets.all(16),
            footer: SizedBox(key: Key('footer'), height: 40),
            children: [SizedBox(height: 100)],
          ),
        ),
      );
      // Bottom-pinned: footer bottom sits at viewport bottom minus the
      // padding's bottom (which lives inside the fill-remaining child).
      expect(
        tester.getBottomLeft(find.byKey(const Key('footer'))).dy,
        600 - 16,
      );
    });

    testWidgets('footer flows after the content once it scrolls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          LegendBody.pinnedFooter(
            safeArea: false,
            padding: const EdgeInsets.all(16),
            controller: controller,
            footer: const SizedBox(key: Key('footer'), height: 40),
            children: const [SizedBox(height: 2000)],
          ),
        ),
      );
      // Content overflows: the footer is beyond the viewport, not pinned.
      expect(find.byKey(const Key('footer')), findsNothing);

      // At the end of the scroll it sits after the content.
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      expect(
        tester.getBottomLeft(find.byKey(const Key('footer'))).dy,
        600 - 16,
      );
      // Total extent = content + its padding + footer + footer padding.
      expect(controller.position.maxScrollExtent, 2000 + 32 + 40 + 16 - 600);
    });
  });

  group('LegendBody — keyboard inset consumed', () {
    testWidgets('scrolling mode gains trailing scroll extent', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = ScrollController();
      addTearDown(controller.dispose);

      Widget build(EdgeInsets viewInsets) => _wrap(
        viewInsets: viewInsets,
        LegendBody(
          safeArea: false,
          padding: EdgeInsets.zero,
          controller: controller,
          children: const [SizedBox(height: 1000)],
        ),
      );

      await tester.pumpWidget(build(EdgeInsets.zero));
      final without = controller.position.maxScrollExtent;
      await tester.pumpWidget(build(const EdgeInsets.only(bottom: 250)));
      expect(controller.position.maxScrollExtent, without + 250);
    });

    testWidgets('.fixed shrinks the fill extent instead of scrolling', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const probe = SizedBox.expand(key: Key('probe'));
      await tester.pumpWidget(
        _wrap(
          viewInsets: const EdgeInsets.only(bottom: 200),
          const LegendBody.fixed(
            safeArea: false,
            padding: EdgeInsets.zero,
            child: probe,
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('probe'))).height, 400);
    });
  });

  group('LegendBody.fixed', () {
    testWidgets('expands the child to the viewport and never scrolls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          const LegendBody.fixed(
            safeArea: false,
            padding: EdgeInsets.zero,
            child: SizedBox.expand(key: Key('probe')),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('probe'))),
        const Size(800, 600),
      );

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      expect(position.physics, isA<NeverScrollableScrollPhysics>());
    });
  });

  group('LegendBody.slivers + LegendSliver* helpers', () {
    testWidgets('renders raw slivers; asSliver adapts box widgets', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LegendBody.slivers(
            safeArea: false,
            slivers: [
              const Text('boxed').asSliver,
              SliverList.list(children: const [Text('listed')]),
            ],
          ),
        ),
      );
      expect(find.text('boxed'), findsOneWidget);
      expect(find.text('listed'), findsOneWidget);
    });

    testWidgets('LegendSliverPinnedHeader pins while content scrolls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          LegendBody.slivers(
            safeArea: false,
            padding: EdgeInsets.zero,
            controller: controller,
            slivers: [
              const LegendSliverPinnedHeader(
                child: SizedBox(key: Key('header'), height: 50),
              ),
              SliverList.list(children: const [SizedBox(height: 3000)]),
            ],
          ),
        ),
      );
      expect(tester.getTopLeft(find.byKey(const Key('header'))).dy, 0);

      controller.jumpTo(500);
      await tester.pump();
      // Still painted at the leading edge — pinned, not scrolled away.
      expect(tester.getTopLeft(find.byKey(const Key('header'))).dy, 0);
      // And it still occupies its extent in the scroll geometry.
      expect(controller.position.maxScrollExtent, 3000 + 50 - 600);
    });

    testWidgets('LegendSliverSection groups a header with its slivers', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          LegendBody.slivers(
            safeArea: false,
            padding: EdgeInsets.zero,
            controller: controller,
            slivers: [
              LegendSliverSection(
                header: const Text('Section A'),
                pinHeader: true,
                slivers: [
                  SliverList.list(children: const [SizedBox(height: 2000)]),
                ],
              ),
              LegendSliverSection(
                header: const Text('Section B'),
                slivers: [
                  SliverList.list(children: const [Text('b-content')]),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.text('Section A'), findsOneWidget);

      controller.jumpTo(300);
      await tester.pump();
      // Pinned within its section: still at the top of the viewport.
      expect(tester.getTopLeft(find.text('Section A')).dy, 0);
    });
  });

  group('LegendBody — scrollbar', () {
    testWidgets('RawScrollbar appears only when requested, with themed '
        'geometry', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendBody(children: [SizedBox(height: 10)])),
      );
      expect(find.byType(RawScrollbar), findsNothing);

      await tester.pumpWidget(
        _wrap(
          const LegendBody(
            scrollbar: true,
            scrollbarThickness: 12,
            children: [SizedBox(height: 10)],
          ),
        ),
      );
      final scrollbar = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
      expect(scrollbar.thickness, 12);
      expect(scrollbar.radius, const Radius.circular(4)); // annotation default
    });
  });
}
