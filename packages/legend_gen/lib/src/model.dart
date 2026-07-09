/// How a `@Style<T>` field's default is declared (RFC-002 R10).
enum StyleDefaultKind {
  /// `@Style<T>(constValue)` — a typed const default ("without theme").
  value,

  /// `@Style<T>.resolve(tearOff)` — an author-defined relation to
  /// `LegendTokens`, called by the generated `defaults(LegendTokens t)`.
  resolve,

  /// `@Style<T>(null)` — no default: the value is genuinely optional and
  /// the resolved theme field stays nullable.
  none,
}

/// A `@Style<T>` field parsed from a `@LegendThemeable` widget.
class StyledField {
  const StyledField({
    required this.name,
    required this.type,
    required this.kind,
    required this.defaultCode,
    required this.defaultDescription,
    required this.lerp,
    this.doc = '',
  });

  /// Field name, e.g. `background`.
  final String name;

  /// Declared (nullable) type source, e.g. `Color?`.
  final String type;

  /// Non-null type, e.g. `Color`.
  String get resolvedType =>
      type.endsWith('?') ? type.substring(0, type.length - 1) : type;

  /// The type of the resolved `XTheme` field: non-null when the field has
  /// a default, the declared nullable type when it is genuinely optional.
  String get themeType => kind == StyleDefaultKind.none ? type : resolvedType;

  /// Whether this is a `LegendStates<X>` field (RFC-002 R6): the emitter
  /// merges it member-wise sparse and lerps member-wise instead of
  /// whole-value.
  bool get isStates => statesInnerType != null;

  /// `X` for a `LegendStates<X>` field, else null.
  String? get statesInnerType {
    final resolved = resolvedType;
    const prefix = 'LegendStates<';
    if (!resolved.startsWith(prefix) || !resolved.endsWith('>')) return null;
    return resolved.substring(prefix.length, resolved.length - 1).trim();
  }

  /// How the default is declared.
  final StyleDefaultKind kind;

  /// The Dart expression the emitter pastes into `defaults(LegendTokens t)`:
  /// the const value's source for [StyleDefaultKind.value], the qualified
  /// tear-off call target (e.g. `LegendSwitch._activeTrack`) for
  /// [StyleDefaultKind.resolve], empty for [StyleDefaultKind.none].
  final String defaultCode;

  /// Human-readable default for the docs manifest (RFC-002 R9): the const
  /// value source, or the `.resolve` tear-off's body expression over `t`.
  final String defaultDescription;

  /// Whether `XTheme.lerp` interpolates this field (else it steps at t=0.5).
  final bool lerp;

  /// The field's dartdoc text with `///` markers stripped (empty when the
  /// field carries no doc comment) — the `legend_gen docs` content
  /// (RFC-002 R9).
  final String doc;
}

/// Plain types the emitter can interpolate — `lerp: true` on anything else
/// is a parse-time error instead of a silent step-fallback (review M4).
const lerpableTypes = {
  'double',
  'Color',
  'EdgeInsets',
  'EdgeInsetsGeometry',
  'BorderRadius',
  'TextStyle',
};

/// `LegendStates<X>` inner types the emitter can interpolate member-wise.
const lerpableStatesInnerTypes = {'Color', 'double'};

/// A `@LegendThemeable` widget class parsed from one source file.
class ThemableWidget {
  const ThemableWidget({
    required this.className,
    required this.fields,
    required this.sourceBasename,
    this.line = 1,
  });

  final String className;
  final List<StyledField> fields;

  /// 1-based line of the class name in the source file (for diagnostics).
  final int line;

  /// Basename of the source file, e.g. `primary_legend_button.dart` — the
  /// target of the emitted `part of` directive.
  final String sourceBasename;
}

/// A final instance field of a `@LegendTokenData` class (RFC-002 R5).
class TokenField {
  const TokenField({required this.name, required this.type});

  /// Field name, e.g. `primary`.
  final String name;

  /// Declared (non-nullable) type source, e.g. `Color`, `List<BoxShadow>`.
  final String type;

  /// Whether the field is a `List<…>` — value `==` compares element-wise
  /// and `hashCode` hashes the elements (list identity would make equal
  /// token sets unequal).
  bool get isList => type.startsWith('List<');
}

/// A `@LegendTokenData` class parsed from one source file (RFC-002 R5):
/// a token data class whose mechanical members (`copyWith`, member-wise
/// `lerp`, value `==`/`hashCode`) are generated. Explicitly NOT a
/// [ThemableWidget] — token classes never get Override widgets, registry
/// entries, or `of()` resolvers (RFC-002 R10 scope).
class TokenClass {
  const TokenClass({
    required this.className,
    required this.fields,
    required this.sourceBasename,
    this.line = 1,
  });

  final String className;
  final List<TokenField> fields;

  /// 1-based line of the class name in the source file (for diagnostics).
  final int line;

  /// Basename of the source file, e.g. `legend_colors.dart` — the target
  /// of the emitted `part of` directive.
  final String sourceBasename;
}

/// A parse/validation problem with a source location.
class LegendGenDiagnostic {
  const LegendGenDiagnostic(this.path, this.line, this.message);

  final String path;
  final int line;
  final String message;

  @override
  String toString() => '$path:$line: $message';
}

/// Thrown when a file violates the decorator contract (DESIGN.md §2.2,
/// RFC-002 R10).
class LegendGenException implements Exception {
  const LegendGenException(this.diagnostics);

  final List<LegendGenDiagnostic> diagnostics;

  @override
  String toString() => diagnostics.join('\n');
}
