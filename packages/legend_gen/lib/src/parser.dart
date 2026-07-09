import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:legend_gen/src/model.dart';
import 'package:path/path.dart' as p;

/// Parses one Dart file and returns its `@LegendThemeable` widgets.
///
/// Pure AST work — no element resolution, no build graph (DESIGN.md §5).
/// Violations of the decorator contract throw [LegendGenException] with
/// `file:line` diagnostics; they never emit broken code silently.
List<ThemableWidget> parseThemableWidgets(String path, String content) {
  final unit = parseString(
    content: content,
    path: path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final diagnostics = <LegendGenDiagnostic>[];
  final widgets = <ThemableWidget>[];

  int lineOf(SyntacticEntity entity) =>
      unit.lineInfo.getLocation(entity.offset).lineNumber;

  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) continue;
    final isThemable = declaration.metadata.any(
      (a) => a.name.name == 'LegendThemeable',
    );
    if (!isThemable) continue;

    final className = declaration.name.lexeme;
    final diagnosticsBefore = diagnostics.length;
    final fields = <StyledField>[];

    for (final member in declaration.members) {
      if (member is! FieldDeclaration) continue;
      final legacy = member.metadata
          .where((a) => a.name.name == 'Themed')
          .firstOrNull;
      if (legacy != null) {
        diagnostics.add(
          LegendGenDiagnostic(
            path,
            lineOf(legacy),
            '@Themed is superseded by the typed @Style<T> contract '
            '(RFC-002 R10) — declare a const value (@Style<T>(v)) or a '
            'tear-off relation (@Style<T>.resolve(_field)).',
          ),
        );
        continue;
      }
      final annotation = member.metadata
          .where((a) => a.name.name == 'Style')
          .firstOrNull;
      if (annotation == null) continue;

      final type = member.fields.type?.toSource();
      for (final variable in member.fields.variables) {
        final name = variable.name.lexeme;
        if (type == null) {
          diagnostics.add(
            LegendGenDiagnostic(
              path,
              lineOf(variable),
              '@Style field "$name" needs an explicit type annotation.',
            ),
          );
          continue;
        }
        if (!type.endsWith('?')) {
          diagnostics.add(
            LegendGenDiagnostic(
              path,
              lineOf(variable),
              '@Style field "$name" must be nullable ("$type?"). Non-null '
              'themed fields make theme values unreachable '
              '(DESIGN.md §2.2).',
            ),
          );
          continue;
        }

        final field = _parseStyleField(
          path: path,
          lineOf: lineOf,
          annotation: annotation,
          declaringClass: declaration,
          className: className,
          name: name,
          type: type,
          doc: _dartdocText(member),
          diagnostics: diagnostics,
        );
        if (field != null) fields.add(field);
      }
    }

    // Constructor contract: a @Style parameter must not carry a default.
    for (final member in declaration.members) {
      if (member is! ConstructorDeclaration) continue;
      for (final param in member.parameters.parameters) {
        if (param is! DefaultFormalParameter) continue;
        final name = param.name?.lexeme;
        final defaultValue = param.defaultValue;
        final isStyledField = fields.any((f) => f.name == name);
        if (isStyledField &&
            defaultValue != null &&
            defaultValue.toSource() != 'null') {
          diagnostics.add(
            LegendGenDiagnostic(
              path,
              lineOf(param),
              'Constructor parameter "$name" is @Style-themed and must '
              'default to null — a non-null default would shadow every '
              'theme level (DESIGN.md §2.2).',
            ),
          );
        }
      }
    }

    if (fields.isEmpty) {
      // Only meaningful when the class produced no other diagnostics;
      // otherwise it's noise caused by the rejected fields above.
      if (diagnostics.length == diagnosticsBefore) {
        diagnostics.add(
          LegendGenDiagnostic(
            path,
            lineOf(declaration),
            '@LegendThemeable class "$className" has no @Style fields.',
          ),
        );
      }
      continue;
    }

    widgets.add(
      ThemableWidget(
        className: className,
        fields: fields,
        sourceBasename: p.basename(path),
        line: lineOf(declaration.name),
      ),
    );
  }

  // Generation is `part of` the widget's library (RFC-002 R1): the source
  // file must carry the matching part directive or the artifact never
  // compiles into the library.
  if (widgets.isNotEmpty) {
    final basename = p.basename(path);
    final expected =
        '${basename.substring(0, basename.length - '.dart'.length)}'
        '.theme.g.dart';
    final hasPart = unit.directives.whereType<PartDirective>().any(
      (d) => d.uri.stringValue == expected,
    );
    if (!hasPart) {
      diagnostics.add(
        LegendGenDiagnostic(
          path,
          1,
          "missing `part '$expected';` — the generated theme file is a "
          'part of the widget library (RFC-002 R1); add the directive '
          'below the imports.',
        ),
      );
    }
  }

  if (diagnostics.isNotEmpty) throw LegendGenException(diagnostics);
  return widgets;
}

