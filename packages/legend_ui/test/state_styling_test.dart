// Per-state color pins (RFC-002 R6 adoption, Phase C).
//
// These tests were written against the PRE-conversion behavior (hand-rolled
// `states.hovered ? … : …` builders) and pin the exact color every
// representative interaction state produced. The `LegendStates<Color>`
// conversion must keep every pin green — zero visual drift.
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _tokens = LegendTokens.light;
LegendColors get _colors => _tokens.colors;

/// The exact hover/press blends the buttons used pre-conversion
/// (LegendButtonCore's `Color.alphaBlend` arms).
Color _hoverBlend(Color foreground, Color background) =>
    Color.alphaBlend(foreground.withValues(alpha: 0.08), background);
Color _pressBlend(Color foreground, Color background) =>
    Color.alphaBlend(foreground.withValues(alpha: 0.16), background);

Widget _wrap(Widget child) {
  return LegendTheme(
    data: const LegendThemeData(tokens: _tokens),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: Center(child: child),
      ),
    ),
  );
}

/// Harness for overlay-based components (dropdown, context menu).
Widget _overlayApp(Widget child) {
  return LegendTheme(
    data: const LegendThemeData(tokens: _tokens),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: TapRegionSurface(
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: Center(child: child),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The decoration color of the nearest surface container above [inner].
Color? _surfaceColorAbove(WidgetTester tester, Finder inner) {
  final ancestors = find.ancestor(
    of: inner,
    matching: find.byWidgetPredicate(
      (w) =>
          (w is Container && w.decoration is BoxDecoration) ||
          w is AnimatedContainer,
    ),
  );
  final widget = tester.widget(ancestors.first);
  final decoration = switch (widget) {
    Container(:final decoration) => decoration,
    AnimatedContainer(:final decoration) => decoration,
    _ => null,
  };
  return (decoration as BoxDecoration?)?.color;
}

BoxDecoration _buttonDecoration(WidgetTester tester, Finder button) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(of: button, matching: find.byType(AnimatedContainer)),
  );
  return container.decoration! as BoxDecoration;
}

Color _labelColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

Future<TestGesture> _hoverOver(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(finder));
  await tester.pumpAndSettle();
  return gesture;
}

