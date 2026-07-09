import 'package:meta/meta_meta.dart';

/// Marks a widget as themable — `legend_gen themes` generates its theme
/// plumbing (`XTheme`, `XThemeNullable`, `XThemeOverride`, `XTheme.of`).
///
/// Contract (enforced by the generator, DESIGN.md §2.2):
/// - every `@Themed` field must be nullable,
/// - every `@Themed` constructor parameter must default to `null`.
@Target({TargetKind.classType})
class LegendThemeable {
  const LegendThemeable();
}

/// Marks a field of a [LegendThemeable] widget as a themed property.
@Target({TargetKind.field})
class Themed {
  const Themed({required this.defaultsTo, this.lerp = false});

  /// A Dart expression over `t` (a `LegendTokens` instance), evaluated in the
  /// generated `defaults(LegendTokens t)` factory — e.g. `'t.colors.primary'`
  /// or `'EdgeInsets.all(t.sizes.md)'`.
  ///
  /// The expression is pasted into generated code, so the analyzer validates
  /// it there: a typo fails `flutter analyze`, not silently at runtime
  /// (decision note in DESIGN.md §9.2).
  final String defaultsTo;

  /// Whether `XTheme.lerp` interpolates this field (opt-in; most fields
  /// step, since theme switches lerp tokens instead — DESIGN.md §2.4).
  final bool lerp;
}
