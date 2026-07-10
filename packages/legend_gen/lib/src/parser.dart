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
///
/// [styleClasses] is the run's style-class index (RFC-002 R6 amendment 7):
/// declared class name → parsed [StyleClass], built by the caller from the
/// same source paths plus [builtinStyleClasses]. A field whose non-null
/// type is a key gets member-wise treatment in the emitted artifacts.
List<ThemableWidget> parseThemableWidgets(
  String path,
  String content, {
  Map<String, StyleClass> styleClasses = const {},
}) {
  final (widgets, diagnostics) = collectThemableWidgets(
    path,
    content,
    styleClasses: styleClasses,
  );
  if (diagnostics.isNotEmpty) throw LegendGenException(diagnostics);
  return widgets;
}

/// Non-throwing core of [parseThemableWidgets] — returns whatever widgets
/// parsed cleanly plus the diagnostics of the ones that did not (used by
/// `legend_gen docs`, which combines widget and style-class diagnostics
/// from one file into a single report).
(List<ThemableWidget>, List<LegendGenDiagnostic>) collectThemableWidgets(
  String path,
  String content, {
  Map<String, StyleClass> styleClasses = const {},
}) {
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
              '@Style field "$name" needs an explicit type annotation — '
              'write the nullable type before the name '
              '(e.g. "final Color? $name;").',
            ),
          );
          continue;
        }
        if (!type.endsWith('?')) {
          diagnostics.add(
            LegendGenDiagnostic(
              path,
              lineOf(variable),
              '@Style field "$name" must be nullable — change the '
              'declaration to "final $type? $name;" (contract rule: all '
              '@Style fields are nullable; a non-null field makes theme '
              'values unreachable, DESIGN.md §2.2).',
            ),
          );
          continue;
        }

        final field = _parseStyleField(
          path: path,
          lineOf: lineOf,
          annotation: annotation,
          unit: unit,
          declaringClass: declaration,
          className: className,
          name: name,
          type: type,
          doc: dartdocText(member),
          styleClasses: styleClasses,
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
              'Constructor parameter "$name" has a non-null default but is '
              '@Style-themed and must default to null — remove the default '
              'value (write "this.$name,"); a non-null default would '
              'shadow every theme level (DESIGN.md §2.2).',
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
            '@LegendThemeable class "$className" has no @Style fields — '
            'annotate at least one field with @Style<T>, or remove the '
            '@LegendThemeable marker.',
          ),
        );
      }
      continue;
    }

    final stateClass = _stateClassOf(unit, className);
    widgets.add(
      ThemableWidget(
        className: className,
        fields: fields,
        sourceBasename: p.basename(path),
        stateClassName: stateClass?.$1,
        stateTypeParameters: stateClass?.$2 ?? '',
        line: lineOf(declaration.name),
      ),
    );
  }

  // Generation is `part of` the widget's library (RFC-002 R1): the source
  // file must carry the matching part directive or the artifact never
  // compiles into the library.
  if (widgets.isNotEmpty) {
    final expected = generatedPartName(path, '.theme.g.dart');
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

  return (widgets, diagnostics);
}

/// The basename of the generated artifact for [path] and [suffix]
/// (`legend_switch.dart` + `.theme.g.dart` → `legend_switch.theme.g.dart`).
String generatedPartName(String path, String suffix) {
  final basename = p.basename(path);
  return '${basename.substring(0, basename.length - '.dart'.length)}$suffix';
}

/// The widget's State class when exactly one class in [unit] declares
/// `extends State<widgetClassName>` (or `State<widgetClassName<…>>`), as
/// `(name, typeParameterSource)` — the RFC-002 R13 auto-extension target.
/// Not found or ambiguous returns null (the extension is simply skipped).
(String, String)? _stateClassOf(CompilationUnit unit, String widgetClassName) {
  final matches = <ClassDeclaration>[];
  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) continue;
    final superclass = declaration.extendsClause?.superclass;
    if (superclass == null) continue;
    final source = superclass.toSource().replaceAll(RegExp(r'\s'), '');
    if (source == 'State<$widgetClassName>' ||
        source.startsWith('State<$widgetClassName<')) {
      matches.add(declaration);
    }
  }
  if (matches.length != 1) return null;
  final state = matches.single;
  return (state.name.lexeme, state.typeParameters?.toSource() ?? '');
}

