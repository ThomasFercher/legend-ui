import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child, {LegendThemeData? data}) {
  return LegendTheme(
    data: data ?? const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

/// The row's surface fill — the AnimatedContainer LegendSurface renders.
Color? _fill(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(LegendListItem),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (container.decoration! as BoxDecoration).color;
}

void main() {
  group('LegendListItem — activation', () {
    testWidgets('tap fires onTap and announces a semantic button', (
      tester,
    ) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(LegendListItem(title: 'Ethereum', onTap: () => taps++)),
      );

      expect(find.byType(LegendInteractive), findsOneWidget);
      expect(find.byType(LegendSelectionControl), findsNothing);
      final node = tester.getSemantics(find.byType(LegendListItem));
      expect(node.flagsCollection.isButton, isTrue);

      await tester.tap(find.text('Ethereum'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('a disabled row is inert', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          LegendListItem(
            title: 'Ethereum',
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('Ethereum'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps, 0);
    });

    testWidgets('a static row (no onTap, no selected) composes no '
        'interaction primitive and has no tap action', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const LegendListItem(title: 'Ethereum')));

      expect(find.byType(LegendInteractive), findsNothing);
      expect(find.byType(LegendSelectionControl), findsNothing);

      SemanticsNode? withTap;
      tester.getSemantics(find.byType(LegendListItem)).visitChildren((node) {
        if (node.getSemanticsData().hasAction(SemanticsAction.tap)) {
          withTap = node;
        }
        return true;
      });
      expect(withTap, isNull);
      handle.dispose();
    });
  });

  group('LegendListItem — selection', () {
    testWidgets('a selected:-bearing row announces selected state, not a '
        'button, and still activates through onTap', (tester) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          LegendListItem(
            title: 'Ethereum',
            selected: true,
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.byType(LegendSelectionControl), findsOneWidget);
      expect(find.byType(LegendInteractive), findsNothing);
      final flags = tester
          .getSemantics(find.byType(LegendSelectionControl))
          .flagsCollection;
      expect(flags.isSelected, Tristate.isTrue);
      expect(flags.isButton, isFalse);

      await tester.tap(find.text('Ethereum'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('a selected row fills with selectedBackground and tints the '
        'title with selectedColor', (tester) async {
      await tester.pumpWidget(
        _wrap(LegendListItem(title: 'Ethereum', selected: true, onTap: () {})),
      );
      expect(_fill(tester), LegendTokens.light.colors.primaryContainer);
      final title = tester.widget<Text>(find.text('Ethereum'));
      expect(title.style?.color, LegendTokens.light.colors.primary);
    });

    testWidgets('an unselected row rests on the normal per-state fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(LegendListItem(title: 'Ethereum', selected: false, onTap: () {})),
      );
      expect(_fill(tester), LegendTokens.light.colors.surface);
      final title = tester.widget<Text>(find.text('Ethereum'));
      expect(title.style?.color, LegendTokens.light.colors.foreground1);
    });
  });

  group('LegendListItem — slots and theming', () {
    testWidgets('subtitle, leading and trailing all render', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegendListItem(
            title: 'Ethereum',
            subtitle: 'ETH',
            leading: SizedBox(key: Key('avatar'), width: 32, height: 32),
            trailing: Text(r'$3,120.55'),
          ),
        ),
      );
      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.byKey(const Key('avatar')), findsOneWidget);
      expect(find.text(r'$3,120.55'), findsOneWidget);

      final subtitle = tester.widget<Text>(find.text('ETH'));
      expect(subtitle.style?.color, LegendTokens.light.colors.foreground2);
    });

    testWidgets('level-3 registry override restyles selectedBackground; the '
        'constructor param still wins', (tester) async {
      const registry = Color(0xFF001F54);
      const param = Color(0xFF8B0000);
      const data = LegendThemeData(
        tokens: LegendTokens.light,
        components: {
          LegendListItem: LegendListItemThemeNullable(
            selectedBackground: registry,
          ),
        },
      );

      await tester.pumpWidget(
        _wrap(
          LegendListItem(title: 'Ethereum', selected: true, onTap: () {}),
          data: data,
        ),
      );
      expect(_fill(tester), registry);

      await tester.pumpWidget(
        _wrap(
          LegendListItem(
            title: 'Ethereum',
            selected: true,
            selectedBackground: param,
            onTap: () {},
          ),
          data: data,
        ),
      );
      await tester.pumpAndSettle();
      expect(_fill(tester), param);
    });
  });

  group('LegendList', () {
    testWidgets('renders the section header in the themed muted style', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendList(
            header: 'Tokens',
            children: [LegendListItem(title: 'Ethereum')],
          ),
        ),
      );
      final header = tester.widget<Text>(find.text('Tokens'));
      expect(header.style?.color, LegendTokens.light.colors.foreground2);
    });

    testWidgets('dividers: true rules between consecutive rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendList(
            dividers: true,
            children: [
              LegendListItem(title: 'One'),
              LegendListItem(title: 'Two'),
              LegendListItem(title: 'Three'),
            ],
          ),
        ),
      );
      expect(find.byType(LegendDivider), findsNWidgets(2));
    });

    testWidgets('without dividers the rows separate by the spacing gap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendList(
            spacing: 12,
            children: [
              LegendListItem(title: 'One'),
              LegendListItem(title: 'Two'),
            ],
          ),
        ),
      );
      expect(find.byType(LegendDivider), findsNothing);
      final first = tester.getBottomLeft(find.byType(LegendListItem).first);
      final second = tester.getTopLeft(find.byType(LegendListItem).last);
      expect(second.dy - first.dy, 12);
    });
  });
}
