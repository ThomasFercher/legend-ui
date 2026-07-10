import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _items = [LegendNavItem(label: 'Home'), LegendNavItem(label: 'Settings')];

Widget _shellApp() {
  return LegendApp(
    theme: const LegendThemeData(tokens: LegendTokens.light),
    home: LegendScaffold(
      appBar: const LegendAppBar(title: 'Demo'),
      sider: LegendSider(items: _items, selectedIndex: 0, onSelected: (_) {}),
      bottomBar: LegendBottomBar(
        items: _items,
        selectedIndex: 0,
        onSelected: (_) {},
      ),
      body: const Center(child: LegendText('body')),
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
    expect(find.byType(LegendBottomBar), findsOneWidget);
    expect(find.byType(LegendSider), findsNothing);
    expect(find.text('Demo'), findsOneWidget);
  });

  testWidgets('wide width shows sider, hides bottom bar', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_shellApp());
    await tester.pump();
    expect(find.byType(LegendSider), findsOneWidget);
    expect(find.byType(LegendBottomBar), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('nav selection reports the tapped index', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    int? selected;
    await tester.pumpWidget(
      LegendApp(
        theme: const LegendThemeData(tokens: LegendTokens.light),
        home: LegendScaffold(
          sider: LegendSider(
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

  testWidgets('LegendApp forwards WidgetsApp passthroughs', (tester) async {
    const scopeId = 'legend-app';
    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.keyK, control: true):
          const ActivateIntent(),
    };
    final actions = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => null),
    };

    await tester.pumpWidget(
      LegendApp(
        theme: const LegendThemeData(tokens: LegendTokens.light),
        restorationScopeId: scopeId,
        shortcuts: shortcuts,
        actions: actions,
        debugShowCheckedModeBanner: false,
        home: const SizedBox.shrink(),
      ),
    );

    final app = tester.widget<WidgetsApp>(find.byType(WidgetsApp));
    expect(app.restorationScopeId, scopeId);
    expect(app.shortcuts, same(shortcuts));
    expect(app.actions, same(actions));
    expect(app.debugShowCheckedModeBanner, isFalse);
  });
}