/// Parses one `@Style<T>` annotation into a [StyledField]; returns null
/// (and reports) on any contract violation.
StyledField? _parseStyleField({
  required String path,
  required int Function(SyntacticEntity) lineOf,
  required Annotation annotation,
  required CompilationUnit unit,
  required ClassDeclaration declaringClass,
  required String className,
  required String name,
  required String type,
  required String doc,
  required Map<String, StyleClass> styleClasses,
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
      '"$resolvedType" — change the annotation to @Style<$resolvedType> '
      '(or fix the field type); the type argument must equal the '
      "field's non-null type.",
    );
    return null;
  }

  final arguments = annotation.arguments?.arguments ?? <Expression>[];
  final positional = arguments.whereType<Expression>().where(
    (e) => e is! NamedExpression,
  );
  var lerp = false;
  var listen = true;
  for (final argument in arguments.whereType<NamedExpression>()) {
    final value = argument.expression;
    if (value is! BooleanLiteral) continue;
    switch (argument.name.label.name) {
      case 'lerp':
        lerp = value.value;
      case 'listen':
        listen = value.value;
    }
  }

  final constructor = annotation.constructorName?.name;
  var kind = StyleDefaultKind.none;
  var defaultCode = '';
  var defaultDescription = 'null';

  switch (constructor) {
    // `@Style<T>(v)` and its flag-bearing spelling `@Style<T>.value(v, …)`
    // (Dart forbids named parameters beside the optional positional of the
    // unnamed form).
    case null || 'value':
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
          '($resolvedType Function(LegendTokens)) — a token Ref catalog '
          'member (e.g. ColorRef.primary), or a private top-level '
          'function "_$name" declared in this file.',
        );
        return null;
      }
      kind = StyleDefaultKind.resolve;
      if (target is PrefixedIdentifier) {
        // Qualified symbol from another class or library (a generated
        // Ref catalog member, a shared defaults class, …) —
        // emit and describe as written.
        defaultCode = target.toSource();
        defaultDescription = defaultCode;
      } else {
        // A bare identifier must be one of the two const-tear-off-able
        // shapes: a static method of the widget class (the annotation
        // resolves it against the class scope; the generated code
        // qualifies it explicitly) or a top-level function of the
        // widget's library (the generated part shares its scope).
        final staticBody = _staticTearOffBody(declaringClass, target.name);
        final topLevelBody = _topLevelTearOffBody(unit, target.name);
        if (staticBody != null) {
          defaultCode = '$className.${target.name}';
          defaultDescription = staticBody;
        } else if (topLevelBody != null) {
          defaultCode = target.name;
          defaultDescription = topLevelBody;
        } else {
          report(
            target,
            '@Style.resolve on "$name" references "${target.name}", which '
            'is neither a static method of "$className" nor a top-level '
            'function in this file — annotation arguments must be const '
            'tear-offs (instance methods and local functions are not); '
            'declare "$resolvedType ${target.name}(LegendTokens t) => …;" '
            'at the top level (or as a static of the class), or use a '
            'token Ref catalog member (e.g. ColorRef.primary).',
          );
          return null;
        }
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
    listen: listen,
    styleClass: styleClasses[_normalizeType(resolvedType)],
    doc: doc,
  );

  if (lerp && !_isLerpable(field)) {
    report(
      annotation,
      'lerp: true on "$name" is not supported for type "$type" — '
      'supported: ${lerpableTypes.join(', ')}, and @Style() style value '
      'classes (which lerp member-wise via their own `lerp` static). '
      'Remove the flag (the field will step at t=0.5 during theme '
      'animation).',
    );
    return null;
  }

  return field;
}