void main() {
  setUp(() {
    // Hover highlights are gated on the focus highlight mode, which the
    // test platform defaults to `touch` — force the desktop behavior so
    // FocusableActionDetector reports hover (same recipe as the framework's
    // own hover tests).
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('PrimaryLegendButton per-state colors', () {
    Widget button({bool enabled = true}) => _wrap(
      PrimaryLegendButton(onPressed: () {}, enabled: enabled, text: 'Save'),
    );
    final finder = find.byType(PrimaryLegendButton);

    testWidgets('normal: primary fill, onPrimary label', (tester) async {
      await tester.pumpWidget(button());
      expect(_buttonDecoration(tester, finder).color, _colors.primary);
      expect(_labelColor(tester, 'Save'), _colors.onPrimary);
    });

    testWidgets('hovered: onPrimary 8% blend over primary', (tester) async {
      await tester.pumpWidget(button());
      await _hoverOver(tester, finder);
      expect(
        _buttonDecoration(tester, finder).color,
        _hoverBlend(_colors.onPrimary, _colors.primary),
      );
    });

    testWidgets('pressed: onPrimary 16% blend over primary', (tester) async {
      await tester.pumpWidget(button());
      final gesture = await tester.startGesture(tester.getCenter(finder));
      await tester.pump();
      expect(
        _buttonDecoration(tester, finder).color,
        _pressBlend(_colors.onPrimary, _colors.primary),
      );
      await gesture.up();
    });

    testWidgets('disabled: disabled fill, onDisabled label', (tester) async {
      await tester.pumpWidget(button(enabled: false));
      expect(_buttonDecoration(tester, finder).color, _colors.disabled);
      expect(_labelColor(tester, 'Save'), _colors.onDisabled);
    });
  });

  group('SecondaryLegendButton per-state colors', () {
    Widget button({bool enabled = true}) => _wrap(
      SecondaryLegendButton(onPressed: () {}, enabled: enabled, text: 'More'),
    );
    final finder = find.byType(SecondaryLegendButton);

    testWidgets('normal: container fill, primary label and border', (
      tester,
    ) async {
      await tester.pumpWidget(button());
      final decoration = _buttonDecoration(tester, finder);
      expect(decoration.color, _colors.primaryContainer);
      expect((decoration.border! as Border).top.color, _colors.primary);
      expect(_labelColor(tester, 'More'), _colors.primary);
    });

    testWidgets('hovered: primary 8% blend over container', (tester) async {
      await tester.pumpWidget(button());
      await _hoverOver(tester, finder);
      expect(
        _buttonDecoration(tester, finder).color,
        _hoverBlend(_colors.primary, _colors.primaryContainer),
      );
    });

    testWidgets('pressed: primary 16% blend over container', (tester) async {
      await tester.pumpWidget(button());
      final gesture = await tester.startGesture(tester.getCenter(finder));
      await tester.pump();
      expect(
        _buttonDecoration(tester, finder).color,
        _pressBlend(_colors.primary, _colors.primaryContainer),
      );
      await gesture.up();
    });

    testWidgets('disabled: disabled fill, border dropped', (tester) async {
      await tester.pumpWidget(button(enabled: false));
      final decoration = _buttonDecoration(tester, finder);
      expect(decoration.color, _colors.disabled);
      expect(decoration.border, isNull);
      expect(_labelColor(tester, 'More'), _colors.onDisabled);
    });
  });

  group('LegendTextButton per-state colors', () {
    Widget button({bool enabled = true}) => _wrap(
      LegendTextButton(onPressed: () {}, enabled: enabled, text: 'Skip'),
    );
    final finder = find.byType(LegendTextButton);
    const transparent = Color(0x00000000);

    testWidgets('normal: transparent fill, primary label', (tester) async {
      await tester.pumpWidget(button());
      expect(_buttonDecoration(tester, finder).color, transparent);
      expect(_labelColor(tester, 'Skip'), _colors.primary);
    });

    testWidgets('hovered: primary 8% tint over transparency', (tester) async {
      await tester.pumpWidget(button());
      await _hoverOver(tester, finder);
      expect(
        _buttonDecoration(tester, finder).color,
        _hoverBlend(_colors.primary, transparent),
      );
    });

    testWidgets('pressed: primary 16% tint over transparency', (tester) async {
      await tester.pumpWidget(button());
      final gesture = await tester.startGesture(tester.getCenter(finder));
      await tester.pump();
      expect(
        _buttonDecoration(tester, finder).color,
        _pressBlend(_colors.primary, transparent),
      );
      await gesture.up();
    });

    testWidgets('disabled: stays transparent (no grey slab), onDisabled '
        'label', (tester) async {
      await tester.pumpWidget(button(enabled: false));
      expect(_buttonDecoration(tester, finder).color, transparent);
      expect(_labelColor(tester, 'Skip'), _colors.onDisabled);
    });
  });

  group('LegendDropdown menu item per-state colors', () {
    const items = [
      LegendDropdownItem(value: 1, label: 'One'),
      LegendDropdownItem(value: 2, label: 'Two'),
    ];

    Future<void> pumpOpen(WidgetTester tester) async {
      await tester.pumpWidget(
        _overlayApp(
          LegendDropdown<int>(
            items: items,
            value: 1,
            placeholder: 'Pick',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.tap(find.byType(LegendDropdown<int>));
      await tester.pumpAndSettle();
    }

    testWidgets('resting item: menu surface color', (tester) async {
      await pumpOpen(tester);
      expect(_surfaceColorAbove(tester, find.text('Two')), _colors.surface);
    });

    testWidgets('hovered item: background2', (tester) async {
      await pumpOpen(tester);
      await _hoverOver(tester, find.text('Two'));
      expect(_surfaceColorAbove(tester, find.text('Two')), _colors.background2);
    });

    testWidgets('selected item label primary, others foreground1', (
      tester,
    ) async {
      await pumpOpen(tester);
      // 'One' appears in the trigger and the menu; the menu copy is last.
      final menuOne = tester.widgetList<Text>(find.text('One')).last;
      expect(menuOne.style!.color, _colors.primary);
      expect(_labelColor(tester, 'Two'), _colors.foreground1);
    });
  });

  group('LegendContextMenu entry per-state colors', () {
    Future<void> pumpOpen(WidgetTester tester) async {
      await tester.pumpWidget(
        _overlayApp(
          LegendContextMenu(
            entries: [LegendContextMenuEntry(label: 'Copy', onSelected: () {})],
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      );
      await tester.tap(
        find.byType(LegendContextMenu),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('resting entry: menu surface color', (tester) async {
      await pumpOpen(tester);
      expect(_surfaceColorAbove(tester, find.text('Copy')), _colors.surface);
      expect(_labelColor(tester, 'Copy'), _colors.foreground1);
    });

    testWidgets('hovered entry: background2', (tester) async {
      await pumpOpen(tester);
      await _hoverOver(tester, find.text('Copy'));
      expect(
        _surfaceColorAbove(tester, find.text('Copy')),
        _colors.background2,
      );
    });
  });

  group('LegendSider item per-state colors', () {
    const items = [
      LegendNavItem(label: 'Home'),
      LegendNavItem(label: 'Settings'),
    ];

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 400,
            child: LegendSider(
              items: items,
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('selected item: primaryContainer fill, selectedColor label', (
      tester,
    ) async {
      await pump(tester);
      expect(
        _surfaceColorAbove(tester, find.text('Home')),
        _colors.primaryContainer,
      );
      expect(_labelColor(tester, 'Home'), _colors.primary);
    });

    testWidgets('unselected resting item: sider background fill', (
      tester,
    ) async {
      await pump(tester);
      expect(
        _surfaceColorAbove(tester, find.text('Settings')),
        _colors.surface,
      );
      expect(_labelColor(tester, 'Settings'), _colors.foreground2);
    });

    testWidgets('unselected hovered item: background2', (tester) async {
      await pump(tester);
      await _hoverOver(tester, find.text('Settings'));
      expect(
        _surfaceColorAbove(tester, find.text('Settings')),
        _colors.background2,
      );
    });
  });

  group('LegendExpandable header per-state colors', () {
    Widget expandable() => _wrap(
      const SizedBox(
        width: 300,
        child: LegendExpandable(title: 'Details', child: Text('Body')),
      ),
    );

    testWidgets('resting header: backgroundColor', (tester) async {
      await tester.pumpWidget(expandable());
      expect(_surfaceColorAbove(tester, find.text('Details')), _colors.surface);
    });

    testWidgets('hovered header: background2', (tester) async {
      await tester.pumpWidget(expandable());
      await _hoverOver(tester, find.text('Details'));
      expect(
        _surfaceColorAbove(tester, find.text('Details')),
        _colors.background2,
      );
    });
  });

  group('LegendSwitch per-state colors (unconverted: no hover/press '
      'differentiation — plain Color fields stay, RFC-002 R6)', () {
    Widget switchAt({required bool value, bool enabled = true}) =>
        _wrap(LegendSwitch(value: value, onChanged: (_) {}, enabled: enabled));

    Color trackColor(WidgetTester tester) {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(LegendSwitch),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    testWidgets('on: activeTrack', (tester) async {
      await tester.pumpWidget(switchAt(value: true));
      expect(trackColor(tester), _colors.primary);
    });

    testWidgets('off: inactiveTrack', (tester) async {
      await tester.pumpWidget(switchAt(value: false));
      expect(trackColor(tester), _colors.background3);
    });

    testWidgets('disabled: disabled track regardless of value', (tester) async {
      await tester.pumpWidget(switchAt(value: true, enabled: false));
      expect(trackColor(tester), _colors.disabled);
    });
  });
}
