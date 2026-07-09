import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

const _items = [NomoNavItem(label: 'Home'), NomoNavItem(label: 'Settings')];

Widget _shellApp() {
  return NomoApp(
    theme: const NomoThemeData(tokens: NomoTokens.light),
    home: NomoScaffold(
      appBar: const NomoAppBar(title: 'Demo'),
      sider: NomoSider(items: _items, selectedIndex: 0, onSelected: (_) {}),
      bottomBar: NomoBottomBar(
        items: _items,
        selectedIndex: 0,
        onSelected: (_) {},
      ),
      body: const Center(child: NomoText('body')),
    ),
  );
}

void main() {
  testWidgets('compact width shows bottom bar, hides sider', (tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_shellApp());
    await tester.pump();
    expect(find.byType(NomoBottomBar), findsOneWidget);
    expect(find.byType(NomoSider), findsNothing);
    expect(find.text('Demo'), findsOneWidget);
  });

  testWidgets('wide width shows sider, hides bottom bar', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_shellApp());
    await tester.pump();
    expect(find.byType(NomoSider), findsOneWidget);
    expect(find.byType(NomoBottomBar), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('nav selection reports the tapped index', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    int? selected;
    await tester.pumpWidget(
      NomoApp(
        theme: const NomoThemeData(tokens: NomoTokens.light),
        home: NomoScaffold(
          sider: NomoSider(
            items: _items,
            selectedIndex: 0,
            onSelected: (i) => selected = i,
          ),
          body: const SizedBox(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Settings'));
    expect(selected, 1);
  });
}
