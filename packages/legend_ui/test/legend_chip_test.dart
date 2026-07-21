import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _colors = LegendColors.light;

Widget _wrap(Widget child, {LegendThemeData? data}) {
  return LegendTheme(
    data: data ?? const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

/// The pill's current fill, read off its animated surface.
Color _fill(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find
        .descendant(
          of: find.byType(LegendChip),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color!;
}

Color _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

void main() {
  group('LegendChip — static mode', () {
    testWidgets('renders label, leading slot, and the resting fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendChip(
            label: 'Ethereum',
            leading: SizedBox.square(dimension: 12),
          ),
        ),
      );
      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
      expect(_fill(tester), _colors.background2);
      expect(_labelColor(tester, 'Ethereum'), _colors.foreground1);
      // No activation surface in static mode.
      expect(find.byType(LegendInteractive), findsNothing);
      expect(find.byType(LegendSelectionControl), findsNothing);
    });

    testWidgets('a number-only label renders compact without special casing', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendChip(label: '3')));
      final size = tester.getSize(find.byType(LegendChip));
      const tokens = LegendTokens.light;
      // Width = glyph + horizontal padding only — no imposed minimum.
      expect(size.width, lessThan(tokens.sizes.sm * 2 + 20));
    });

    testWidgets('disabled static chip draws the disabled colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendChip(label: 'Tag', enabled: false)),
      );
      expect(_fill(tester), _colors.disabled);
      expect(_labelColor(tester, 'Tag'), _colors.onDisabled);
    });
  });

  group('LegendChip — selectable mode', () {
    testWidgets('tap toggles: reports true, then false once selected', (
      tester,
    ) async {
      bool? next;
      await tester.pumpWidget(
        _wrap(LegendChip(label: 'Filter', onSelected: (v) => next = v)),
      );
      await tester.tap(find.byType(LegendChip));
      expect(next, isTrue);

      await tester.pumpWidget(
        _wrap(
          LegendChip(
            label: 'Filter',
            selected: true,
            onSelected: (v) => next = v,
          ),
        ),
      );
      await tester.tap(find.byType(LegendChip));
      expect(next, isFalse);
    });

    testWidgets('selected chip draws the selected colors', (tester) async {
      await tester.pumpWidget(
        _wrap(LegendChip(label: 'Filter', selected: true, onSelected: (_) {})),
      );
      expect(_fill(tester), _colors.primaryContainer);
      expect(_labelColor(tester, 'Filter'), _colors.onPrimaryContainer);
    });

    testWidgets('announces selected-role semantics with the label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(LegendChip(label: 'Filter', selected: true, onSelected: (_) {})),
      );
      final flags = tester
          .getSemantics(find.byType(LegendSelectionControl))
          .flagsCollection;
      expect(flags.isSelected, Tristate.isTrue);
      expect(flags.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('disabled selectable chip is inert', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(
          LegendChip(
            label: 'Filter',
            enabled: false,
            onSelected: (_) => called = true,
          ),
        ),
      );
      await tester.tap(find.byType(LegendChip), warnIfMissed: false);
      expect(called, isFalse);
      expect(_fill(tester), _colors.disabled);
    });
  });

  group('LegendChip — action mode', () {
    testWidgets('tap activates onTap with button semantics', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _wrap(LegendChip(label: '3', onTap: () => taps++)),
      );
      await tester.tap(find.byType(LegendChip));
      expect(taps, 1);
      final flags = tester
          .getSemantics(find.byType(LegendInteractive))
          .flagsCollection;
      expect(flags.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('disabled action chip is inert', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(LegendChip(label: 'Ask', enabled: false, onTap: () => taps++)),
      );
      await tester.tap(find.byType(LegendChip), warnIfMissed: false);
      expect(taps, 0);
    });
  });

  group('LegendChip — dismissible mode', () {
    testWidgets('the remove affordance fires onDismissed, not the chip', (
      tester,
    ) async {
      var dismissed = 0;
      bool? toggled;
      await tester.pumpWidget(
        _wrap(
          LegendChip(
            label: 'Tag',
            onSelected: (v) => toggled = v,
            onDismissed: () => dismissed++,
            dismissLabel: 'Remove Tag',
          ),
        ),
      );
      // The remove affordance is the only LegendInteractive beside the
      // selection control.
      await tester.tap(find.byType(LegendInteractive));
      expect(dismissed, 1);
      expect(toggled, isNull);
    });

    testWidgets('tapping the body still toggles beside the affordance', (
      tester,
    ) async {
      bool? toggled;
      await tester.pumpWidget(
        _wrap(
          LegendChip(
            label: 'Tag',
            onSelected: (v) => toggled = v,
            onDismissed: () {},
          ),
        ),
      );
      await tester.tap(find.text('Tag'));
      expect(toggled, isTrue);
    });

    testWidgets('a static chip can carry the affordance alone', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        _wrap(LegendChip(label: 'Tag', onDismissed: () => dismissed++)),
      );
      await tester.tap(find.byType(LegendInteractive));
      expect(dismissed, 1);
    });

    testWidgets('disabled chip has an inert remove affordance', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        _wrap(
          LegendChip(
            label: 'Tag',
            enabled: false,
            onDismissed: () => dismissed++,
          ),
        ),
      );
      await tester.tap(find.byType(LegendInteractive), warnIfMissed: false);
      expect(dismissed, 0);
    });
  });

  group('LegendChip — theming', () {
    testWidgets('constructor param beats every theme level', (tester) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          const LegendChip(
            label: 'Tag',
            background: InteractiveColors(normal: navy),
          ),
        ),
      );
      expect(_fill(tester), navy);
    });

    testWidgets('components-map entry restyles the selected fill', (
      tester,
    ) async {
      const gold = Color(0xFFFFD700);
      await tester.pumpWidget(
        _wrap(
          LegendChip(label: 'Tag', selected: true, onSelected: (_) {}),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendChip: LegendChipThemeNullable(
                selectedBackground: InteractiveColors(normal: gold),
              ),
            },
          ),
        ),
      );
      expect(_fill(tester), gold);
    });

    testWidgets('hover derives from the resolved normal fill', (tester) async {
      // Hover highlights are gated on the focus highlight mode, which the
      // test platform defaults to `touch` — force the desktop behavior so
      // FocusableActionDetector reports hover.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.pumpWidget(_wrap(LegendChip(label: 'Tag', onTap: () {})));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(LegendChip)));
      await tester.pumpAndSettle();
      const tokens = LegendTokens.light;
      expect(_fill(tester), tokens.states.hovered(_colors.background2));
    });
  });
}
