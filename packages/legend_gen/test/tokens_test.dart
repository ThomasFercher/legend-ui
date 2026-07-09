import 'dart:io';

import 'package:legend_gen/legend_gen.dart';
import 'package:test/test.dart';

/// Wraps [body] in a minimal file that satisfies the whole-file contract
/// (part directive present), so tests can focus on one violation.
String _tokenFile(String body) =>
    '''
import 'package:legend_ui/legend_ui.dart';

part 'bad.tokens.g.dart';

$body
''';

void _expectSingleDiagnostic(String source, Matcher matcher) {
  expect(
    () => parseTokenClasses('bad.dart', source),
    throwsA(
      isA<LegendGenException>().having(
        (e) => e.diagnostics.single.toString(),
        'diagnostic',
        matcher,
      ),
    ),
  );
}

void _matchGolden(String output, String goldenName) {
  final goldenFile = File('test/goldens/$goldenName');
  if (Platform.environment['UPDATE_GOLDENS'] == '1') {
    goldenFile
      ..createSync(recursive: true)
      ..writeAsStringSync(output);
  }
  expect(
    goldenFile.existsSync(),
    isTrue,
    reason:
        'Golden missing — run with UPDATE_GOLDENS=1 once, review, '
        'and commit.',
  );
  expect(output, goldenFile.readAsStringSync());
}

