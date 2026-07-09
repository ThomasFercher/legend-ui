import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

void main() {
  testWidgets('gallery renders, navigates sections, toggles theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GalleryApp());
    await tester.pump();
    expect(find.text('Primary'), findsOneWidget);

    await tester.tap(find.text('Typography'));
    await tester.pumpAndSettle();
    expect(find.text('Heading 1'), findsOneWidget);

    await tester.tap(find.byType(LegendSwitch));
    await tester.pumpAndSettle();
    final text = tester.widget<Text>(find.text('Heading 1'));
    expect(text.style?.color, LegendTokens.dark.colors.foreground1);
  });
}
