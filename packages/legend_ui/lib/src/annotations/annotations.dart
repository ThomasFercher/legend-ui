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

/// Marks a token data class for `legend_gen tokens` (RFC-002 R5): the
/// mechanical members — `copyWith` and value `==`/`hashCode` as a
/// `_$ClassName` mixin the class applies via `with`, plus the private
/// member-wise lerp function the class's one-line `static lerp` redirects
/// to — are generated into a `<file>.tokens.g.dart` part.
///
/// With [mountedAt] set, the generator additionally emits a **const
/// tear-off catalog** `<ClassName>Ref` into the same part: one static
/// `FieldType field(LegendTokens t) => t.<mountedAt>.<field>;` per token
/// field, usable directly inside `@Style<T>.resolve` annotations
/// (RFC-002 R10 amendment) — the common one-hop token default without an
/// adjacent hand-written tear-off.
///
/// Explicitly NOT [LegendThemeable]: token classes are the base theme
/// (DESIGN.md §2.1) and never get Override widgets, registry entries, or
/// `of()` resolvers (RFC-002 R10 scope). There is no per-field opt-out:
/// every field lerps with its type-appropriate lerper (none of the kit's
/// token fields needs to step).
///
/// Contract (enforced by the generator):
/// - every instance field is `final`, explicitly typed and non-nullable,
/// - the unnamed constructor accepts every field as a named parameter,
/// - list fields are `List<BoxShadow>` (the one lerpable list),
/// - the class applies the generated mixin (`with _$ClassName`),
/// - the file carries `part '<file>.tokens.g.dart';`,
/// - with [mountedAt], the file imports `legend_tokens.dart` (the Ref
///   catalog's parameter type; an in-package circular import is fine).
@Target({TargetKind.classType})
class LegendTokenData {
  const LegendTokenData({this.mountedAt, this.refName});

  /// The [LegendTokens] getter this class sits behind — `'colors'`,
  /// `'sizes'`, `'typography'`, `'shadows'`, or `'states'` for the kit's
  /// own classes. An explicit declaration, never a naming convention.
  ///
  /// The empty string is the **root sentinel**: the class IS
  /// [LegendTokens], and its Ref catalog reads fields directly
  /// (`static LegendColors colors(LegendTokens t) => t.colors;`), closing
  /// the catalog over the whole base theme.
  ///
  /// Null (the default) skips the Ref catalog — for nested groups a
  /// consumer never styles against.
  final String? mountedAt;

  /// The name of the emitted Ref catalog class. Null (the default) uses
  /// `<ClassName>Ref`; an explicit name overrides it — the kit sets short
  /// names (`ColorRef`, `SizeRef`, `TextRef`, `ShadowRef`, `StateRef`,
  /// `TokenRef`) because annotation ubiquity earns terseness (a
  /// **documented exception** to the Legend-prefix rule; still an explicit
  /// declaration, never a naming convention). Ignored without [mountedAt].
  final String? refName;
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
///   ordinary symbol. Two tear-off shapes (Dart's const rules allow
///   exactly these):
///   - a **Ref catalog member** for the common one-hop token read —
///     `@Style<double>.resolve(SizeRef.md)`; the catalogs are
///     generated from the token classes ([LegendTokenData.mountedAt]),
///     so no adjacent hand-written static is needed;
///   - a **private top-level function** (or a static method) in the
///     widget's file for composite defaults —
///     `EdgeInsetsGeometry _padding(LegendTokens t) =>
///     EdgeInsets.all(t.sizes.md);` — the generated artifact is
///     `part of` the widget's library, so private symbols resolve.
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