bool _isLerpable(StyledField field) {
  // Style value classes always lerp member-wise through their own `lerp`
  // static (members without a lerper step inside it).
  if (field.styleClass != null) return true;
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

/// The body expression source of the top-level function [name] in [unit]
/// (`Color _bg(LegendTokens t) => t.colors.primary;` → `t.colors.primary`),
/// or null when the unit declares no such function. Top-level functions
/// are the other const-tear-off-able shape besides statics; getters and
/// setters don't tear off, so they are skipped.
String? _topLevelTearOffBody(CompilationUnit unit, String name) {
  for (final declaration in unit.declarations) {
    if (declaration is! FunctionDeclaration) continue;
    if (declaration.isGetter || declaration.isSetter) continue;
    if (declaration.name.lexeme != name) continue;
    final body = declaration.functionExpression.body;
    if (body is ExpressionFunctionBody) return body.expression.toSource();
    return body.toSource();
  }
  return null;
}

String _normalizeType(String source) => source.replaceAll(RegExp(r'\s'), '');

// ── @Style() style value classes (RFC-002 R6 amendment 7) ─────────────

/// Parses one Dart file and returns its `@Style()` style value classes.
///
/// Same pure-AST discipline as [parseThemableWidgets]; contract
/// violations throw [LegendGenException] with `file:line` diagnostics.
List<StyleClass> parseStyleClasses(String path, String content) {
  final (classes, diagnostics) = collectStyleClasses(path, content);
  if (diagnostics.isNotEmpty) throw LegendGenException(diagnostics);
  return classes;
}

/// Non-throwing core of [parseStyleClasses] — returns whatever classes
/// parsed cleanly plus the diagnostics of the ones that did not. The
/// style-class *index* uses the clean classes (a broken class fails its
/// own file's styles pass, never the whole run).
(List<StyleClass>, List<LegendGenDiagnostic>) collectStyleClasses(
  String path,
  String content,
) {
  final unit = parseString(
    content: content,
    path: path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final diagnostics = <LegendGenDiagnostic>[];
  final classes = <StyleClass>[];

  int lineOf(SyntacticEntity entity) =>
      unit.lineInfo.getLocation(entity.offset).lineNumber;

  void report(SyntacticEntity at, String message) =>
      diagnostics.add(LegendGenDiagnostic(path, lineOf(at), message));

  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) continue;
    final marker = declaration.metadata
        .where((a) => a.name.name == 'Style')
        .firstOrNull;
    if (marker == null) continue;

    final className = declaration.name.lexeme;

    // The class form is exactly `@Style()` — no type argument, no default,
    // no flags (RFC-002 R6 amendment 7); defaults belong on the widget
    // fields typed with the class.
    if (marker.typeArguments != null ||
        marker.constructorName != null ||
        (marker.arguments?.arguments.isNotEmpty ?? false)) {
      report(
        marker,
        '@Style on class "$className" takes no value, resolve tear-off, '
        'flags, or type argument — the class form is exactly @Style() '
        '(defaults live on the widget fields typed with the class).',
      );
      continue;
    }
    final conflicting = declaration.metadata
        .map((a) => a.name.name)
        .where((n) => n == 'LegendThemeable' || n == 'LegendTokenData')
        .firstOrNull;
    if (conflicting != null) {
      report(
        marker,
        '"$className" is both @Style and @$conflicting — a style value '
        'class is neither a themable widget nor a token class; keep '
        'exactly one marker.',
      );
      continue;
    }

    final diagnosticsBefore = diagnostics.length;
    final fields = <StyleClassField>[];
    for (final member in declaration.members) {
      if (member is! FieldDeclaration) continue;
      if (member.isStatic) continue;
      final type = member.fields.type?.toSource();
      final doc = dartdocText(member);
      for (final variable in member.fields.variables) {
        final name = variable.name.lexeme;
        if (type == null) {
          report(
            variable,
            '@Style class field "$className.$name" needs an explicit type '
            'annotation — write the nullable type before the name '
            '(e.g. "final Color? $name;").',
          );
          continue;
        }
        if (!type.endsWith('?')) {
          report(
            variable,
            '@Style class field "$className.$name" must be nullable — '
            'change the declaration to "final $type? $name;" (members are '
            'sparse: null means "inherit from the next theme level").',
          );
          continue;
        }
        if (!member.fields.isFinal) {
          report(
            variable,
            '@Style class field "$className.$name" must be final — style '
            'value classes are immutable pure data; write '
            '"final $type $name;".',
          );
          continue;
        }
        fields.add(StyleClassField(name: name, type: type, doc: doc));
      }
    }

    if (fields.isEmpty) {
      if (diagnostics.length == diagnosticsBefore) {
        report(
          declaration,
          '@Style class "$className" has no instance fields — declare its '
          'members as final nullable fields, or remove the @Style marker.',
        );
      }
      continue;
    }

    // Constructor contract: a const unnamed constructor taking every
    // member as a named `this.<member>` parameter with a null default.
    final constructor = declaration.members
        .whereType<ConstructorDeclaration>()
        .where((c) => c.name == null)
        .firstOrNull;
    if (constructor == null || constructor.constKeyword == null) {
      report(
        declaration,
        '@Style class "$className" needs a const unnamed constructor '
        'taking every member as a named parameter — add "const '
        '$className('
        '{${fields.map((f) => 'this.${f.name}').join(', ')}});".',
      );
      continue;
    }
    var constructorOk = true;
    final namedFieldParams = <String>{};
    for (final param in constructor.parameters.parameters) {
      final inner = param is DefaultFormalParameter ? param.parameter : param;
      if (inner is FieldFormalParameter && param.isNamed) {
        namedFieldParams.add(inner.name.lexeme);
      }
      if (param is DefaultFormalParameter &&
          param.defaultValue != null &&
          param.defaultValue!.toSource() != 'null') {
        report(
          param,
          'Constructor parameter "${param.name?.lexeme}" of @Style class '
          '"$className" has a non-null default — remove it (write '
          '"this.${param.name?.lexeme},"); a non-null member default '
          'would clobber lower theme levels in every merge.',
        );
        constructorOk = false;
      }
    }
    for (final field in fields) {
      if (!namedFieldParams.contains(field.name)) {
        report(
          constructor,
          'Constructor of @Style class "$className" is missing the named '
          'parameter "this.${field.name}" — every member must be a named '
          'constructor parameter (the generated merge/lerp construct new '
          'instances member-wise).',
        );
        constructorOk = false;
      }
    }
    if (!constructorOk) continue;

    final hasMixin =
        declaration.withClause?.mixinTypes.any(
          (t) => t.toSource() == '_\$$className',
        ) ??
        false;
    if (!hasMixin) {
      report(
        declaration,
        '@Style class "$className" must apply its generated mixin — add '
        '`with _\$$className` to the declaration (it carries the '
        'member-wise merge and value ==/hashCode).',
      );
      continue;
    }

    final hasLerp = declaration.members.any(
      (m) => m is MethodDeclaration && m.isStatic && m.name.lexeme == 'lerp',
    );
    if (!hasLerp) {
      report(
        declaration,
        '@Style class "$className" is missing its lerp redirect — add '
        '"static $className? lerp($className? a, $className? b, '
        'double t) => _\$${className}Lerp(a, b, t);" (mixins cannot add '
        'statics, so this one-liner is hand-written, exactly like the '
        'token classes).',
      );
      continue;
    }

    classes.add(
      StyleClass(
        className: className,
        fields: fields,
        sourceBasename: p.basename(path),
        line: lineOf(declaration.name),
      ),
    );
  }

  if (classes.isNotEmpty) {
    final expected = generatedPartName(path, '.style.g.dart');
    final hasPart = unit.directives.whereType<PartDirective>().any(
      (d) => d.uri.stringValue == expected,
    );
    if (!hasPart) {
      diagnostics.add(
        LegendGenDiagnostic(
          path,
          1,
          "missing `part '$expected';` — the generated style file is a "
          'part of the declaring library (RFC-002 R6 amendment 7); add '
          'the directive below the imports.',
        ),
      );
    }
  }

  return (classes, diagnostics);
}

/// Combined per-file docs sources (RFC-002 R9): the file's style value
/// classes followed by its themable widgets, with the diagnostics of both
/// parses merged into one report.
List<Object> parseDocsDeclarations(
  String path,
  String content, {
  Map<String, StyleClass> styleClasses = const {},
}) {
  final (styles, styleDiagnostics) = collectStyleClasses(path, content);
  final (widgets, widgetDiagnostics) = collectThemableWidgets(
    path,
    content,
    styleClasses: styleClasses,
  );
  final diagnostics = [...styleDiagnostics, ...widgetDiagnostics];
  if (diagnostics.isNotEmpty) throw LegendGenException(diagnostics);
  return [...styles, ...widgets];
}

/// The dartdoc of [declaration] as plain text: `///` markers stripped,
/// lines joined with `\n`, no trailing whitespace. Empty when undocumented.
/// Shared with the tokens parser (Ref catalog members copy field docs).
String dartdocText(AnnotatedNode declaration) {
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
