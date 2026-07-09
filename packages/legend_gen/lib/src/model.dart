/// A `@Themed` field parsed from a `@LegendThemeable` widget.
class ThemedField {
  const ThemedField({
    required this.name,
    required this.type,
    required this.defaultsTo,
    required this.lerp,
  });

  /// Field name, e.g. `background`.
  final String name;

  /// Declared (nullable) type source, e.g. `Color?`.
  final String type;

  /// Non-null type, e.g. `Color`.
  String get resolvedType =>
      type.endsWith('?') ? type.substring(0, type.length - 1) : type;

  /// Dart expression over `t` (`LegendTokens`).
  final String defaultsTo;

  /// Whether `lerp` interpolates this field (else it steps at t=0.5).
  final bool lerp;
}

/// Types the emitter can interpolate — `lerp: true` on anything else is a
/// parse-time error instead of a silent step-fallback (review M4).
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
    required this.sourceImports,
    required this.sourceBasename,
    this.line = 1,
  });

  final String className;
  final List<ThemedField> fields;

  /// 1-based line of the class name in the source file (for diagnostics).
  final int line;

  /// Import directives copied verbatim from the source file (minus
  /// generated-file self-imports).
  final List<String> sourceImports;

  /// Basename of the source file, e.g. `primary_legend_button.dart`.
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

/// Thrown when a file violates the decorator contract (DESIGN.md §2.2).
class LegendGenException implements Exception {
  const LegendGenException(this.diagnostics);

  final List<LegendGenDiagnostic> diagnostics;

  @override
  String toString() => diagnostics.join('\n');
}
