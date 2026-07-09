import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

final _probe = GlobalKey();

/// Minimal app shell for toasts: theme + a root [Overlay] whose base
/// entry exposes a context ([_probe]) to call [showNomoToast] with.
Widget _overlayApp() {
  return NomoTheme(
    data: const NomoThemeData(tokens: NomoTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => Center(child: SizedBox(key: _probe)),
          ),
        ],
      ),
    ),
  );
}

Widget _wrap(Widget child) {
  return NomoTheme(
    data: const NomoThemeData(tokens: NomoTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

void main() {
  group('showNomoToast', () {
    testWidgets('appears with its action and auto-dismisses', (tester) async {
      await tester.pumpWidget(_overlayApp());
      final context = tester.element(find.byKey(_probe));

      showNomoToast(
        context,
        'Saved',
        duration: const Duration(seconds: 1),
        action: const Text('UNDO'),
      );
      await tester.pump(); // entry inserted, slide/fade starts
      await tester.pump(const Duration(milliseconds: 250)); // fully in
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1)); // timer → dismiss
      await tester.pump(const Duration(milliseconds: 250)); // fully out
      await tester.pump(); // entry removed
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('queues overlapping calls FIFO, one at a time', (tester) async {
      await tester.pumpWidget(_overlayApp());
      final context = tester.element(find.byKey(_probe));
      const duration = Duration(milliseconds: 500);

      showNomoToast(context, 'first', duration: duration);
      showNomoToast(context, 'second', duration: duration);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Strictly one toast at a time, in call order.
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500)); // first out
      await tester.pump(const Duration(milliseconds: 250)); // second in
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500)); // second out
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(find.text('second'), findsNothing);
    });

    testWidgets('survives tree teardown mid-toast and recovers', (
      tester,
    ) async {
      await tester.pumpWidget(_overlayApp());
      final context = tester.element(find.byKey(_probe));

      showNomoToast(context, 'doomed', duration: const Duration(seconds: 30));
      showNomoToast(context, 'stale', duration: const Duration(seconds: 30));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('doomed'), findsOneWidget);

      // Tear the whole app down while the toast is holding: its ticker
      // and auto-dismiss timer must be disposed with it (this test fails
      // on leaked tickers / pending timers), and the queue must unjam.
      await tester.pumpWidget(const SizedBox());
      expect(find.text('doomed'), findsNothing);

      // A fresh tree shows fresh toasts; the queued request whose overlay
      // died ('stale') is dropped, not shown on the dead overlay.
      await tester.pumpWidget(_overlayApp());
      final fresh = tester.element(find.byKey(_probe));
      showNomoToast(
        fresh,
        'revived',
        duration: const Duration(milliseconds: 500),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('stale'), findsNothing);
      expect(find.text('revived'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(find.text('revived'), findsNothing);
    });
  });

  group('NomoToast severity accent', () {
    Finder accent(Color color) => find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == color,
    );

    testWidgets('info (default) uses the primary token', (tester) async {
      await tester.pumpWidget(_wrap(const NomoToast(message: 'i')));
      expect(accent(NomoTokens.light.colors.primary), findsOneWidget);
    });

    testWidgets('success uses the secondary token', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const NomoToast(message: 's', severity: NomoToastSeverity.success),
        ),
      );
      expect(accent(NomoTokens.light.colors.secondary), findsOneWidget);
    });

    testWidgets('error uses the error token', (tester) async {
      await tester.pumpWidget(
        _wrap(const NomoToast(message: 'e', severity: NomoToastSeverity.error)),
      );
      expect(accent(NomoTokens.light.colors.error), findsOneWidget);
    });
  });

  group('NomoLoading', () {
    testWidgets('renders an animating arc painter at the themed size', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const NomoLoading()));
      final paint = find.descendant(
        of: find.byType(NomoLoading),
        matching: find.byType(CustomPaint),
      );
      expect(paint, findsOneWidget);
      expect(tester.getSize(paint), const Size(24, 24));

      final before = tester.widget<CustomPaint>(paint).painter;
      expect(before, isNotNull);

      await tester.pump(const Duration(milliseconds: 300));
      final after = tester.widget<CustomPaint>(paint).painter;
      expect(after, isNotNull);
      expect(identical(after, before), isFalse);
      expect(after!.shouldRepaint(before!), isTrue);

      // The controller repeats forever: unmounting must dispose its
      // ticker (this test fails on leaked tickers otherwise).
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('constructor size wins over the themed default', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const NomoLoading(size: 40)));
      final paint = find.descendant(
        of: find.byType(NomoLoading),
        matching: find.byType(CustomPaint),
      );
      expect(tester.getSize(paint), const Size(40, 40));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('NomoShimmer', () {
    testWidgets('sweeps a shader over its child', (tester) async {
      await tester.pumpWidget(
        _wrap(const NomoShimmer(child: Text('skeleton'))),
      );
      expect(find.text('skeleton'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NomoShimmer),
          matching: find.byType(ShaderMask),
        ),
        findsOneWidget,
      );
      // Loops without error while mounted.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('box constructor renders a sized placeholder', (tester) async {
      await tester.pumpWidget(
        _wrap(const NomoShimmer.box(width: 80, height: 20)),
      );
      expect(tester.getSize(find.byType(NomoShimmer)), const Size(80, 20));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
