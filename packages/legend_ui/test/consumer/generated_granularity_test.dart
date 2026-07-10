// RFC-002 R12 — the GENERATED per-field wiring, exercised through the
// consumer probe fixtures (rebuild_probe.dart): aspects registered by
// XTheme.of, listen: false latching, per-field accessors, and the
// generated ValueListenable selectors. The aspect-core behavior itself is
// covered in ../granular_rebuilds_test.dart.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

import 'rebuild_probe.dart';

const _navy = Color(0xFF001F54);
const _red = Color(0xFFFF0000);

void main() {
  group('generated per-field rebuilds (RFC-002 R12)', () {
    testWidgets("(a) changing component A's registry entry does NOT "
        'rebuild themed widget B', (tester) async {
      final log = <String>[];
      // Stable instances: any rebuild can only come from a dependency.
      final tree = Column(
        textDirection: TextDirection.ltr,
        children: [
          SizedBox(
            height: 10,
            child: ProbeBox(onBuild: () => log.add('probe')),
          ),
          SizedBox(
            height: 10,
            child: OtherBox(onBuild: () => log.add('other')),
          ),
        ],
      );
      Future<void> pump(LegendThemeData data) =>
          tester.pumpWidget(LegendTheme(data: data, child: tree));

      await pump(const LegendThemeData(tokens: LegendTokens.light));
      log.clear();

      await pump(
        const LegendThemeData(
          tokens: LegendTokens.light,
          components: {OtherBox: OtherBoxThemeNullable(fill: _red)},
        ),
      );
      expect(log, ['other']);
    });

    testWidgets("(b) a listened field's resolved-value change rebuilds", (
      tester,
    ) async {
      var builds = 0;
      final probe = SizedBox(
        height: 10,
        child: ProbeBox(onBuild: () => builds++),
      );
      Future<void> pump(LegendThemeData data) =>
          tester.pumpWidget(LegendTheme(data: data, child: probe));

      await pump(const LegendThemeData(tokens: LegendTokens.light));
      builds = 0;
      await pump(
        const LegendThemeData(
          tokens: LegendTokens.light,
          components: {ProbeBox: ProbeBoxThemeNullable(tint: _navy)},
        ),
      );
      expect(builds, 1);
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(ProbeBox),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        _navy,
      );
    });

    testWidgets("(c) a listen: false field's change does not rebuild, but "
        'the next build reads the new value', (tester) async {
      var builds = 0;
      double paddingNow() =>
          (tester
                      .widget<Padding>(
                        find.descendant(
                          of: find.byType(ProbeBox),
                          matching: find.byType(Padding),
                        ),
                      )
                      .padding
                  as EdgeInsets)
              .top;

      final probe = SizedBox(
        height: 40,
        child: ProbeBox(onBuild: () => builds++),
      );
      Future<void> pump(LegendThemeData data, {Widget? child}) =>
          tester.pumpWidget(LegendTheme(data: data, child: child ?? probe));

      await pump(const LegendThemeData(tokens: LegendTokens.light));
      builds = 0;
      expect(paddingNow(), 8);

      // gap is listen: false — the registry change alone must not
      // schedule a rebuild, so the stale 8 stays on screen.
      const changed = LegendThemeData(
        tokens: LegendTokens.light,
        components: {ProbeBox: ProbeBoxThemeNullable(gap: 20)},
      );
      await pump(changed);
      expect(builds, 0);
      expect(paddingNow(), 8);

      // Any ordinary rebuild (here: a new widget instance) resolves the
      // fresh value.
      await pump(
        changed,
        child: SizedBox(height: 40, child: ProbeBox(onBuild: () => builds++)),
      );
      expect(builds, 1);
      expect(paddingNow(), 20);
    });

    testWidgets('(d) the per-field accessor registers only its own '
        "field's aspect", (tester) async {
      var builds = 0;
      final probe = SizedBox(
        height: 10,
        child: TintOnlyBox(onBuild: () => builds++),
      );
      Future<void> pump(LegendThemeData data) =>
          tester.pumpWidget(LegendTheme(data: data, child: probe));

      await pump(const LegendThemeData(tokens: LegendTokens.light));
      builds = 0;

      // gap changes (a LISTENED field of the widget, but not consumed by
      // its build, which reads only _tint(context)): no rebuild.
      await pump(
        const LegendThemeData(
          tokens: LegendTokens.light,
          components: {TintOnlyBox: TintOnlyBoxThemeNullable(gap: 32)},
        ),
      );
      expect(builds, 0);

      // tint changes: rebuild, and the accessor resolves level 3.
      await pump(
        const LegendThemeData(
          tokens: LegendTokens.light,
          components: {
            TintOnlyBox: TintOnlyBoxThemeNullable(gap: 32, tint: _navy),
          },
        ),
      );
      expect(builds, 1);
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(TintOnlyBox),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        _navy,
      );
    });

    test('(e) the generated listenable selector is distinct-until-changed', () {
      final source = ValueNotifier<int>(0);
      var data = const LegendThemeData(tokens: LegendTokens.light);
      final tint = ProbeBoxThemeListenables.tint(source, () => data);
      addTearDown(() => (tint as LegendThemeSelector<Color>).dispose());

      var notifications = 0;
      tint.addListener(() => notifications++);
      expect(tint.value, LegendTokens.light.colors.primary);

      // Unrelated registry change: silent.
      data = const LegendThemeData(
        tokens: LegendTokens.light,
        components: {OtherBox: OtherBoxThemeNullable(fill: _red)},
      );
      source.value++;
      expect(notifications, 0);

      // tint override: one notification, resolved through the registry.
      data = const LegendThemeData(
        tokens: LegendTokens.light,
        components: {ProbeBox: ProbeBoxThemeNullable(tint: _navy)},
      );
      source.value++;
      expect(notifications, 1);
      expect(tint.value, _navy);

      // Same value: still one.
      source.value++;
      expect(notifications, 1);
    });
  });
}
