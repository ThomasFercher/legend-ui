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

/// Provides a [LegendThemeData] to the subtree.
class LegendTheme extends InheritedWidget {
  const LegendTheme({required this.data, required super.child, super.key});

  final LegendThemeData data;

  static LegendThemeData of(BuildContext context) {
    final data = maybeOf(context);
    assert(data != null, 'No LegendTheme found in context.');
    return data!;
  }

  static LegendThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LegendTheme>()?.data;
  }

  @override
  bool updateShouldNotify(LegendTheme oldWidget) => data != oldWidget.data;
}

/// Level-2 subtree override, generic over the sparse theme type.
///
/// Generated code wraps this in a typed `XThemeOverride` widget for
/// ergonomics; both are public API.
class LegendThemeOverride<T extends Object> extends InheritedWidget {
  const LegendThemeOverride({
    required this.data,
    required super.child,
    super.key,
  });

  final T data;

  static T? maybeOf<T extends Object>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LegendThemeOverride<T>>()
        ?.data;
  }

  @override
  bool updateShouldNotify(LegendThemeOverride<T> oldWidget) =>
      data != oldWidget.data;
}
