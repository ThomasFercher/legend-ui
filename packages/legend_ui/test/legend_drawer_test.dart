import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

/// A [LegendApp] whose home is a button opening a drawer via
/// [LegendDrawer.show].
Widget _app({
  required LegendDrawerEdge edge,
  Widget content = const Text('Sheet content'),
  bool showHandle = true,
  Map<Type, Object> components = const {},
  void Function(Object?)? onResult,
}) {
  return LegendApp(
    theme: LegendThemeData(tokens: LegendTokens.light, components: components),
    home: Builder(
      builder: (context) => Center(
        child: PrimaryLegendButton(
          text: 'Open',
          onPressed: () async {
            final result = await LegendDrawer.show<Object?>(
              context,
              edge: edge,
              showHandle: showHandle,
              builder: (context) => content,
            );
            onResult?.call(result);
          },
        ),
      ),
    ),
  );
}

/// A bare shell (theme + [Directionality] + [Navigator]) for tests that
/// need an app-level text direction — [LegendApp]'s default localizations
/// pin LTR.
Widget _directionalShell({
  required TextDirection textDirection,
  required Widget home,
}) {
  return LegendTheme(
    data: const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: textDirection,
      child: Navigator(
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) => home,
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('LegendDrawer.show', () {
    testWidgets('start drawer opens, pops with a result', (tester) async {
      Object? result;
      await tester.pumpWidget(
        _app(
          edge: LegendDrawerEdge.start,
          onResult: (value) => result = value,
          content: Builder(
            builder: (context) => PrimaryLegendButton(
              text: 'Done',
              onPressed: () => Navigator.pop(context, 'saved'),
            ),
          ),
        ),
      );
      await _open(tester);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, 'saved');
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('scrim tap dismisses', (tester) async {
      await tester.pumpWidget(_app(edge: LegendDrawerEdge.start));
      await _open(tester);
      expect(find.text('Sheet content'), findsOneWidget);

      // The start drawer hugs the left edge — tap well outside it.
      await tester.tapAt(const Offset(700, 300));
      await tester.pumpAndSettle();
      expect(find.text('Sheet content'), findsNothing);
    });

    testWidgets('Escape dismisses', (tester) async {
      await tester.pumpWidget(_app(edge: LegendDrawerEdge.start));
      await _open(tester);
      expect(find.text('Sheet content'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Sheet content'), findsNothing);
    });

    testWidgets('start hugs the left edge in LTR, end the right', (
      tester,
    ) async {
      await tester.pumpWidget(_app(edge: LegendDrawerEdge.start));
      await _open(tester);
      final start = tester.getRect(find.byType(LegendDrawer));
      expect(start.left, 0);
      expect(start.width, 320); // annotation default
      expect(start.height, 600); // full height

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await tester.pumpWidget(_app(edge: LegendDrawerEdge.end));
      await _open(tester);
      expect(tester.getRect(find.byType(LegendDrawer)).right, 800);
    });

    testWidgets('start resolves against RTL (hugs the right edge)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _directionalShell(
          textDirection: TextDirection.rtl,
          home: Builder(
            builder: (context) => Center(
              child: PrimaryLegendButton(
                text: 'Open',
                onPressed: () => LegendDrawer.show<void>(
                  context,
                  builder: (context) => const Text('Sheet content'),
                ),
              ),
            ),
          ),
        ),
      );
      await _open(tester);
      expect(tester.getRect(find.byType(LegendDrawer)).right, 800);
    });

    testWidgets('bottom drawer spans the width and shows the handle', (
      tester,
    ) async {
      await tester.pumpWidget(_app(edge: LegendDrawerEdge.bottom));
      await _open(tester);

      final rect = tester.getRect(find.byType(LegendDrawer));
      expect(rect.width, 800);
      expect(rect.bottom, 600);
      expect(_findHandle(), findsOneWidget);
    });

    testWidgets('showHandle: false hides the handle', (tester) async {
      await tester.pumpWidget(
        _app(edge: LegendDrawerEdge.bottom, showHandle: false),
      );
      await _open(tester);
      expect(_findHandle(), findsNothing);
    });
  });

  group('LegendDrawer drag-to-dismiss (bottom)', () {
    testWidgets('dragging past a third of the height dismisses', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          edge: LegendDrawerEdge.bottom,
          content: const SizedBox(height: 300, child: Text('Sheet content')),
        ),
      );
      await _open(tester);

      await tester.drag(find.text('Sheet content'), const Offset(0, 250));
      await tester.pumpAndSettle();
      expect(find.text('Sheet content'), findsNothing);
    });

    testWidgets('a short drag springs back instead of dismissing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          edge: LegendDrawerEdge.bottom,
          content: const SizedBox(height: 300, child: Text('Sheet content')),
        ),
      );
      await _open(tester);
      final restingTop = tester.getRect(find.byType(LegendDrawer)).top;

      // Slow and short: below both the distance and fling thresholds.
      await tester.timedDrag(
        find.text('Sheet content'),
        const Offset(0, 40),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sheet content'), findsOneWidget);
      expect(tester.getRect(find.byType(LegendDrawer)).top, restingTop);
    });

    testWidgets('upward drags never move the sheet', (tester) async {
      await tester.pumpWidget(
        _app(
          edge: LegendDrawerEdge.bottom,
          content: const SizedBox(height: 300, child: Text('Sheet content')),
        ),
      );
      await _open(tester);
      final restingTop = tester.getRect(find.byType(LegendDrawer)).top;

      await tester.timedDrag(
        find.text('Sheet content'),
        const Offset(0, -80),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(LegendDrawer)).top, restingTop);
    });
  });

  group('LegendDrawer theming', () {
    testWidgets('level-3 registry override restyles the width', (tester) async {
      await tester.pumpWidget(
        _app(
          edge: LegendDrawerEdge.start,
          components: const {
            LegendDrawer: LegendDrawerThemeNullable(width: 260),
          },
        ),
      );
      await _open(tester);
      expect(tester.getRect(find.byType(LegendDrawer)).width, 260);
    });

    testWidgets('constructor param wins over the registry', (tester) async {
      await tester.pumpWidget(
        const LegendApp(
          theme: LegendThemeData(
            tokens: LegendTokens.light,
            components: {LegendDrawer: LegendDrawerThemeNullable(width: 260)},
          ),
          home: Align(
            alignment: Alignment.centerLeft,
            child: LegendDrawer(width: 200, child: Text('Inline')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(LegendDrawer)).width, 200);
    });

    testWidgets('bottom corner radius and handle color follow the tokens', (
      tester,
    ) async {
      await tester.pumpWidget(_app(edge: LegendDrawerEdge.bottom));
      await _open(tester);

      final surface = tester.widget<LegendSurface>(
        find.descendant(
          of: find.byType(LegendDrawer),
          matching: find.byType(LegendSurface),
        ),
      );
      const tokens = LegendTokens.light;
      expect(
        surface.borderRadius,
        BorderRadius.vertical(top: Radius.circular(tokens.sizes.radiusLg)),
      );
      expect(surface.color, tokens.colors.surface);

      final handle = tester.widget<DecoratedBox>(
        find
            .ancestor(of: _findHandle(), matching: find.byType(DecoratedBox))
            .first,
      );
      expect(
        (handle.decoration as BoxDecoration).color,
        tokens.colors.background3,
      );
    });
  });
}

Finder _findHandle() => find.byWidgetPredicate(
  (widget) => widget is SizedBox && widget.width == 36 && widget.height == 4,
);
