import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

Widget _wrap(Widget child) {
  return NomoTheme(
    data: const NomoThemeData(tokens: NomoTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

void main() {
  group('NomoText', () {
    testWidgets('uses variant token style and default color', (tester) async {
      await tester.pumpWidget(
        _wrap(const NomoText('Hi', variant: NomoTextVariant.h2)),
      );
      final text = tester.widget<Text>(find.text('Hi'));
      expect(text.style?.fontSize, NomoTokens.light.typography.h2.fontSize);
      expect(text.style?.color, NomoTokens.light.colors.foreground1);
    });
  });

  group('buttons on NomoButtonCore', () {
    testWidgets('secondary applies themed border and tap works', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(SecondaryNomoButton(onPressed: () => taps++, text: 'Sec')),
      );
      await tester.tap(find.text('Sec'));
      expect(taps, 1);
    });

    testWidgets('text button is transparent by default', (tester) async {
      await tester.pumpWidget(
        _wrap(NomoTextButton(onPressed: () {}, text: 'Txt')),
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final color = (container.decoration! as BoxDecoration).color!;
      expect(color.a, 0);
    });
  });

  group('NomoSwitch', () {
    testWidgets('toggles and animates thumb alignment', (tester) async {
      var value = false;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => NomoSwitch(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(NomoSwitch));
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
          NomoSwitch(value: true, onChanged: (_) {}, semanticLabel: 'Dark'),
        ),
      );
      final node = tester.getSemantics(find.byType(NomoSwitch));
      final flags = node.flagsCollection;
      expect(flags.isToggled, Tristate.isTrue);
      expect(flags.isButton, isFalse);
      expect(node.label, 'Dark');
      handle.dispose();
    });
  });

  group('NomoTextField', () {
    testWidgets('typing updates, placeholder hides, error shows', (
      tester,
    ) async {
      final controller = TextEditingController();
      String? error;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => NomoTextField(
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

  group('NomoDialog via showNomoDialog', () {
    testWidgets('opens above the app and pops with a result', (tester) async {
      String? result;
      await tester.pumpWidget(
        NomoApp(
          theme: const NomoThemeData(tokens: NomoTokens.light),
          home: Builder(
            builder: (context) => Center(
              child: PrimaryNomoButton(
                text: 'Open',
                onPressed: () async {
                  result = await showNomoDialog<String>(
                    context: context,
                    builder: (context) => NomoDialog(
                      title: 'Confirm',
                      content: const NomoText('Sure?'),
                      actions: [
                        PrimaryNomoButton(
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

  group('AnimatedNomoTheme', () {
    testWidgets('token switch animates through intermediate values', (
      tester,
    ) async {
      var tokens = NomoTokens.light;
      late StateSetter setTheme;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setTheme = setState;
            return AnimatedNomoTheme(
              data: NomoThemeData(tokens: tokens),
              duration: const Duration(milliseconds: 200),
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: Center(child: NomoText('x')),
              ),
            );
          },
        ),
      );
      Color textColor() => tester.widget<Text>(find.text('x')).style!.color!;
      final before = textColor();

      setTheme(() => tokens = NomoTokens.dark);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = textColor();
      expect(mid, isNot(before));
      expect(mid, isNot(NomoTokens.dark.colors.foreground1));

      await tester.pumpAndSettle();
      expect(textColor(), NomoTokens.dark.colors.foreground1);
    });
  });

  group('NomoBreakpoints', () {
    testWidgets('tier follows window width', (tester) async {
      NomoTier? tier;
      Widget probe() => NomoBreakpointScope(
        child: Builder(
          builder: (context) {
            tier = NomoBreakpoints.of(context).tier;
            return const SizedBox();
          },
        ),
      );
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(probe());
      expect(tier, NomoTier.compact);

      tester.view.physicalSize = const Size(800, 800);
      await tester.pumpWidget(probe());
      expect(tier, NomoTier.medium);

      tester.view.physicalSize = const Size(1300, 800);
      await tester.pumpWidget(probe());
      expect(tier, NomoTier.expanded);
    });
  });
}
