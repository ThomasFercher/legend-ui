import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:nomo_gen/src/model.dart';
import 'package:path/path.dart' as p;

/// Parses one Dart file and returns its `@NomoThemeable` widgets.
///
/// Pure AST work — no element resolution, no build graph (DESIGN.md §5).
/// Violations of the decorator contract throw [NomoGenException] with
/// `file:line` diagnostics; they never emit broken code silently.
List<ThemableWidget> parseThemableWidgets(String path, String content) {
  final unit = parseString(
    content: content,
    path: path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final diagnostics = <NomoGenDiagnostic>[];
  final widgets = <ThemableWidget>[];

  int lineOf(SyntacticEntity entity) =>
      unit.lineInfo.getLocation(entity.offset).lineNumber;

  final imports = unit.directives
      .whereType<ImportDirective>()
      .map((d) => d.toSource())
      // Never copy an import of a generated theme file (the widget imports
      // its own output; the output must not import itself).
      .where((source) => !source.contains('.theme.g.dart'))
      .toList();

  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) continue;
    final isThemable = declaration.metadata.any(
      (a) => a.name.name == 'NomoThemeable',
    );
    if (!isThemable) continue;

    final className = declaration.name.lexeme;
    final diagnosticsBefore = diagnostics.length;
    final fields = <ThemedField>[];

    for (final member in declaration.members) {
      if (member is! FieldDeclaration) continue;
      final annotation = member.metadata
          .where((a) => a.name.name == 'Themed')
          .firstOrNull;
      if (annotation == null) continue;

      final type = member.fields.type?.toSource();
      for (final variable in member.fields.variables) {
        final name = variable.name.lexeme;
        if (type == null) {
          diagnostics.add(
            NomoGenDiagnostic(
              path,
              lineOf(variable),
              '@Themed field "$name" needs an explicit type annotation.',
            ),
          );
          continue;
        }
        if (!type.endsWith('?')) {
          diagnostics.add(
            NomoGenDiagnostic(
              path,
              lineOf(variable),
              '@Themed field "$name" must be nullable ("$type?"). Non-null '
              'themed fields make theme values unreachable '
              '(DESIGN.md §2.2).',
            ),
          );
          continue;
        }

        final args = _themedArguments(annotation);
        final defaultsTo = args.defaultsTo;
        if (defaultsTo == null) {
          diagnostics.add(
            NomoGenDiagnostic(
              path,
              lineOf(annotation),
              '@Themed on "$name" needs defaultsTo as a string literal '
              "(e.g. defaultsTo: 't.colors.primary').",
            ),
          );
          continue;
        }

        fields.add(
          ThemedField(
            name: name,
            type: type,
            defaultsTo: defaultsTo,
            lerp: args.lerp,
          ),
        );
      }
    }

    // Constructor contract: a @Themed parameter must not carry a default.
    for (final member in declaration.members) {
      if (member is! ConstructorDeclaration) continue;
      for (final param in member.parameters.parameters) {
        if (param is! DefaultFormalParameter) continue;
        final name = param.name?.lexeme;
        final defaultValue = param.defaultValue;
        final isThemedField = fields.any((f) => f.name == name);
        if (isThemedField &&
            defaultValue != null &&
            defaultValue.toSource() != 'null') {
          diagnostics.add(
            NomoGenDiagnostic(
              path,
              lineOf(param),
              'Constructor parameter "$name" is @Themed and must default to '
              'null — a non-null default would shadow every theme level '
              '(DESIGN.md §2.2).',
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
          NomoGenDiagnostic(
            path,
            lineOf(declaration),
            '@NomoThemeable class "$className" has no @Themed fields.',
          ),
        );
      }
      continue;
    }

    widgets.add(
      ThemableWidget(
        className: className,
        fields: fields,
        sourceImports: imports,
        sourceBasename: p.basename(path),
      ),
    );
  }

  if (diagnostics.isNotEmpty) throw NomoGenException(diagnostics);
  return widgets;
}

typedef _ThemedArgs = ({String? defaultsTo, bool lerp});

_ThemedArgs _themedArguments(Annotation annotation) {
  String? defaultsTo;
  var lerp = false;
  for (final argument in annotation.arguments?.arguments ?? <Expression>[]) {
    if (argument is! NamedExpression) continue;
    final value = argument.expression;
    switch (argument.name.label.name) {
      case 'defaultsTo':
        defaultsTo = _stringLiteralValue(value);
      case 'lerp':
        if (value is BooleanLiteral) lerp = value.value;
    }
  }
  return (defaultsTo: defaultsTo, lerp: lerp);
}

/// Extracts a compile-time string, including adjacent literals
/// (`'a' 'b'` — how long token expressions wrap across lines).
String? _stringLiteralValue(Expression expression) {
  if (expression is SimpleStringLiteral) return expression.value;
  if (expression is AdjacentStrings) {
    final parts = expression.strings;
    if (parts.every((s) => s is SimpleStringLiteral)) {
      return parts.cast<SimpleStringLiteral>().map((s) => s.value).join();
    }
  }
  return null;
}
