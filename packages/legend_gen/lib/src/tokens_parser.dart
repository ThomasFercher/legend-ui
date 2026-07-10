import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:legend_gen/src/model.dart';
import 'package:legend_gen/src/parser.dart';
import 'package:path/path.dart' as p;

/// Parses one Dart file and returns its `@LegendTokenData` classes
/// (RFC-002 R5).
///
/// Pure AST work — no element resolution, no build graph (DESIGN.md §5),
/// exactly like the `@LegendThemeable` parser. Violations of the token
/// contract throw [LegendGenException] with `file:line` diagnostics.
///
/// Contract, enforced here:
///
/// - the class is not also `@LegendThemeable` (tokens are the base theme,
///   never component themes — RFC-002 R10 scope),
/// - every instance field is `final`, explicitly typed and non-nullable,
/// - `List<…>` fields are `List<BoxShadow>` (the one list lerper),
/// - the class applies the generated mixin (`with _$ClassName`),
/// - `mountedAt:` (the Ref-catalog mount, RFC-002 R10 amendment) and
///   `refName:` (the catalog's class name) are plain string literals
///   when given,
/// - the file carries `part '<file>.tokens.g.dart';`.
List<TokenClass> parseTokenClasses(String path, String content) {
  final unit = parseString(
    content: content,
    path: path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final diagnostics = <LegendGenDiagnostic>[];
  final classes = <TokenClass>[];

  int lineOf(SyntacticEntity entity) =>
      unit.lineInfo.getLocation(entity.offset).lineNumber;
  void report(SyntacticEntity at, String message) =>
      diagnostics.add(LegendGenDiagnostic(path, lineOf(at), message));

  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) continue;
    final marker = declaration.metadata
        .where((a) => a.name.name == 'LegendTokenData')
        .firstOrNull;
    if (marker == null) continue;

    final className = declaration.name.lexeme;
    final markerArguments = marker.arguments?.arguments ?? <Expression>[];
    String? mountedAt;
    final mountArgument = markerArguments
        .whereType<NamedExpression>()
        .where((a) => a.name.label.name == 'mountedAt')
        .firstOrNull;
    if (mountArgument != null) {
      final value = mountArgument.expression;
      if (value is SimpleStringLiteral) {
        mountedAt = value.value;
      } else if (value is! NullLiteral) {
        report(
          mountArgument,
          'mountedAt on "$className" must be a plain string literal (the '
          "LegendTokens getter the class sits behind, e.g. 'sizes') — the "
          'Ref catalog is generated from it (RFC-002 R10 amendment); '
          'write the literal directly.',
        );
        continue;
      }
    }
    String? refName;
    final refNameArgument = markerArguments
        .whereType<NamedExpression>()
        .where((a) => a.name.label.name == 'refName')
        .firstOrNull;
    if (refNameArgument != null) {
      final value = refNameArgument.expression;
      if (value is SimpleStringLiteral) {
        refName = value.value;
      } else if (value is! NullLiteral) {
        report(
          refNameArgument,
          'refName on "$className" must be a plain string literal (the '
          "emitted Ref catalog's class name, e.g. 'ColorRef') — write the "
          'literal directly, or drop it to default to <ClassName>Ref.',
        );
        continue;
      }
    }
    if (declaration.metadata.any((a) => a.name.name == 'LegendThemeable')) {
      report(
        marker,
        '"$className" is both @LegendTokenData and @LegendThemeable — '
        'token classes are the base theme and never component themes '
        '(RFC-002 R10 scope); remove one marker.',
      );
      continue;
    }

    final fields = <TokenField>[];
    var fieldsValid = true;
    for (final member in declaration.members) {
      if (member is! FieldDeclaration || member.isStatic) continue;
      final type = member.fields.type?.toSource();
      for (final variable in member.fields.variables) {
        final name = variable.name.lexeme;
        if (type == null) {
          report(
            variable,
            'token field "$name" needs an explicit type annotation — '
            'write the type before the name (e.g. "final Color $name;").',
          );
          fieldsValid = false;
          continue;
        }
        if (type.endsWith('?')) {
          report(
            variable,
            'token field "$name" must be non-nullable ("$type" declared) — '
            'drop the "?" and give it a value everywhere; tokens are the '
            'complete base theme with no "inherit" level below them '
            '(DESIGN.md §2.1).',
          );
          fieldsValid = false;
          continue;
        }
        if (!member.fields.isFinal) {
          report(
            variable,
            'token field "$name" must be final — add the "final" keyword; '
            'token classes are immutable data (DESIGN.md §2.1).',
          );
          fieldsValid = false;
          continue;
        }
        if (type.startsWith('List<') && type != 'List<BoxShadow>') {
          report(
            variable,
            'token field "$name" has unsupported list type "$type" — the '
            'only lerpable list is List<BoxShadow> (BoxShadow.lerpList); '
            'use List<BoxShadow>, or model the values as separate fields.',
          );
          fieldsValid = false;
          continue;
        }
        fields.add(
          TokenField(name: name, type: type, doc: dartdocText(member)),
        );
      }
    }

    if (fields.isEmpty) {
      if (fieldsValid) {
        report(
          declaration.name,
          '@LegendTokenData class "$className" has no instance fields — '
          'declare the token values as final instance fields, or remove '
          'the marker.',
        );
      }
      continue;
    }

    final mixinName = '_\$$className';
    final appliesMixin =
        declaration.withClause?.mixinTypes.any(
          (t) => t.toSource() == mixinName,
        ) ??
        false;
    if (!appliesMixin) {
      report(
        declaration.name,
        '"$className" does not apply the generated mixin — add '
        '`with $mixinName` to the class declaration.',
      );
    }

    classes.add(
      TokenClass(
        className: className,
        fields: fields,
        sourceBasename: p.basename(path),
        mountedAt: mountedAt,
        refName: refName,
        line: lineOf(declaration.name),
      ),
    );
  }

  // Generation is `part of` the token library (mirrors RFC-002 R1): the
  // source file must carry the matching part directive.
  if (classes.isNotEmpty) {
    final basename = p.basename(path);
    final expected =
        '${basename.substring(0, basename.length - '.dart'.length)}'
        '.tokens.g.dart';
    final hasPart = unit.directives.whereType<PartDirective>().any(
      (d) => d.uri.stringValue == expected,
    );
    if (!hasPart) {
      diagnostics.add(
        LegendGenDiagnostic(
          path,
          1,
          "missing `part '$expected';` — the generated token file is a "
          'part of the token library (RFC-002 R5); add the directive '
          'below the imports.',
        ),
      );
    }
  }

  if (diagnostics.isNotEmpty) throw LegendGenException(diagnostics);
  return classes;
}
