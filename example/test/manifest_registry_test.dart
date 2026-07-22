import 'dart:io';

import 'package:example/docs/manifest_registry.dart';
import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Color? _surfaceColorOf(WidgetTester tester, String text) {
  final surface = tester.widget<LegendSurface>(
    find
        .ancestor(of: find.text(text), matching: find.byType(LegendSurface))
        .first,
  );
  return surface.color;
}

void main() {
  test('registry covers every shipped docs manifest (and nothing else)', () {
    // The kit commits one *.docs.g.dart per @LegendThemeable declaration
    // (RFC-002 R9). Scan them so a widget landing without a registry row
    // fails here loudly. InteractiveColors is the @Style value class, not
    // a widget — it feeds styleClassConstructors instead.
    final kitLib = Directory('../packages/legend_ui/lib');
    final owners = <String>{};
    for (final file in kitLib.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.docs.g.dart')) continue;
      final owner = RegExp(
        "owner: '([^']+)'",
      ).firstMatch(file.readAsStringSync());
      if (owner != null) owners.add(owner.group(1)!);
    }
    owners.remove('InteractiveColors');
    expect(owners, isNotEmpty, reason: 'manifest scan found nothing');

    final registered = playgroundComponents.map((c) => c.name).toSet();
    expect(
      registered.length,
      playgroundComponents.length,
      reason: 'duplicate registry rows',
    );
    expect(
      owners.difference(registered),
      isEmpty,
      reason: 'shipped manifests missing a theme-explorer registry row',
    );
    expect(
      registered.difference(owners),
      isEmpty,
      reason: 'registry rows without a shipped manifest',
    );
  });

  test('compileOverride builds sparse XThemeNullable values by name', () {
    final button = playgroundComponentByType[PrimaryLegendButton]!;

    // Nothing set: no override registers at all.
    expect(compileOverride(button, const {}), isNull);
    expect(compileOverride(button, const {'textStyle': null}), isNull);

    // A plain member becomes a named constructor argument.
    const style = TextStyle(fontSize: 18);
    expect(
      compileOverride(button, const {'textStyle': style}),
      const PrimaryLegendButtonThemeNullable(textStyle: style),
    );

    // Dot-path members group into their @Style value class — a sparse
    // InteractiveColors whose unset states keep deriving (RFC-002 R6).
    expect(
      compileOverride(button, const {
        'background.hovered': Color(0xFF8B5CF6),
      }),
      const PrimaryLegendButtonThemeNullable(
        background: InteractiveColors(hovered: Color(0xFF8B5CF6)),
      ),
    );
  });

  test('overrideSource renders the copy-pasteable sparse override', () {
    final button = playgroundComponentByType[PrimaryLegendButton]!;
    final source = overrideSource(button, const {
      'background.normal': Color(0xFFDC2626),
      'textStyle': TextStyle(fontSize: 18),
    });
    expect(source, contains('PrimaryLegendButtonThemeNullable('));
    expect(source, contains('textStyle: TextStyle(fontSize: 18'));
    expect(
      source,
      contains('background: InteractiveColors(normal: Color(0xFFDC2626))'),
    );
  });

  testWidgets('theme explorer: pick a component, edit a color, and the '
      'live preview restyles', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> settleTheme() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    await tester.tap(find.text('Explorer'));
    await settleTheme();
    expect(find.text('Theme explorer'), findsOneWidget);

    // The search box narrows the picker to the queried component.
    await tester.enterText(find.byType(LegendTextField).first, 'badge');
    await settleTheme();
    expect(find.text('LegendBadge'), findsOneWidget);
    expect(find.text('LegendAccordion'), findsNothing);

    // Pick it; its manifest-driven editors and live preview render.
    await tester.tap(find.text('LegendBadge'));
    await settleTheme();
    expect(find.text('Mainnet'), findsOneWidget);

    // Edit the `background` Color entry through its swatch row: the
    // override registers as a sparse LegendBadgeThemeNullable (level 3)
    // and the live badge picks it up.
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('background #2563EB'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.bySemanticsLabel('background #2563EB'));
    await settleTheme();
    await tester.tap(find.bySemanticsLabel('background #2563EB'));
    await settleTheme();
    expect(_surfaceColorOf(tester, 'Mainnet'), const Color(0xFF2563EB));

    // The emitted-code block shows exactly what the edit registered.
    expect(
      find.textContaining('LegendBadgeThemeNullable('),
      findsOneWidget,
    );

    // Clearing the component's overrides falls back down the ladder.
    await tester.scrollUntilVisible(
      find.text('Clear LegendBadge overrides'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Clear LegendBadge overrides'));
    await settleTheme();
    await tester.tap(find.text('Clear LegendBadge overrides'));
    await settleTheme();
    expect(find.textContaining('LegendBadgeThemeNullable('), findsNothing);
    expect(
      _surfaceColorOf(tester, 'Mainnet'),
      isNot(const Color(0xFF2563EB)),
    );
  });

  testWidgets('theme explorer: a dot-path member compiles into a sparse '
      'InteractiveColors override', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> settleTheme() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pumpWidget(const DocsApp());
    await settleTheme();
    await tester.tap(find.text('Explorer'));
    await settleTheme();

    await tester.enterText(find.byType(LegendTextField).first, 'primary');
    await settleTheme();
    await tester.tap(find.text('PrimaryLegendButton'));
    await settleTheme();

    // Edit background.normal through the grouped member editor.
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('background.normal #DC2626'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.bySemanticsLabel('background.normal #DC2626'),
    );
    await settleTheme();
    await tester.tap(find.bySemanticsLabel('background.normal #DC2626'));
    await settleTheme();

    // The live preview button repaints; the unset states keep deriving.
    expect(_surfaceColorOf(tester, 'Primary'), const Color(0xFFDC2626));
    expect(
      find.textContaining(
        'background: InteractiveColors(normal: Color(0xFFDC2626))',
      ),
      findsOneWidget,
    );
  });
}
