// RFC-002 R12 — granular rebuilds: the aspect-aware LegendTheme /
// LegendThemeOverride core and the distinct-until-changed selector.
// The generated per-field wiring (aspects registered by XTheme.of,
// listen: false, per-field accessors) is covered in
// generated_granularity_test.dart.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _red = Color(0xFFFF0000);
const _green = Color(0xFF00FF00);
const _blue = Color(0xFF0000FF);

/// Selects the LegendSwitch registry entry — a stand-in for a generated
/// per-field resolver (registry + defaults).
Object? _selectSwitchEntry(LegendThemeData data) =>
    data.componentOf<InteractiveColors>(LegendSwitch);

Object? _selectPrimary(LegendThemeData data) => data.tokens.colors.primary;

const _switchAspect = LegendThemeAspect(_selectSwitchEntry);
const _primaryAspect = LegendThemeAspect(_selectPrimary);

class _Probe extends StatefulWidget {
  const _Probe({required this.onBuild, this.aspect, this.readOnly = false});

  final VoidCallback onBuild;

  /// Null with [readOnly] false: whole-object dependency (LegendTheme.of).
  final LegendThemeAspect? aspect;

  /// True: LegendTheme.read — no dependency at all.
  final bool readOnly;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    final aspect = widget.aspect;
    if (widget.readOnly) {
      LegendTheme.read(context);
    } else if (aspect != null) {
      LegendTheme.depend(context, aspect);
    } else {
      LegendTheme.of(context);
    }
    return const SizedBox();
  }
}

void main() {
  group('LegendTheme aspects (RFC-002 R12 core)', () {
    Future<
      ({Future<void> Function(LegendThemeData) pump, List<String> buildLog})
    >
    pumpProbes(WidgetTester tester) async {
      final buildLog = <String>[];
      // The probe subtree is ONE stable widget instance reused across
      // pumps — identical child widgets short-circuit the element update,
      // so any probe rebuild can only come from a dependency
      // notification.
      final probes = Column(
        textDirection: TextDirection.ltr,
        children: [
          _Probe(
            aspect: _switchAspect,
            onBuild: () => buildLog.add('switch-entry'),
          ),
          _Probe(
            aspect: _primaryAspect,
            onBuild: () => buildLog.add('primary'),
          ),
          _Probe(onBuild: () => buildLog.add('whole')),
          _Probe(readOnly: true, onBuild: () => buildLog.add('read')),
        ],
      );
      Future<void> pump(LegendThemeData data) {
        return tester.pumpWidget(LegendTheme(data: data, child: probes));
      }

      await pump(const LegendThemeData(tokens: LegendTokens.light));
      buildLog.clear();
      return (pump: pump, buildLog: buildLog);
    }

    testWidgets('a registry change for one widget type rebuilds only its '
        'dependents — not other aspects (audit regression)', (tester) async {
      final harness = await pumpProbes(tester);
      // Register an override for LegendSwitch: the switch-entry dependent
      // and the whole-object dependent rebuild; the primary-color
      // dependent and the read-only probe must NOT.
      await harness.pump(
        const LegendThemeData(
          tokens: LegendTokens.light,
          components: {LegendSwitch: InteractiveColors(normal: _red)},
        ),
      );
      expect(harness.buildLog, unorderedEquals(['switch-entry', 'whole']));
    });

    testWidgets('a token change rebuilds only aspects whose selected value '
        'differs', (tester) async {
      final harness = await pumpProbes(tester);
      final restyled = LegendTokens.light.copyWith(
        colors: LegendTokens.light.colors.copyWith(primary: _green),
      );
      await harness.pump(LegendThemeData(tokens: restyled));
      expect(harness.buildLog, unorderedEquals(['primary', 'whole']));
    });

    testWidgets('read registers no dependency but re-reads fresh on the '
        'next build', (tester) async {
      final harness = await pumpProbes(tester);
      await harness.pump(
        const LegendThemeData(
          tokens: LegendTokens.light,
          components: {LegendSwitch: InteractiveColors(normal: _red)},
        ),
      );
      expect(harness.buildLog, isNot(contains('read')));
    });

    testWidgets('identical data notifies nobody', (tester) async {
      final harness = await pumpProbes(tester);
      await harness.pump(const LegendThemeData(tokens: LegendTokens.light));
      expect(harness.buildLog, isEmpty);
    });
  });

  group('LegendThemeOverride aspects (RFC-002 R12 core)', () {
    testWidgets('dependents rebuild only when their selected member '
        'changes', (tester) async {
      final log = <String>[];
      final probe = Builder(
        builder: (context) {
          log.add('built');
          LegendThemeOverride.depend<InteractiveColors>(
            context,
            const LegendOverrideAspect(_selectNormal),
          );
          return const SizedBox();
        },
      );
      Future<void> pump(InteractiveColors data) {
        return tester.pumpWidget(
          LegendTheme(
            data: const LegendThemeData(tokens: LegendTokens.light),
            child: LegendThemeOverride<InteractiveColors>(
              data: data,
              child: probe,
            ),
          ),
        );
      }

      await pump(const InteractiveColors(normal: _red));
      log.clear();
      // Same selected member, different other member: no rebuild.
      await pump(const InteractiveColors(normal: _red, hovered: _blue));
      expect(log, isEmpty);
      // Selected member changes: rebuild.
      await pump(const InteractiveColors(normal: _green, hovered: _blue));
      expect(log, ['built']);
    });
  });

  group('LegendThemeSelector (RFC-002 R12.4)', () {
    test('notifies distinct-until-changed', () {
      final source = ChangeNotifier();
      var data = const LegendThemeData(tokens: LegendTokens.light);
      final selector = LegendThemeSelector<Color>(
        source,
        () => data,
        (d) => d.tokens.colors.primary,
      );
      addTearDown(selector.dispose);

      var notifications = 0;
      selector.addListener(() => notifications++);
      expect(selector.value, LegendTokens.light.colors.primary);

      // Unrelated change: no notification.
      data = const LegendThemeData(
        tokens: LegendTokens.light,
        components: {LegendSwitch: InteractiveColors(normal: _red)},
      );
      source.notify();
      expect(notifications, 0);

      // Selected value changes: exactly one notification.
      data = LegendThemeData(
        tokens: LegendTokens.light.copyWith(
          colors: LegendTokens.light.colors.copyWith(primary: _green),
        ),
      );
      source.notify();
      expect(notifications, 1);
      expect(selector.value, _green);

      // Same value again: still one.
      source.notify();
      expect(notifications, 1);
    });

    test('dispose detaches from the source', () {
      final source = ChangeNotifier();
      var data = const LegendThemeData(tokens: LegendTokens.light);
      final selector = LegendThemeSelector<Color>(
        source,
        () => data,
        (d) => d.tokens.colors.primary,
      );
      var notifications = 0;
      selector
        ..addListener(() => notifications++)
        ..dispose();
      data = LegendThemeData(
        tokens: LegendTokens.light.copyWith(
          colors: LegendTokens.light.colors.copyWith(primary: _green),
        ),
      );
      source.notify();
      expect(notifications, 0);
    });
  });
}

Object? _selectNormal(InteractiveColors data) => data.normal;

extension on ChangeNotifier {
  void notify() {
    // Tests drive the source notifier directly — there is no subclass.
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    notifyListeners();
  }
}
