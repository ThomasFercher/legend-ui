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
    this.listen = true,
    this.styleClass,
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

  /// The `@Style()`-annotated style value class this field is typed with
  /// (RFC-002 R6 amendment 7), or null for a plain field. Set when the
  /// field's non-null type resolves to a style class in the run's index
  /// (same-run sources plus [builtinStyleClasses]); the emitter then
  /// merges member-wise sparse (via the class's generated `merge`), lerps
  /// via the class's `lerp` static, and the docs manifest lists one entry
  /// per member (`background.hovered`).
  final StyleClass? styleClass;

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

  /// Whether the generated resolver registers a rebuild aspect for this
  /// field (RFC-002 R12). `listen: false` fields resolve fresh on every
  /// build but register no dependency.
  final bool listen;

  /// The field's dartdoc text with `///` markers stripped (empty when the
  /// field carries no doc comment) — the `legend_gen docs` content
  /// (RFC-002 R9).
  final String doc;
}

/// Plain types the emitter can interpolate — `lerp: true` on anything else
/// is a parse-time error instead of a silent step-fallback (review M4).
/// Fields typed with a `@Style()` class are additionally lerpable through
/// the class's own `lerp` static (RFC-002 R6 amendment 7).
const lerpableTypes = {
  'double',
  'Color',
  'EdgeInsets',
  'EdgeInsetsGeometry',
  'BorderRadius',
  'TextStyle',
};

/// A `@LegendThemeable` widget class parsed from one source file.
class ThemableWidget {
  const ThemableWidget({
    required this.className,
    required this.fields,
    required this.sourceBasename,
    this.stateClassName,
    this.stateTypeParameters = '',
    this.isStateful = false,
    this.line = 1,
  });

  final String className;
  final List<StyledField> fields;

  /// Whether the widget is known to be stateful — it `extends
  /// StatefulWidget` directly, or its State class was detected in the
  /// same file. Gates the `_\$XThemeState` mixin (RFC-002 R13):
  /// `on State<X>` only satisfies State's bound for stateful widgets.
  final bool isStateful;

  /// The widget's `State` class when it is unambiguously detected in the
  /// same file (`class _XState extends State<X>`), else null (not found or
  /// ambiguous — RFC-002 R13). Non-null makes the emitter add the
  /// `theme` getter extension on the State class.
  final String? stateClassName;

  /// The detected State class's type parameter list source (e.g. `<T>`),
  /// empty when it has none — re-declared on the generated extension.
  final String stateTypeParameters;

  /// 1-based line of the class name in the source file (for diagnostics).
  final int line;

  /// Basename of the source file, e.g. `primary_legend_button.dart` — the
  /// target of the emitted `part of` directive.
  final String sourceBasename;
}

/// A member of a `@Style()` style value class (RFC-002 R6 amendment 7).
class StyleClassField {
  const StyleClassField({
    required this.name,
    required this.type,
    this.doc = '',
  });

  /// Member name, e.g. `hovered`.
  final String name;

  /// Declared (nullable) type source, e.g. `Color?`.
  final String type;

  /// Non-null type, e.g. `Color`.
  String get resolvedType =>
      type.endsWith('?') ? type.substring(0, type.length - 1) : type;

  /// The member's dartdoc text (empty when undocumented) — surfaces in the
  /// docs manifests (RFC-002 R9).
  final String doc;
}

/// A `@Style()`-annotated style value class parsed from one source file
/// (RFC-002 R6 amendment 7): a pure-data bundle of themed members whose
/// mechanical members (member-wise sparse `merge`, member-wise lerp, value
/// `==`/`hashCode`) are generated into a `<file>.style.g.dart` part.
/// Explicitly NOT a [ThemableWidget]: style classes never get Override
/// widgets, registry entries, or `of()` resolvers — they are value types
/// carried BY widget theme fields.
class StyleClass {
  const StyleClass({
    required this.className,
    required this.fields,
    required this.sourceBasename,
    this.line = 1,
  });

  final String className;
  final List<StyleClassField> fields;

  /// 1-based line of the class name in the source file (for diagnostics).
  final int line;

  /// Basename of the source file, e.g. `interactive_colors.dart` — the
  /// target of the emitted `part of` directive.
  final String sourceBasename;
}

/// The kit's predefined style classes, compiled into the CLI so a consumer
/// project's widgets get member-wise treatment for fields typed with them
/// without the CLI scanning the kit's sources (generation stays strictly
/// one-file-in/one-file-out; CLI↔kit version lock-step is enforced by the
/// `doctor` pin, RFC-002 R11.4). Same-run declarations win on a name
/// clash.
const Map<String, StyleClass> builtinStyleClasses = {
  'InteractiveColors': StyleClass(
    className: 'InteractiveColors',
    sourceBasename: 'interactive_colors.dart',
    fields: [
      StyleClassField(
        name: 'normal',
        type: 'Color?',
        doc: 'Fill at rest (and the base unset members fall back to).',
      ),
      StyleClassField(
        name: 'hovered',
        type: 'Color?',
        doc: 'Fill while a pointer hovers the widget.',
      ),
      StyleClassField(
        name: 'pressed',
        type: 'Color?',
        doc: 'Fill while the widget is actively pressed.',
      ),
      StyleClassField(
        name: 'focused',
        type: 'Color?',
        doc: 'Fill while the widget holds keyboard focus.',
      ),
      StyleClassField(
        name: 'disabled',
        type: 'Color?',
        doc: 'Fill while the widget is disabled.',
      ),
    ],
  ),
};

/// A final instance field of a `@LegendTokenData` class (RFC-002 R5).
class TokenField {
  const TokenField({required this.name, required this.type, this.doc = ''});

  /// Field name, e.g. `primary`.
  final String name;

  /// Declared (non-nullable) type source, e.g. `Color`, `List<BoxShadow>`.
  final String type;

  /// The field's dartdoc text with `///` markers stripped (empty when
  /// undocumented) — copied onto the matching Ref catalog member
  /// (RFC-002 R10 amendment).
  final String doc;

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
    this.mountedAt,
    this.refName,
    this.line = 1,
  });

  final String className;
  final List<TokenField> fields;

  /// The `LegendTokens` getter this class sits behind (e.g. `'colors'`),
  /// from `@LegendTokenData(mountedAt: …)`. Non-null makes the emitter
  /// additionally generate the [effectiveRefName] const tear-off catalog
  /// (RFC-002 R10 amendment); null emits no catalog.
  final String? mountedAt;

  /// The emitted Ref catalog's class name, from
  /// `@LegendTokenData(refName: …)`; null defaults to `<ClassName>Ref`.
  /// The kit sets short explicit names (`ColorRef`, `SizeRef`, `TextRef`,
  /// `ShadowRef`, `StateRef`, `TokenRef`) — annotation ubiquity earns
  /// terseness (a documented exception to the Legend-prefix rule; still
  /// an explicit declaration, never a naming convention).
  final String? refName;

  /// The effective catalog name: [refName], else `<ClassName>Ref`.
  String get effectiveRefName => refName ?? '${className}Ref';

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
