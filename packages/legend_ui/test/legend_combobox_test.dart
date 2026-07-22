import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _items = [
  LegendComboboxItem(value: 'eth', label: 'Ethereum'),
  LegendComboboxItem(value: 'btc', label: 'Bitcoin'),
  LegendComboboxItem(value: 'sol', label: 'Solana'),
];

Widget _app({
  required ValueChanged<String> onChanged,
  String? value,
  bool enabled = true,
  LegendComboboxFilter<String>? filter,
  LegendThemeData? theme,
}) {
  return LegendTheme(
    data: theme ?? const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      // WidgetsApp installs this in real apps; TapRegion dismissal
      // depends on it.
      child: TapRegionSurface(
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              // The ColoredBox stands in for an app's background surface;
              // without a hit-testable backdrop, outside taps reach
              // nothing and TapRegion cannot observe them.
              builder: (context) => ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: Center(
                  child: SizedBox(
                    width: 280,
                    child: LegendCombobox<String>(
                      items: _items,
                      value: value,
                      placeholder: 'Pick a token',
                      enabled: enabled,
                      filter: filter,
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('opens on tap, selecting an option reports and closes', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(_app(onChanged: (v) => selected = v));

    expect(find.text('Pick a token'), findsOneWidget);
    expect(find.text('Bitcoin'), findsNothing);

    await tester.tap(find.byType(LegendCombobox<String>));
    await tester.pumpAndSettle();
    expect(find.text('Bitcoin'), findsOneWidget);

    await tester.tap(find.text('Bitcoin'));
    await tester.pumpAndSettle();
    expect(selected, 'btc');
    // The field now carries the selected label; the panel is gone (only
    // the field's own EditableText still shows the text).
    expect(find.text('Solana'), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Bitcoin',
    );
  });

  testWidgets('typing filters the options case-insensitively', (tester) async {
    await tester.pumpWidget(_app(onChanged: (_) {}));

    await tester.enterText(find.byType(EditableText), 'BIT');
    await tester.pumpAndSettle();
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Ethereum'), findsNothing);
    expect(find.text('Solana'), findsNothing);
  });

  testWidgets('a query with no matches shows emptyText', (tester) async {
    await tester.pumpWidget(_app(onChanged: (_) {}));

    await tester.enterText(find.byType(EditableText), 'doge');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('a custom filter callback replaces the default', (tester) async {
    await tester.pumpWidget(
      _app(
        onChanged: (_) {},
        // Match on the VALUE instead of the label.
        filter: (item, query) => item.value.contains(query),
      ),
    );

    await tester.enterText(find.byType(EditableText), 'btc');
    await tester.pumpAndSettle();
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Ethereum'), findsNothing);
  });

  testWidgets('arrows move the highlight and Enter commits it', (tester) async {
    String? selected;
    await tester.pumpWidget(_app(onChanged: (v) => selected = v));

    await tester.tap(find.byType(LegendCombobox<String>));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected, 'btc');
    expect(find.text('Solana'), findsNothing);
  });

  testWidgets('Escape closes the panel without selecting', (tester) async {
    String? selected;
    await tester.pumpWidget(_app(onChanged: (v) => selected = v));

    await tester.tap(find.byType(LegendCombobox<String>));
    await tester.pumpAndSettle();
    expect(find.text('Solana'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Solana'), findsNothing);
    expect(selected, isNull);
  });

  testWidgets('tap outside dismisses the panel', (tester) async {
    await tester.pumpWidget(_app(onChanged: (_) {}));

    await tester.tap(find.byType(LegendCombobox<String>));
    await tester.pumpAndSettle();
    expect(find.text('Ethereum'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Ethereum'), findsNothing);
  });

  testWidgets('blur without a selection reverts the text', (tester) async {
    await tester.pumpWidget(_app(onChanged: (_) {}, value: 'eth'));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Ethereum',
    );

    await tester.enterText(find.byType(EditableText), 'garbage');
    await tester.pumpAndSettle();

    // Unfocus = blur; the typed text was never committed.
    tester.widget<EditableText>(find.byType(EditableText)).focusNode.unfocus();
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Ethereum',
    );
  });

  testWidgets('blur with no value at all clears the text', (tester) async {
    await tester.pumpWidget(_app(onChanged: (_) {}));

    await tester.enterText(find.byType(EditableText), 'gar');
    await tester.pumpAndSettle();

    tester.widget<EditableText>(find.byType(EditableText)).focusNode.unfocus();
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
  });

  testWidgets('disabled: no panel on tap, field is read-only', (tester) async {
    await tester.pumpWidget(_app(onChanged: (_) {}, enabled: false));

    await tester.tap(find.byType(LegendCombobox<String>));
    await tester.pumpAndSettle();
    expect(find.text('Ethereum'), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );
  });

  testWidgets('options announce their selected state', (tester) async {
    await tester.pumpWidget(_app(onChanged: (_) {}, value: 'btc'));

    await tester.tap(find.byType(LegendCombobox<String>));
    await tester.pumpAndSettle();

    // The field itself also shows 'Bitcoin'; the panel option is the last
    // match (overlay entries build after their anchor).
    expect(
      tester.getSemantics(find.text('Bitcoin').last),
      containsSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(find.text('Solana')),
      containsSemantics(isSelected: false),
    );
  });

  testWidgets(
    'level-3 registry override restyles the panel (four-level resolution)',
    (tester) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _app(
          onChanged: (_) {},
          theme: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendCombobox: LegendComboboxThemeNullable(
                menuBackground: InteractiveColors(normal: navy),
              ),
            },
          ),
        ),
      );

      await tester.tap(find.byType(LegendCombobox<String>));
      await tester.pumpAndSettle();

      final surfaces = tester.widgetList<LegendSurface>(
        find.byType(LegendSurface),
      );
      expect(surfaces.any((s) => s.color == navy), isTrue);
    },
  );
}