/// Parses one `@Style<T>` annotation into a [StyledField]; returns null
/// (and reports) on any contract violation.
StyledField? _parseStyleField({
  required String path,
  required int Function(SyntacticEntity) lineOf,
  required Annotation annotation,
  required ClassDeclaration declaringClass,
  required String className,
  required String name,
  required String type,
  required String doc,
  required List<LegendGenDiagnostic> diagnostics,
}) {
  void report(SyntacticEntity at, String message) =>
      diagnostics.add(LegendGenDiagnostic(path, lineOf(at), message));

  final resolvedType = type.substring(0, type.length - 1);

  // The generic type argument is required and must match the field type —
  // the generator picks merge/lerp strategy from it (RFC-002 R6/R10).
  final typeArguments = annotation.typeArguments?.arguments;
  if (typeArguments == null || typeArguments.length != 1) {
    report(
      annotation,
      '@Style on "$name" needs exactly one generic type argument '
      '(e.g. @Style<$resolvedType>…).',
    );
    return null;
  }
  final typeArgument = typeArguments.single.toSource();
  if (_normalizeType(typeArgument) != _normalizeType(resolvedType)) {
    report(
      typeArguments.single,
      '@Style<$typeArgument> on "$name" does not match the field type '
      '"$resolvedType" — the annotation type argument must equal the '
      "field's non-null type.",
    );
    return null;
  }

  final arguments = annotation.arguments?.arguments ?? <Expression>[];
  final positional = arguments.whereType<Expression>().where(
    (e) => e is! NamedExpression,
  );
  var lerp = false;
  for (final argument in arguments.whereType<NamedExpression>()) {
    if (argument.name.label.name == 'lerp') {
      final value = argument.expression;
      if (value is BooleanLiteral) lerp = value.value;
    }
  }

  final constructor = annotation.constructorName?.name;
  var kind = StyleDefaultKind.none;
  var defaultCode = '';
  var defaultDescription = 'null';

  switch (constructor) {
    case null:
      final value = positional.firstOrNull;
      if (value == null) {
        report(
          annotation,
          '@Style on "$name" needs its positional const default — pass '
          'null for a genuinely optional value, or use '
          '@Style<$resolvedType>.resolve(tearOff) to derive it from the '
          'tokens.',
        );
        return null;
      }
      if (value is! NullLiteral) {
        kind = StyleDefaultKind.value;
        defaultCode = value.toSource();
        defaultDescription = defaultCode;
      }
    case 'resolve':
      final target = positional.firstOrNull;
      if (target is! Identifier) {
        report(
          annotation,
          '@Style.resolve on "$name" needs a const tear-off identifier '
          '($resolvedType Function(LegendTokens)), e.g. a private static '
          '"_$name" declared next to the field.',
        );
        return null;
      }
      kind = StyleDefaultKind.resolve;
      if (target is PrefixedIdentifier) {
        // Qualified (shared/public) symbol — emit and describe as written.
        defaultCode = target.toSource();
        defaultDescription = defaultCode;
      } else {
        // A plain identifier resolves against the widget class scope in
        // the annotation, so it must be one of its statics; the generated
        // classes qualify it explicitly.
        final body = _staticTearOffBody(declaringClass, target.name);
        if (body == null) {
          report(
            target,
            '@Style.resolve on "$name" references "${target.name}", which '
            'is not a static method of "$className" — declare '
            '"static $resolvedType ${target.name}(LegendTokens t) => …;" '
            'in the class, or qualify a shared symbol '
            '(e.g. SharedDefaults.${target.name}).',
          );
          return null;
        }
        defaultCode = '$className.${target.name}';
        defaultDescription = body;
      }
    default:
      report(
        annotation,
        '@Style.$constructor on "$name" is not part of the contract — use '
        '@Style<T>(value) or @Style<T>.resolve(tearOff).',
      );
      return null;
  }

  final field = StyledField(
    name: name,
    type: type,
    kind: kind,
    defaultCode: defaultCode,
    defaultDescription: defaultDescription,
    lerp: lerp,
    doc: doc,
  );

  if (lerp && !_isLerpable(field)) {
    final supported = [
      ...lerpableTypes,
      ...lerpableStatesInnerTypes.map((t) => 'LegendStates<$t>'),
    ];
    report(
      annotation,
      'lerp: true on "$name" is not supported for type "$type" — '
      'supported: ${supported.join(', ')}. Remove the flag '
      '(the field will step at t=0.5 during theme animation).',
    );
    return null;
  }

  return field;
}

bool _isLerpable(StyledField field) {
  final inner = field.statesInnerType;
  if (inner != null) return lerpableStatesInnerTypes.contains(inner);
  return lerpableTypes.contains(field.resolvedType);
}

/// The body expression source of the static method [name] on [declaration]
/// (`static Color _bg(LegendTokens t) => t.colors.primary;` →
/// `t.colors.primary`), or null when no such static exists. Block bodies
/// fall back to the full body source.
String? _staticTearOffBody(ClassDeclaration declaration, String name) {
  for (final member in declaration.members) {
    if (member is! MethodDeclaration) continue;
    if (!member.isStatic || member.name.lexeme != name) continue;
    final body = member.body;
    if (body is ExpressionFunctionBody) return body.expression.toSource();
    return body.toSource();
  }
  return null;
}

String _normalizeType(String source) => source.replaceAll(RegExp(r'\s'), '');

/// The dartdoc of [declaration] as plain text: `///` markers stripped,
/// lines joined with `\n`, no trailing whitespace. Empty when undocumented.
String _dartdocText(AnnotatedNode declaration) {
  final comment = declaration.documentationComment;
  if (comment == null) return '';
  return comment.tokens
      .map((token) {
        final line = token.lexeme;
        final stripped = line.startsWith('///') ? line.substring(3) : line;
        return stripped.startsWith(' ') ? stripped.substring(1) : stripped;
      })
      .join('\n')
      .trim();
}
