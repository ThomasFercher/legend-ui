import 'package:flutter/material.dart'
    show Material, MaterialApp, SelectionArea;
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
  group('LegendText.rich', () {
    testWidgets('unstyled spans inherit the token base style', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegendText.rich(
            TextSpan(
              text: 'Plain ',
              children: [TextSpan(text: 'still plain')],
            ),
            variant: LegendTextVariant.h2,
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      const tokens = LegendTokens.light;
      // The base style handed to Text.rich is the variant's token style with
      // the foreground1 fallback color; inherit-style child spans pick it up.
      expect(text.textSpan, isNotNull);
      expect(text.style?.fontSize, tokens.typography.h2.fontSize);
      expect(text.style?.fontWeight, tokens.typography.h2.fontWeight);
      expect(text.style?.color, tokens.colors.foreground1);
      final child = (text.textSpan! as TextSpan).children!.single as TextSpan;
      expect(child.style, isNull); // nothing overrides the inherited base
    });

    testWidgets('styled child spans override the base', (tester) async {
      const highlight = Color(0xFF123456);
      await tester.pumpWidget(
        _wrap(
          const LegendText.rich(
            TextSpan(
              text: 'Normal ',
              children: [
                TextSpan(
                  text: 'bold blue',
                  style: TextStyle(
                    color: highlight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      // Text.rich wraps the provided span in a root span that carries the
      // resolved base style.
      final root = richText.text as TextSpan;
      const tokens = LegendTokens.light;
      expect(root.style?.fontSize, tokens.typography.b1.fontSize);
      expect(root.style?.color, tokens.colors.foreground1);
      // …and the styled child merges its own values over that base.
      final provided = root.children!.single as TextSpan;
      expect(provided.style, isNull); // 'Normal ' inherits the base
      final child = provided.children!.single as TextSpan;
      expect(child.style?.color, highlight);
      expect(child.style?.fontWeight, FontWeight.w700);
      expect(child.style!.inherit, isTrue); // still inherits the rest
    });

    testWidgets('builds under a SelectionArea', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LegendTheme(
            data: LegendThemeData(tokens: LegendTokens.light),
            child: Material(
              child: SelectionArea(
                child: Center(
                  child: LegendText.rich(
                    TextSpan(
                      text: 'Selectable ',
                      children: [TextSpan(text: 'rich text')],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Selectable'), findsOneWidget);
      // Text.rich registers with the enclosing SelectionArea via a
      // SelectionContainer registrar — the paragraph must be selectable.
      final registrar = tester.element(find.byType(RichText));
      expect(
        SelectionContainer.maybeOf(registrar),
        isNotNull,
        reason: 'LegendText.rich must participate in selection',
      );
    });
  });
}