void main() {
  final miniTokens = File('test/fixtures/mini_tokens.dart').readAsStringSync();

  group('tokens parser (@LegendTokenData, RFC-002 R5)', () {
    test('extracts all instance fields of every annotated class', () {
      final classes = parseTokenClasses('mini_tokens.dart', miniTokens);
      expect(classes, hasLength(2));

      final mini = classes.first;
      expect(mini.className, 'MiniTokens');
      expect(mini.fields.map((f) => f.name), [
        'accent',
        'gap',
        'label',
        'glow',
        'nested',
      ]);
      expect(mini.fields.map((f) => f.type), [
        'Color',
        'double',
        'TextStyle',
        'List<BoxShadow>',
        'MiniNested',
      ]);
      expect(mini.fields[3].isList, isTrue);

      final nested = classes.last;
      expect(nested.className, 'MiniNested');
      expect(nested.fields.single.name, 'amount');
    });

    test('extracts mountedAt (Ref catalog mount, incl. the root '
        'sentinel)', () {
      final classes = parseTokenClasses('mini_tokens.dart', miniTokens);
      // '' is the root sentinel: the class IS the LegendTokens root.
      expect(classes.first.mountedAt, '');
      expect(classes.last.mountedAt, 'nested');
    });

    test('mountedAt defaults to null (no Ref catalog)', () {
      final classes = parseTokenClasses(
        'plain.dart',
        _tokenFile(r'''
@LegendTokenData()
class Plain with _$Plain {
  const Plain({this.amount = 1});
  final double amount;
}
''').replaceFirst("part 'bad.tokens.g.dart';", "part 'plain.tokens.g.dart';"),
      );
      expect(classes.single.mountedAt, isNull);
    });

    test('extracts field dartdoc for the Ref catalog members', () {
      final classes = parseTokenClasses('mini_tokens.dart', miniTokens);
      expect(
        classes.first.fields.first.doc,
        'Accent color drawn behind everything.',
      );
    });

    test('rejects a non-literal mountedAt with the fix named', () {
      _expectSingleDiagnostic(
        _tokenFile(r'''
const _mount = 'sizes';

@LegendTokenData(mountedAt: _mount)
class Bad with _$Bad {
  const Bad({this.amount = 1});
  final double amount;
}
'''),
        allOf(
          contains('mountedAt on "Bad"'),
          contains('plain string literal'),
          contains('write the literal directly'),
        ),
      );
    });

    test('skips statics and unannotated classes', () {
      final classes = parseTokenClasses(
        'plain.dart',
        _tokenFile(r'''
@LegendTokenData()
class Plain with _$Plain {
  const Plain({this.amount = 1});
  final double amount;
  static const preset = Plain();
  static Plain lerp(Plain a, Plain b, double t) => _$PlainLerp(a, b, t);
}

class NotTokens {
  final double ignored = 0;
}
''').replaceFirst("part 'bad.tokens.g.dart';", "part 'plain.tokens.g.dart';"),
      );
      expect(classes, hasLength(1));
      expect(classes.single.fields.map((f) => f.name), ['amount']);
    });

    test('rejects a class that is also @LegendThemeable', () {
      _expectSingleDiagnostic(
        _tokenFile(r'''
@LegendTokenData()
@LegendThemeable()
class Bad with _$Bad {
  const Bad({this.amount = 1});
  final double amount;
}
'''),
        allOf(
          contains('both @LegendTokenData and @LegendThemeable'),
          contains('R10'),
        ),
      );
    });

    test('rejects nullable token fields', () {
      _expectSingleDiagnostic(
        _tokenFile(r'''
@LegendTokenData()
class Bad with _$Bad {
  const Bad({this.amount});
  final double? amount;
}
'''),
        contains('must be non-nullable'),
      );
    });

    test('rejects non-final token fields', () {
      _expectSingleDiagnostic(
        _tokenFile(r'''
@LegendTokenData()
class Bad with _$Bad {
  Bad({this.amount = 1});
  double amount;
}
'''),
        contains('must be final'),
      );
    });

    test('rejects list fields other than List<BoxShadow>', () {
      _expectSingleDiagnostic(
        _tokenFile(r'''
@LegendTokenData()
class Bad with _$Bad {
  const Bad({this.stops = const <double>[]});
  final List<double> stops;
}
'''),
        contains('unsupported list type "List<double>"'),
      );
    });

    test('rejects a class without the generated mixin applied', () {
      _expectSingleDiagnostic(
        _tokenFile('''
@LegendTokenData()
class Bad {
  const Bad({this.amount = 1});
  final double amount;
}
'''),
        contains(r'add `with _$Bad`'),
      );
    });

    test('rejects a class with no instance fields', () {
      _expectSingleDiagnostic(
        _tokenFile(r'''
@LegendTokenData()
class Bad with _$Bad {
  const Bad();
  static const preset = 1;
}
'''),
        contains('has no instance fields'),
      );
    });

    test('rejects a token file without the part directive', () {
      const source = r'''
import 'package:legend_ui/legend_ui.dart';

@LegendTokenData()
class Bad with _$Bad {
  const Bad({this.amount = 1});
  final double amount;
}
''';
      _expectSingleDiagnostic(
        source,
        allOf(
          contains('bad.dart:1'),
          contains("missing `part 'bad.tokens.g.dart';`"),
        ),
      );
    });
  });

  group('tokens emitter (golden)', () {
    test('mini_tokens emits the expected token part file', () {
      final classes = parseTokenClasses('mini_tokens.dart', miniTokens);
      _matchGolden(emitTokensFile(classes), 'mini_tokens.tokens.g.dart.golden');
    });

    test('emitted code is a part file with mixin + lerp per class', () {
      final output = emitTokensFile(
        parseTokenClasses('mini_tokens.dart', miniTokens),
      );
      expect(output, contains("part of 'mini_tokens.dart';"));
      expect(output, isNot(contains('import ')));
      // Mechanical members only — never component-theme machinery
      // (RFC-002 R10 scope).
      expect(output, isNot(contains('ThemeNullable')));
      expect(output, isNot(contains('ThemeOverride')));
      expect(output, isNot(contains(' of(')));
      // One mixin + one lerp function per class.
      expect(output, contains(r'mixin _$MiniTokens {'));
      expect(output, contains(r'mixin _$MiniNested {'));
      expect(
        output,
        contains(r'MiniTokens _$MiniTokensLerp(MiniTokens a, MiniTokens b'),
      );
      // copyWith over the private self-cast (no abstract getters, so the
      // class declares no overrides and annotate_overrides stays quiet).
      expect(output, contains('MiniTokens get _self => this as MiniTokens;'));
      expect(output, contains('accent: accent ?? _self.accent'));
      // Type-appropriate lerpers.
      expect(output, contains('Color.lerp(a.accent, b.accent, t)!'));
      expect(
        output,
        contains('a.gap == b.gap ? a.gap : a.gap * (1.0 - t) + b.gap * t'),
      );
      expect(output, contains('TextStyle.lerp(a.label, b.label, t)!'));
      expect(output, contains('BoxShadow.lerpList(a.glow, b.glow, t)!'));
      expect(output, contains('MiniNested.lerp(a.nested, b.nested, t)'));
      expect(output, isNot(contains('lerpDouble')));
      // Value equality: lists compare element-wise and hash by elements.
      expect(output, contains('bool operator ==(Object other)'));
      expect(output, contains(r'_$listEquals(other.glow, _self.glow)'));
      expect(output, contains('Object.hashAll(_self.glow),'));
      expect(output, contains(r'bool _$listEquals('));
    });

    test('mountedAt emits the Ref const tear-off catalog (RFC-002 R10 '
        'amendment)', () {
      final output = emitTokensFile(
        parseTokenClasses('mini_tokens.dart', miniTokens),
      );
      // The root sentinel ('') reads fields directly off `t` and covers
      // every field type — no filtering.
      expect(output, contains('abstract final class MiniTokensRef {'));
      expect(
        output,
        contains('static Color accent(LegendTokens t) => t.accent;'),
      );
      expect(output, contains('static double gap(LegendTokens t) => t.gap;'));
      expect(
        output,
        contains('static TextStyle label(LegendTokens t) => t.label;'),
      );
      expect(
        output,
        contains('static List<BoxShadow> glow(LegendTokens t) => t.glow;'),
      );
      expect(
        output,
        contains('static MiniNested nested(LegendTokens t) => t.nested;'),
      );
      // A non-root mount reads through its LegendTokens getter.
      expect(output, contains('abstract final class MiniNestedRef {'));
      expect(
        output,
        contains('static double amount(LegendTokens t) => t.nested.amount;'),
      );
      // Members carry the field's dartdoc (the docs-CMS content, R9).
      expect(output, contains('/// Accent color drawn behind everything.'));
      expect(output, contains('/// Some derivation amount.'));
    });

    test('no Ref catalog without mountedAt', () {
      final output = emitTokensFile(
        parseTokenClasses(
          'plain.dart',
          _tokenFile(r'''
@LegendTokenData()
class Plain with _$Plain {
  const Plain({this.amount = 1});
  final double amount;
}
''').replaceFirst("part 'bad.tokens.g.dart';", "part 'plain.tokens.g.dart';"),
        ),
      );
      expect(output, isNot(contains('PlainRef')));
    });

    test('the list-equality helper is only emitted when needed', () {
      final output = emitTokensFile(
        parseTokenClasses(
          'plain.dart',
          _tokenFile(r'''
@LegendTokenData()
class Plain with _$Plain {
  const Plain({this.amount = 1});
  final double amount;
}
''').replaceFirst("part 'bad.tokens.g.dart';", "part 'plain.tokens.g.dart';"),
        ),
      );
      expect(output, isNot(contains(r'_$listEquals')));
    });
  });

  group('legend_gen tokens --check (CI gate)', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('legend_gen_tokens_test');
      File('${tmp.path}/mini_tokens.dart').writeAsStringSync(miniTokens);
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    test('generates, then --check passes; stale output exits dirty '
        '(65)', () async {
      expect(await runTokens([tmp.path]), 0);
      final generated = File('${tmp.path}/mini_tokens.tokens.g.dart');
      expect(generated.existsSync(), isTrue);
      expect(await runTokens([tmp.path], check: true), 0);

      generated.writeAsStringSync('// stale');
      expect(await runTokens([tmp.path], check: true), LegendGenExit.dirty);
    });

    test('--check fails on missing output with the dirty code', () async {
      expect(await runTokens([tmp.path], check: true), LegendGenExit.dirty);
    });

    test('contract violations exit sourceError (66) without writing '
        'output', () async {
      File('${tmp.path}/broken.dart').writeAsStringSync(
        _tokenFile(r'''
@LegendTokenData()
class Broken with _$Broken {
  const Broken({this.amount});
  final double? amount;
}
''').replaceFirst("part 'bad.tokens.g.dart';", "part 'broken.tokens.g.dart';"),
      );
      expect(await runTokens([tmp.path]), LegendGenExit.sourceError);
      expect(File('${tmp.path}/broken.tokens.g.dart').existsSync(), isFalse);
    });

    test('generation is deterministic', () async {
      expect(await runTokens([tmp.path]), 0);
      final first = File(
        '${tmp.path}/mini_tokens.tokens.g.dart',
      ).readAsStringSync();
      expect(await runTokens([tmp.path]), 0);
      final second = File(
        '${tmp.path}/mini_tokens.tokens.g.dart',
      ).readAsStringSync();
      expect(second, first);
    });
  });
}
