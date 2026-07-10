import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

/// The app-level theme: tokens plus an **open, Type-keyed registry** of
/// component themes (DESIGN.md §2.3).
///
/// The registry is keyed by the *nullable* theme type a component's
/// generated code looks up (e.g. `PrimaryLegendButtonThemeNullable`).
/// Consumers register their own generated component themes in the same map
/// — there is no closed aggregate and no naming convention.
@immutable
class LegendThemeData {
  const LegendThemeData({required this.tokens, this.components = const {}});

  final LegendTokens tokens;
  final Map<Type, Object> components;

  /// Level-3 lookup for a component's sparse theme, or null if the app
  /// didn't register one.
  T? component<T>() => components[T] as T?;

  /// Level-3 lookup used by generated `XTheme.of` (RFC-002 R3): tries the
  /// **widget type** [widget] first — the key consumers naturally reach
  /// for — then falls back to `T` (the sparse theme type, the pre-RFC-002
  /// key) so existing registrations keep working. When both keys are
  /// registered, the widget-type entry wins.
  T? componentOf<T>(Type widget) {
    final value = components[widget] ?? components[T];
    assert(
      value is T?,
      'LegendThemeData.components[$widget] holds ${value.runtimeType}, '
      'expected $T — register the generated sparse theme type as the value.',
    );
    return value is T ? value : null;
  }

  LegendThemeData copyWith({
    LegendTokens? tokens,
    Map<Type, Object>? components,
  }) {
    return LegendThemeData(
      tokens: tokens ?? this.tokens,
      components: components ?? this.components,
    );
  }

  // Equality keeps updateShouldNotify honest: rebuilding an app that
  // reconstructs an identical LegendThemeData must not invalidate every
  // theme dependent (review I7). Tokens compare by identity — presets and
  // lerp outputs are either const or genuinely new objects.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendThemeData &&
          identical(other.tokens, tokens) &&
          mapEquals(other.components, components);

  @override
  int get hashCode => Object.hash(
    tokens,
    Object.hashAllUnordered(components.entries.map((e) => (e.key, e.value))),
  );
}

/// A rebuild aspect of [LegendTheme] (RFC-002 R12): a **comparator-carrying
/// const object**. [select] resolves one listened value — for a generated
/// component field, that field resolved through the registry and the token
/// defaults — from a [LegendThemeData]; a dependent registered with this
/// aspect rebuilds only when the selected value actually changes.
///
/// Design note (R12.1, aspect representation): the aspect carries the
/// comparator itself instead of a `(Type, field)` key because the
/// comparator answers "did this dependent's resolved value change"
/// directly inside [LegendTheme.updateShouldNotifyDependent] — no central
/// key table to generate (the registry stays open, rule 4), no generated
/// comparator lookup — and const tear-off construction canonicalizes equal
/// aspects, so `InheritedModel`'s per-dependent aspect set deduplicates
/// for free. Registry changes are type-scoped by construction: the
/// selector re-resolves through [LegendThemeData.componentOf], so an
/// unrelated component's registry entry never changes the selected value.
/// (the breakpoint aspect is an enum because its aspect set is closed;
/// theme aspects are open-ended — one per generated field, kit and
/// consumer alike.)
class LegendThemeAspect {
  /// Const so generated per-field aspects are canonicalized.
  const LegendThemeAspect(this.select);

  /// Resolves the listened value from the theme data; compared with `!=`
  /// between the old and new data.
  final Object? Function(LegendThemeData data) select;
}

/// Provides a [LegendThemeData] to the subtree — an [InheritedModel] over
/// [LegendThemeAspect]s (RFC-002 R12).
///
/// Dependents come in two flavors:
///
/// - **Aspect-less** ([of]/[maybeOf] — e.g. token readers like the docs
///   shell) keep classic whole-object behavior: any data change rebuilds
///   them.
/// - **Per-field** (generated `XTheme.of` via [read] + [depend]) rebuild
///   only when a listened field resolves differently — changing component
///   A's registry entry no longer rebuilds themed widget B.
class LegendTheme extends InheritedModel<LegendThemeAspect> {
  const LegendTheme({required this.data, required super.child, super.key});

  final LegendThemeData data;

