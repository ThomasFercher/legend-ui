import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:meta/meta_meta.dart';

/// Marks a widget as themable — `legend_gen themes` generates its theme
/// plumbing (`XTheme`, `XThemeNullable`, `XThemeOverride`, `XTheme.of`,
/// and the private in-library `_theme(BuildContext)` resolver) into a
/// `part` file of the widget's library.
///
/// Contract (enforced by the generator, DESIGN.md §2.2 + RFC-002):
/// - every `@Style` field must be nullable,
/// - every `@Style` constructor parameter must default to `null`,
/// - the widget file carries a `part '<widget>.theme.g.dart';` directive.
@Target({TargetKind.classType})
class LegendThemeable {
  const LegendThemeable();
}

/// Marks a field of a [LegendThemeable] widget as a themed property and
/// carries its **typed** default (RFC-002 R10) — the annotation exists for
/// exactly one thing: generating the theme boilerplate. Applies to
/// component themes only, never to token classes.
///
/// Three default forms:
///
/// - `@Style<T>(value)` — a const value used when no theme level provides
///   anything ("the value without theme"). Overridden by any theme
///   override at any level; untouched four-level semantics.
/// - `@Style<T>.resolve(tearOff)` — the author defines the relation to the
///   static theme values as a const tear-off `T Function(LegendTokens)`,
///   compile-checked in the widget file itself and shareable as an
///   ordinary symbol. Tear-offs may be private statics — the generated
///   artifact is `part of` the widget's library.
/// - `@Style<T>(null)` — no default: the component treats the value as
///   genuinely optional and the resolved theme field stays nullable.
///
/// The generic type argument is required and must match the field's
/// declared (non-null) type; the generator validates it from the AST.
@Target({TargetKind.field})
class Style<T> {
  /// A const default value (or `null` for "genuinely optional").
  const Style(this.value, {this.lerp = false}) : resolve = null;

  /// An author-defined relation to the tokens: a const tear-off
  /// `T Function(LegendTokens)`, evaluated by the generated
  /// `XTheme.defaults(LegendTokens t)`.
  const Style.resolve(this.resolve, {this.lerp = false}) : value = null;

  /// The typed const default ("without theme"), for the value form.
  final T? value;

  /// The typed default's relation to [LegendTokens], for the resolve form.
  final T Function(LegendTokens tokens)? resolve;

  /// Whether `XTheme.lerp` interpolates this field (opt-in; most fields
  /// step, since theme switches lerp tokens instead — DESIGN.md §2.4).
  final bool lerp;
}
