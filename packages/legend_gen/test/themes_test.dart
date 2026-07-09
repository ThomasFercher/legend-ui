import 'dart:io';

import 'package:legend_gen/legend_gen.dart';
import 'package:test/test.dart';

/// Wraps [body] in a minimal file that satisfies the whole-file contract
/// (part directive present), so tests can focus on one violation.
String _widgetFile(String body) =>
    '''
import 'package:legend_ui/legend_ui.dart';

part 'bad.theme.g.dart';

$body
''';

void _expectSingleDiagnostic(String source, Matcher matcher) {
  expect(
    () => parseThemableWidgets('bad.dart', source),
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
  final fancyBox = File('test/fixtures/fancy_box.dart').readAsStringSync();
  final statefulChip = File(
    'test/fixtures/stateful_chip.dart',
  ).readAsStringSync();

  group('parser (@Style<T>, RFC-002 R10)', () {
    test('extracts the three default kinds and the lerp flag', () {
      final widgets = parseThemableWidgets('fancy_box.dart', fancyBox);
      expect(widgets, hasLength(1));
      final w = widgets.single;
      expect(w.className, 'FancyBox');
      expect(w.fields.map((f) => f.name), [
        'background',
        'gap',
        'padding',
        'outline',
      ]);

      final background = w.fields[0];
      expect(background.kind, StyleDefaultKind.resolve);
      expect(background.defaultCode, 'FancyBox._background');
      expect(background.defaultDescription, 't.colors.surface');
      expect(background.lerp, isTrue);

      final gap = w.fields[1];
      expect(gap.kind, StyleDefaultKind.value);
      expect(gap.defaultCode, '8.0');
      expect(gap.defaultDescription, '8.0');
      expect(gap.lerp, isTrue);

      final padding = w.fields[2];
      expect(padding.kind, StyleDefaultKind.resolve);
      expect(padding.resolvedType, 'EdgeInsetsGeometry');
      expect(padding.defaultDescription, 'EdgeInsets.all(t.sizes.md)');
      expect(padding.lerp, isFalse);

      final outline = w.fields[3];
      expect(outline.kind, StyleDefaultKind.none);
      expect(outline.themeType, 'Color?');
      expect(outline.defaultDescription, 'null');
    });

    test('recognizes LegendStates<T> fields with their inner type', () {
      final widgets = parseThemableWidgets('stateful_chip.dart', statefulChip);
      final background = widgets.single.fields.first;
      expect(background.isStates, isTrue);
      expect(background.statesInnerType, 'Color');
      expect(background.resolvedType, 'LegendStates<Color>');
      expect(
        background.defaultDescription,
        'LegendStates(normal: t.colors.primary)',
      );
    });

    test('extracts field dartdoc for the docs manifest (R9)', () {
      final widgets = parseThemableWidgets('fancy_box.dart', fancyBox);
      expect(widgets.single.fields.first.doc, 'Fill behind the child.');
    });

    test('rejects a type argument that mismatches the field type', () {
      _expectSingleDiagnostic(
        _widgetFile('''
@LegendThemeable()
class Bad {
  const Bad({this.background});

  @Style<double>.resolve(_background)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.surface;
}
'''),
        allOf(
          contains('bad.dart:9'),
          contains('@Style<double>'),
          contains('does not match the field type "Color"'),
        ),
      );
    });

    test('rejects a missing type argument', () {
      _expectSingleDiagnostic(
        _widgetFile('''
@LegendThemeable()
class Bad {
  const Bad({this.gap});

  @Style(8.0)
  final double? gap;
}
'''),
        allOf(
          contains('bad.dart:9'),
          contains('exactly one generic type argument'),
        ),
      );
    });

    test('rejects non-nullable themed fields with file:line', () {
      _expectSingleDiagnostic(
        _widgetFile('''
@LegendThemeable()
class Bad {
  const Bad({required this.background});

  @Style<Color>.resolve(_background)
  final Color background;
  static Color _background(LegendTokens t) => t.colors.surface;
}
'''),
        allOf(contains('bad.dart:10'), contains('must be nullable')),
      );
    });

    test('rejects non-null constructor defaults on themed params', () {
      _expectSingleDiagnostic(
        _widgetFile('''
@LegendThemeable()
class Bad {
  const Bad({this.gap = 8.0});

  @Style<double>(4.0)
  final double? gap;
}
'''),
        contains('must default to null'),
      );
    });

    test('rejects a .resolve target that is not a static of the class', () {
      _expectSingleDiagnostic(
        _widgetFile('''
@LegendThemeable()
class Bad {
  const Bad({this.background});

  @Style<Color>.resolve(_missing)
  final Color? background;
}
'''),
        allOf(
          contains('bad.dart:9'),
          contains('"_missing"'),
          contains('not a static method of "Bad"'),
        ),
      );
    });

    test('accepts a qualified shared symbol as the .resolve target', () {
      final widgets = parseThemableWidgets(
        'shared.dart',
        _widgetFile('''
@LegendThemeable()
class Shared {
  const Shared({this.padding});

  @Style<EdgeInsetsGeometry>.resolve(SharedDefaults.padding)
  final EdgeInsetsGeometry? padding;
}
''').replaceFirst("part 'bad.theme.g.dart';", "part 'shared.theme.g.dart';"),
      );
      final field = widgets.single.fields.single;
      expect(field.kind, StyleDefaultKind.resolve);
      expect(field.defaultCode, 'SharedDefaults.padding');
      expect(field.defaultDescription, 'SharedDefaults.padding');
    });

    test('rejects the superseded @Themed annotation', () {
      _expectSingleDiagnostic(
        _widgetFile('''
@LegendThemeable()
class Bad {
  const Bad({this.background});

  @Themed(defaultsTo: 't.colors.surface')
  final Color? background;
}
'''),
        allOf(contains('bad.dart:9'), contains('superseded')),
      );
    });

    test('rejects a widget file without the part directive', () {
      const source = '''
import 'package:legend_ui/legend_ui.dart';

@LegendThemeable()
class Bad {
  const Bad({this.gap});

  @Style<double>(8.0)
  final double? gap;
}
''';
      _expectSingleDiagnostic(
        source,
        allOf(
          contains('bad.dart:1'),
          contains("missing `part 'bad.theme.g.dart';`"),
        ),
      );
    });

    test('rejects lerp: true on unsupported types with a diagnostic', () {
      _expectSingleDiagnostic(
        _widgetFile('''
@LegendThemeable()
class Bad {
  const Bad({this.shadows});

  @Style<List<BoxShadow>>.resolve(_shadows, lerp: true)
  final List<BoxShadow>? shadows;
  static List<BoxShadow> _shadows(LegendTokens t) => t.shadows.low;
}
'''),
        contains('lerp: true on "shadows" is not supported'),
      );
    });
  });

  group('emitter (golden)', () {
    test('fancy_box emits the expected theme part file', () {
      final widgets = parseThemableWidgets('fancy_box.dart', fancyBox);
      _matchGolden(emitThemeFile(widgets), 'fancy_box.theme.g.dart.golden');
    });

    test('stateful_chip emits the expected theme part file', () {
      final widgets = parseThemableWidgets('stateful_chip.dart', statefulChip);
      _matchGolden(emitThemeFile(widgets), 'stateful_chip.theme.g.dart.golden');
    });

    test('emitted code is a part file with the full artifact set', () {
      final output = emitThemeFile(
        parseThemableWidgets('fancy_box.dart', fancyBox),
      );
      expect(output, contains("part of 'fancy_box.dart';"));
      expect(output, isNot(contains('import ')));
      expect(output, contains('class FancyBoxTheme '));
      expect(output, contains('class FancyBoxThemeNullable '));
      expect(output, contains('class FancyBoxThemeOverride '));
      expect(
        output,
        contains('factory FancyBoxTheme.defaults(LegendTokens t)'),
      );
      // Tear-offs are called class-qualified; consts are inlined.
      expect(output, contains('background: FancyBox._background(t)'));
      expect(output, contains('gap: 8.0'));
      // Both-keys level-3 lookup (R3): widget type first.
      expect(
        output,
        contains('data.componentOf<FancyBoxThemeNullable>(FancyBox)'),
      );
      // The private in-library resolver (R1).
      expect(output, contains(r'extension _$FancyBoxThemeResolve on FancyBox'));
      expect(output, contains('FancyBoxTheme _theme(BuildContext context)'));
      // Value equality on the sparse class (R2).
      expect(output, contains('bool operator ==(Object other)'));
      expect(output, contains('int get hashCode'));
      // Lerp: no dart:ui lerpDouble (unimportable from a part).
      expect(output, contains('Color.lerp(a.background, b.background, t)!'));
      expect(output, contains('a.gap + (b.gap - a.gap) * t'));
      expect(output, contains('t < 0.5 ? a.padding : b.padding'));
      expect(output, isNot(contains('lerpDouble')));
      // The optional field stays nullable in the resolved theme.
      expect(output, contains('final Color? outline;'));
      expect(output, contains('Color.lerp(a.outline, b.outline, t),'));
    });

    test('LegendStates<Color> fields merge member-wise and fill in of()', () {
      final output = emitThemeFile(
        parseThemableWidgets('stateful_chip.dart', statefulChip),
      );
      expect(
        output,
        contains('LegendStates.merge(background, other.background)'),
      );
      expect(output, contains('LegendStates.lerpWith('));
      expect(output, contains('Color.lerp,'));
      expect(
        output,
        contains(
          'background: resolved.background.withDerived(data.tokens.states)',
        ),
      );
    });
  });

  group('legend_gen docs (golden, R9)', () {
    test('fancy_box emits the expected docs manifest', () {
      final widgets = parseThemableWidgets('fancy_box.dart', fancyBox);
      _matchGolden(emitDocsFile(widgets), 'fancy_box.docs.g.dart.golden');
    });

    test('manifest contains one entry per variable with doc + default', () {
      final output = emitDocsFile(
        parseThemableWidgets('fancy_box.dart', fancyBox),
      );
      expect(output, contains('const List<LegendDocEntry> fancyBoxDocEntries'));
      expect(output, contains("name: 'background'"));
      expect(output, contains("doc: 'Fill behind the child.'"));
      expect(output, contains("defaultDescription: 't.colors.surface'"));
      expect(output, contains("defaultDescription: '8.0'"));
      expect(output, contains("owner: 'FancyBox'"));
    });

    test('LegendStates fields emit one extra entry per state member', () {
      final output = emitDocsFile(
        parseThemableWidgets('stateful_chip.dart', statefulChip),
      );
      for (final member in [
        'background.normal',
        'background.hovered',
        'background.pressed',
        'background.focused',
        'background.disabled',
      ]) {
        expect(output, contains("name: '$member'"));
      }
      expect(
        output,
        contains(
          "defaultDescription: 'LegendStates(normal: t.colors.primary)'",
        ),
      );
    });
  });
}