  /// The nearest theme, registering a **whole-object** dependency: any
  /// [LegendThemeData] change rebuilds the caller. The right call for
  /// token consumers; generated resolvers use [read] + [depend] instead.
  static LegendThemeData of(BuildContext context) {
    final data = maybeOf(context);
    assert(data != null, 'No LegendTheme found in context.');
    return data!;
  }

  static LegendThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LegendTheme>()?.data;
  }

  /// The nearest theme **without registering any dependency** — the
  /// caller re-reads naturally on its next build but is never rebuilt by
  /// theme changes through this call. Generated resolvers read the data
  /// once, then register per-field aspects via [depend]; `listen: false`
  /// fields stop here (RFC-002 R12.2).
  static LegendThemeData read(BuildContext context) {
    final theme = context.getInheritedWidgetOfExactType<LegendTheme>();
    assert(theme != null, 'No LegendTheme found in context.');
    return theme!.data;
  }

  /// Registers [aspect] on the nearest theme (RFC-002 R12.1): the caller
  /// rebuilds only when `aspect.select` resolves differently against new
  /// data. Call once per listened field. Mixing with a whole-object [of]
  /// dependency in the same build conservatively keeps the whole-object
  /// behavior (the framework records the widest dependency).
  static LegendThemeData depend(
    BuildContext context,
    LegendThemeAspect aspect,
  ) {
    final theme = InheritedModel.inheritFrom<LegendTheme>(
      context,
      aspect: aspect,
    );
    assert(theme != null, 'No LegendTheme found in context.');
    return theme!.data;
  }

  @override
  bool updateShouldNotify(LegendTheme oldWidget) => data != oldWidget.data;

  @override
  bool updateShouldNotifyDependent(
    LegendTheme oldWidget,
    Set<LegendThemeAspect> dependencies,
  ) {
    for (final aspect in dependencies) {
      if (aspect.select(data) != aspect.select(oldWidget.data)) return true;
    }
    return false;
  }
}

/// A rebuild aspect of [LegendThemeOverride] (RFC-002 R12): selects one
/// member of the sparse override data `T`; the dependent rebuilds only
/// when that member changes. Same comparator-carrying design as
/// [LegendThemeAspect].
class LegendOverrideAspect<T extends Object> {
  /// Const so generated per-field aspects are canonicalized.
  const LegendOverrideAspect(this.select);

  /// Reads the listened member from the override data; compared with
  /// `!=` between the old and new data.
  final Object? Function(T data) select;
}

/// Level-2 subtree override, generic over the sparse theme type — an
/// [InheritedModel] over [LegendOverrideAspect]s (RFC-002 R12), with the
/// same two dependent flavors as [LegendTheme].
///
/// Generated code wraps this in a typed `XThemeOverride` widget for
/// ergonomics; both are public API.
class LegendThemeOverride<T extends Object>
    extends InheritedModel<LegendOverrideAspect<T>> {
  const LegendThemeOverride({
    required this.data,
    required super.child,
    super.key,
  });

  final T data;

  /// The nearest override of type `T`, registering a whole-object
  /// dependency; null when the subtree carries none.
  static T? maybeOf<T extends Object>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LegendThemeOverride<T>>()
        ?.data;
  }

  /// The nearest override of type `T` **without registering any
  /// dependency** (see [LegendTheme.read]).
  static T? read<T extends Object>(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<LegendThemeOverride<T>>()
        ?.data;
  }

  /// Registers [aspect] on the nearest override of type `T` (see
  /// [LegendTheme.depend]); null when the subtree carries none.
  static T? depend<T extends Object>(
    BuildContext context,
    LegendOverrideAspect<T> aspect,
  ) {
    return InheritedModel.inheritFrom<LegendThemeOverride<T>>(
      context,
      aspect: aspect,
    )?.data;
  }

  @override
  bool updateShouldNotify(LegendThemeOverride<T> oldWidget) =>
      data != oldWidget.data;

  @override
  bool updateShouldNotifyDependent(
    LegendThemeOverride<T> oldWidget,
    Set<LegendOverrideAspect<T>> dependencies,
  ) {
    for (final aspect in dependencies) {
      if (aspect.select(data) != aspect.select(oldWidget.data)) return true;
    }
    return false;
  }
}
