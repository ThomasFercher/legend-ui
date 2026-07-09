import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _items = [
  LegendDropdownItem(value: 1, label: 'One'),
  LegendDropdownItem(value: 2, label: 'Two'),
];

Widget _app({required ValueChanged<int> onChanged, int? value}) {
  return LegendTheme(
    data: const LegendThemeData(tokens: LegendTokens.light),
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
                  child: LegendDropdown<int>(
                    items: _items,
                    value: value,
                    placeholder: 'Pick',
                    onChanged: onChanged,
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
  testWidgets('opens on tap, selecting an item reports and closes', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(_app(onChanged: (v) => selected = v));

    expect(find.text('Pick'), findsOneWidget);
    expect(find.text('Two'), findsNothing);

    await tester.tap(find.byType(LegendDropdown<int>));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget);

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(find.text('Two'), findsNothing);
  });

  testWidgets('tap outside dismisses the menu', (tester) async {
    await tester.pumpWidget(_app(onChanged: (_) {}));
    await tester.tap(find.byType(LegendDropdown<int>));
    await tester.pumpAndSettle();
    expect(find.text('One'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('One'), findsNothing);
  });

  testWidgets('shows the selected value in the trigger', (tester) async {
    await tester.pumpWidget(_app(onChanged: (_) {}, value: 1));
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Pick'), findsNothing);
  });
}
