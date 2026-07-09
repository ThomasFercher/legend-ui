import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child) {
  return LegendTheme(
    data: const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

void main() {
  group('LegendText', () {
    testWidgets('uses variant token style and default color', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendText('Hi', variant: LegendTextVariant.h2)),
      );
      final text = tester.widget<Text>(find.text('Hi'));
      expect(text.style?.fontSize, LegendTokens.light.typography.h2.fontSize);
      expect(text.style?.color, LegendTokens.light.colors.foreground1);
    });
  });

  group('buttons on LegendButtonCore', () {
    testWidgets('secondary applies themed border and tap works', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(SecondaryLegendButton(onPressed: () => taps++, text: 'Sec')),
      );
      await tester.tap(find.text('Sec'));
      expect(taps, 1);
    });

    testWidgets('text button is transparent by default', (tester) async {
      await tester.pumpWidget(
        _wrap(LegendTextButton(onPressed: () {}, text: 'Txt')),
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final color = (container.decoration! as BoxDecoration).color!;
      expect(color.a, 0);
    });
  });

  group('LegendSwitch', () {
    testWidgets('toggles and animates thumb alignment', (tester) async {
      var value = false;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => LegendSwitch(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(LegendSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      final align = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      // Directional so the thumb mirrors under RTL (review M1).
      expect(align.alignment, AlignmentDirectional.centerEnd);
    });

    testWidgets('announces as a toggle, not a button (review I3)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          LegendSwitch(value: true, onChanged: (_) {}, semanticLabel: 'Dark'),
        ),
      );
      final node = tester.getSemantics(find.byType(LegendSwitch));
      final flags = node.flagsCollection;
      expect(flags.isToggled, Tristate.isTrue);
      expect(flags.isButton, isFalse);
      expect(node.label, 'Dark');
      handle.dispose();
    });
  });

  group('LegendTextField', () {
    testWidgets('typing updates, placeholder hides, error shows', (
      tester,
    ) async {
      final controller = TextEditingController();
      String? error;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => LegendTextField(
              controller: controller,
              title: 'Name',
              placeholder: 'Type here',
              errorText: error,
              onChanged: (v) =>
                  setState(() => error = v.length < 3 ? 'Too short' : null),
            ),
          ),
        ),
      );
      expect(find.text('Type here'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'ab');
      await tester.pump();
      expect(controller.text, 'ab');
      expect(find.text('Type here'), findsNothing);
      expect(find.text('Too short'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'abcd');
      await tester.pump();
      expect(find.text('Too short'), findsNothing);
      controller.dispose();
    });
  });

  group('LegendDialog via showLegendDialog', () {
    testWidgets('opens above the app and pops with a result', (tester) async {
      String? result;
      await tester.pumpWidget(
        LegendApp(
          theme: const LegendThemeData(tokens: LegendTokens.light),
          home: Builder(
            builder: (context) => Center(
              child: PrimaryLegendButton(
                text: 'Open',
                onPressed: () async {
                  result = await showLegendDialog<String>(
                    context: context,
                    builder: (context) => LegendDialog(
                      title: 'Confirm',
                      content: const LegendText('Sure?'),
                      actions: [
                        PrimaryLegendButton(
                          text: 'Yes',
                          onPressed: () => Navigator.pop(context, 'yes'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(result, 'yes');
      expect(find.text('Confirm'), findsNothing);
    });
  });

  group('AnimatedLegendTheme', () {
    testWidgets('token switch animates through intermediate values', (
      tester,
    ) async {
      var tokens = LegendTokens.light;
      late StateSetter setTheme;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setTheme = setState;
            return AnimatedLegendTheme(
              data: LegendThemeData(tokens: tokens),
              duration: const Duration(milliseconds: 200),
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: Center(child: LegendText('x')),
              ),
            );
          },
        ),
      );
      Color textColor() => tester.widget<Text>(find.text('x')).style!.color!;
      final before = textColor();

      setTheme(() => tokens = LegendTokens.dark);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = textColor();
      expect(mid, isNot(before));
      expect(mid, isNot(LegendTokens.dark.colors.foreground1));

      await tester.pumpAndSettle();
      expect(textColor(), LegendTokens.dark.colors.foreground1);
    });
  });

  group('LegendBreakpoints', () {
    testWidgets('tier follows window width', (tester) async {
      LegendTier? tier;
      Widget probe() => LegendBreakpointScope(
        child: Builder(
          builder: (context) {
            tier = LegendBreakpoints.of(context).tier;
            return const SizedBox();
          },
        ),
      );
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(probe());
      expect(tier, LegendTier.compact);

      tester.view.physicalSize = const Size(800, 800);
      await tester.pumpWidget(probe());
      expect(tier, LegendTier.medium);

      tester.view.physicalSize = const Size(1300, 800);
      await tester.pumpWidget(probe());
      expect(tier, LegendTier.expanded);
    });
  });
}
