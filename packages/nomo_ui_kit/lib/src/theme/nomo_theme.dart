import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/tokens/nomo_tokens.dart';

/// The app-level theme: tokens plus an **open, Type-keyed registry** of
/// component themes (DESIGN.md §2.3).
///
/// The registry is keyed by the *nullable* theme type a component's
/// generated code looks up (e.g. `PrimaryNomoButtonThemeNullable`).
/// Consumers register their own generated component themes in the same map
/// — there is no closed aggregate and no naming convention.
class NomoThemeData {
  const NomoThemeData({required this.tokens, this.components = const {}});

  final NomoTokens tokens;
  final Map<Type, Object> components;

  /// Level-3 lookup for a component's sparse theme, or null if the app
  /// didn't register one.
  T? component<T>() => components[T] as T?;

  NomoThemeData copyWith({NomoTokens? tokens, Map<Type, Object>? components}) {
    return NomoThemeData(
      tokens: tokens ?? this.tokens,
      components: components ?? this.components,
    );
  }
}

/// Provides a [NomoThemeData] to the subtree.
class NomoTheme extends InheritedWidget {
  const NomoTheme({required this.data, required super.child, super.key});

  final NomoThemeData data;

  static NomoThemeData of(BuildContext context) {
    final data = maybeOf(context);
    assert(data != null, 'No NomoTheme found in context.');
    return data!;
  }

  static NomoThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NomoTheme>()?.data;
  }

  @override
  bool updateShouldNotify(NomoTheme oldWidget) => data != oldWidget.data;
}

/// Level-2 subtree override, generic over the sparse theme type.
///
/// Generated code wraps this in a typed `XThemeOverride` widget for
/// ergonomics; both are public API.
class NomoThemeOverride<T extends Object> extends InheritedWidget {
  const NomoThemeOverride({
    required this.data,
    required super.child,
    super.key,
  });

  final T data;

  static T? maybeOf<T extends Object>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NomoThemeOverride<T>>()
        ?.data;
  }

  @override
  bool updateShouldNotify(NomoThemeOverride<T> oldWidget) =>
      data != oldWidget.data;
}
