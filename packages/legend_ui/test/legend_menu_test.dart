import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _tokens = LegendTokens.light;

/// Overlay harness: `TapRegionSurface` (WidgetsApp installs it in real
/// apps; dismissal depends on it) plus a hit-testable backdrop so outside
/// taps reach *something*.
Widget _app(
  Widget child, {
  LegendThemeData data = const LegendThemeData(tokens: _tokens),
}) {
  return LegendTheme(
    data: data,
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

Widget _trigger() =>
    const SizedBox(width: 100, height: 40, child: Text('Open'));

/// The fill of the item row surface holding [label] — the row's
/// `AnimatedContainer` target decoration, so no animation wait is needed.
Color? _itemFill(WidgetTester tester, String label) {
  final container = tester.widget<AnimatedContainer>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return (container.decoration as BoxDecoration?)?.color;
}

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

/// A mouse pointer parked away from the menu, cleaned up on teardown.
Future<TestGesture> _mouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  return gesture;
}

void main() {
  group('open and close', () {
    testWidgets('tap opens; entries and divider render; tap again closes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(label: 'Rename', onSelected: () {}),
              const LegendMenuDivider(),
              LegendMenuItem(label: 'Delete', onSelected: () {}),
            ],
          ),
        ),
      );
      expect(find.text('Rename'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byType(LegendDivider), findsOneWidget);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
    });

    testWidgets('selecting an item fires onSelected and closes', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(label: 'Rename', onSelected: () => picked = 'r'),
              LegendMenuItem(label: 'Delete', onSelected: () => picked = 'd'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(picked, 'd');
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('outside tap dismisses', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [LegendMenuItem(label: 'Rename', onSelected: () {})],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
    });

    testWidgets('disabled menu: the trigger is inert', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            enabled: false,
            items: [LegendMenuItem(label: 'Rename', onSelected: () {})],
          ),
        ),
      );
      await tester.tap(find.text('Open'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
    });

    testWidgets('a controller opens and closes programmatically', (
      tester,
    ) async {
      final controller = LegendPopoverController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            controller: controller,
            items: [LegendMenuItem(label: 'Rename', onSelected: () {})],
          ),
        ),
      );
      controller.show();
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);
      expect(controller.isOpen, isTrue);

      controller.hide();
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
    });
  });

  group('keyboard', () {
    testWidgets('Escape closes and returns focus to the trigger', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [LegendMenuItem(label: 'Rename', onSelected: () {})],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
      final triggerNode = Focus.of(tester.element(find.text('Open')));
      expect(triggerNode.hasFocus, isTrue);
    });

    testWidgets('arrows move the highlight, wrapping at both ends', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(label: 'Rename', onSelected: () {}),
              LegendMenuItem(label: 'Delete', onSelected: () {}),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Nothing highlighted until the first arrow key.
      expect(_itemFill(tester, 'Rename'), const Color(0x00000000));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_itemFill(tester, 'Rename'), _tokens.colors.background2);
      expect(_itemFill(tester, 'Delete'), const Color(0x00000000));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_itemFill(tester, 'Delete'), _tokens.colors.background2);

      // Wraps bottom -> top.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_itemFill(tester, 'Rename'), _tokens.colors.background2);

      // And top -> bottom.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_itemFill(tester, 'Delete'), _tokens.colors.background2);
    });

    testWidgets('ArrowUp first enters the list from the bottom', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(label: 'Rename', onSelected: () {}),
              LegendMenuItem(label: 'Delete', onSelected: () {}),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_itemFill(tester, 'Delete'), _tokens.colors.background2);
    });

    testWidgets('Enter activates the highlighted item and closes', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(label: 'Rename', onSelected: () => picked = 'r'),
              LegendMenuItem(label: 'Delete', onSelected: () => picked = 'd'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, 'd');
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('Space activates like Enter', (tester) async {
      var selected = false;
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(
                label: 'Rename',
                onSelected: () => selected = true,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(selected, isTrue);
      expect(find.text('Rename'), findsNothing);
    });

    testWidgets('Enter with no highlight is a no-op that keeps the menu up', (
      tester,
    ) async {
      var selected = false;
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(
                label: 'Rename',
                onSelected: () => selected = true,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, isFalse);
      expect(find.text('Rename'), findsOneWidget);
    });

    testWidgets('navigation skips disabled items', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(label: 'Rename', onSelected: () {}),
              LegendMenuItem(
                label: 'Locked',
                onSelected: () {},
                enabled: false,
              ),
              LegendMenuItem(label: 'Delete', onSelected: () {}),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_itemFill(tester, 'Delete'), _tokens.colors.background2);
      expect(_itemFill(tester, 'Locked'), isNot(_tokens.colors.background2));
    });
  });

  group('items', () {
    testWidgets('hover highlights the row; keyboard continues from it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(label: 'Rename', onSelected: () {}),
              LegendMenuItem(label: 'Duplicate', onSelected: () {}),
              LegendMenuItem(label: 'Delete', onSelected: () {}),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final gesture = await _mouse(tester);
      await gesture.moveTo(tester.getCenter(find.text('Duplicate')));
      await tester.pumpAndSettle();
      expect(_itemFill(tester, 'Duplicate'), _tokens.colors.background2);

      // The hovered row seeded the highlight — ArrowDown moves past it.
      await gesture.moveTo(Offset.zero);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_itemFill(tester, 'Delete'), _tokens.colors.background2);
    });

    testWidgets('destructive item renders the label in the error color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(label: 'Rename', onSelected: () {}),
              LegendMenuItem(
                label: 'Delete',
                onSelected: () {},
                destructive: true,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(_labelColor(tester, 'Rename'), _tokens.colors.foreground1);
      expect(_labelColor(tester, 'Delete'), _tokens.colors.error);
    });

    testWidgets('disabled item: muted label, tap neither fires nor closes', (
      tester,
    ) async {
      var selected = false;
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(
                label: 'Locked',
                onSelected: () => selected = true,
                enabled: false,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(_labelColor(tester, 'Locked'), _tokens.colors.onDisabled);

      await tester.tap(find.text('Locked'));
      await tester.pumpAndSettle();
      expect(selected, isFalse);
      expect(find.text('Locked'), findsOneWidget);
    });

    testWidgets('icon renders before the label', (tester) async {
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(
                label: 'Rename',
                icon: const SizedBox(key: Key('icon'), width: 16, height: 16),
                onSelected: () {},
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('icon')), findsOneWidget);
      final icon = tester.getRect(find.byKey(const Key('icon')));
      final label = tester.getRect(find.text('Rename'));
      expect(icon.left, lessThan(label.left));
    });
  });

  group('semantics', () {
    testWidgets('items announce button semantics; disabled announces so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            semanticLabel: 'Actions',
            items: [
              LegendMenuItem(label: 'Rename', onSelected: () {}),
              LegendMenuItem(
                label: 'Locked',
                onSelected: () {},
                enabled: false,
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Actions')),
        containsSemantics(isButton: true),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // `.first` is the labeled LegendInteractive node; the row's Text
      // produces a second node with the same label.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Rename').first),
        containsSemantics(isButton: true, isEnabled: true),
      );
      // The inert row has no actions, so its Text merges into the labeled
      // node ("Locked\nLocked") — match by prefix.
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Locked')).first),
        containsSemantics(isButton: true, isEnabled: false),
      );
      handle.dispose();
    });
  });

  group('themed resolution', () {
    testWidgets('registry entry (level 3) retunes the destructive color', (
      tester,
    ) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _app(
          data: const LegendThemeData(
            tokens: _tokens,
            components: {
              LegendMenu: LegendMenuThemeNullable(destructiveColor: navy),
            },
          ),
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(
                label: 'Delete',
                onSelected: () {},
                destructive: true,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(_labelColor(tester, 'Delete'), navy);
    });

    testWidgets('constructor param (level 1) wins over the registry', (
      tester,
    ) async {
      const coral = Color(0xFFFF6F61);
      await tester.pumpWidget(
        _app(
          data: const LegendThemeData(
            tokens: _tokens,
            components: {
              LegendMenu: LegendMenuThemeNullable(
                destructiveColor: Color(0xFF001F54),
              ),
            },
          ),
          LegendMenu(
            trigger: _trigger(),
            destructiveColor: coral,
            items: [
              LegendMenuItem(
                label: 'Delete',
                onSelected: () {},
                destructive: true,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(_labelColor(tester, 'Delete'), coral);
    });

    testWidgets('subtree override (level 2) beats the registry', (
      tester,
    ) async {
      const teal = Color(0xFF0D9488);
      await tester.pumpWidget(
        _app(
          data: const LegendThemeData(
            tokens: _tokens,
            components: {
              LegendMenu: LegendMenuThemeNullable(
                destructiveColor: Color(0xFF001F54),
              ),
            },
          ),
          LegendMenuThemeOverride(
            data: const LegendMenuThemeNullable(destructiveColor: teal),
            child: LegendMenu(
              trigger: _trigger(),
              items: [
                LegendMenuItem(
                  label: 'Delete',
                  onSelected: () {},
                  destructive: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(_labelColor(tester, 'Delete'), teal);
    });
  });

  group('layout', () {
    testWidgets('the menu sizes to its widest item, not the overlay', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          LegendMenu(
            trigger: _trigger(),
            items: [
              LegendMenuItem(label: 'Short', onSelected: () {}),
              LegendMenuItem(
                label: 'A considerably longer action label',
                onSelected: () {},
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final screen = tester.getSize(find.byType(TapRegionSurface).first);
      final panel = tester.getRect(
        find
            .ancestor(
              of: find.text('Short'),
              matching: find.byType(LegendSurface),
            )
            .last,
      );
      // Narrower than the overlay: sized by IntrinsicWidth, not stretched
      // to the screen.
      expect(panel.width, lessThan(screen.width));
      // Both rows share the panel width.
      final short = tester.getRect(
        find
            .ancestor(
              of: find.text('Short'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final long = tester.getRect(
        find
            .ancestor(
              of: find.text('A considerably longer action label'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(short.width, long.width);
    });
  });
}
