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
  Map<String, StyleClass> chipIndex() => {
    for (final s in parseStyleClasses('stateful_chip.dart', statefulChip))
      s.className: s,
  };

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
        'stripeWidth',
        'outline',
      ]);

      // Ref-catalog member (qualified tear-off from the tokens library) —
      // emitted and described as written (RFC-002 R10 amendment).
      final background = w.fields[0];
      expect(background.kind, StyleDefaultKind.resolve);
      expect(background.defaultCode, 'LegendColorsRef.surface');
      expect(background.defaultDescription, 'LegendColorsRef.surface');
      expect(background.lerp, isTrue);

      final gap = w.fields[1];
      expect(gap.kind, StyleDefaultKind.value);
      expect(gap.defaultCode, '8.0');
      expect(gap.defaultDescription, '8.0');
      expect(gap.lerp, isTrue);

      // Class-static tear-off — emitted class-qualified, described by its
      // body expression.
      final padding = w.fields[2];
      expect(padding.kind, StyleDefaultKind.resolve);
      expect(padding.resolvedType, 'EdgeInsetsGeometry');
      expect(padding.defaultCode, 'FancyBox._padding');
      expect(padding.defaultDescription, 'EdgeInsets.all(t.sizes.md)');
      expect(padding.lerp, isFalse);

      // Top-level function tear-off — emitted unqualified (the generated
      // part shares the library scope), described by its body expression.
      final stripeWidth = w.fields[3];
      expect(stripeWidth.kind, StyleDefaultKind.resolve);
      expect(stripeWidth.defaultCode, '_stripeWidth');
      expect(stripeWidth.defaultDescription, 't.sizes.borderWidth * 2');

      final outline = w.fields[4];
      expect(outline.kind, StyleDefaultKind.none);
      expect(outline.themeType, 'Color?');
      expect(outline.defaultDescription, 'null');
    });

    test('recognizes @Style() value-class fields through the index '
        '(RFC-002 R6 amendment 7)', () {
      final styles = parseStyleClasses('stateful_chip.dart', statefulChip);
      expect(styles.single.className, 'ChipAccent');
      expect(styles.single.fields.map((f) => f.name), [
        'fill',
        'outline',
        'weight',
      ]);
      expect(styles.single.fields.first.doc, 'Fill behind the chip label.');

      final widgets = parseThemableWidgets(
        'stateful_chip.dart',
        statefulChip,
        styleClasses: {for (final s in styles) s.className: s},
      );
      final accent = widgets.single.fields.first;
      expect(accent.styleClass?.className, 'ChipAccent');
      expect(accent.resolvedType, 'ChipAccent');
      expect(accent.defaultDescription, 'ChipAccent(fill: t.colors.primary)');

      // Without the index the same field parses as a plain opaque type
      // (and lerp: true on it is rejected — covered below).
      expect(
        () => parseThemableWidgets('stateful_chip.dart', statefulChip),
        throwsA(isA<LegendGenException>()),
      );
    });

    test('detects the widget State class in the same file (R13)', () {
      final styles = parseStyleClasses('stateful_chip.dart', statefulChip);
      final widgets = parseThemableWidgets(
        'stateful_chip.dart',
        statefulChip,
        styleClasses: {for (final s in styles) s.className: s},
      );
      expect(widgets.single.stateClassName, '_StatefulChipState');
      expect(widgets.single.stateTypeParameters, isEmpty);

      final none = parseThemableWidgets('fancy_box.dart', fancyBox);
      expect(none.single.stateClassName, isNull);
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

    test('rejects a .resolve target that is neither a static of the class '
        'nor a top-level function', () {
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
          contains(
            'neither a static method of "Bad" nor a top-level '
            'function',
          ),
        ),
      );
    });

    test('rejects an instance-method .resolve target (not a const '
        'tear-off)', () {
      _expectSingleDiagnostic(
        _widgetFile('''
@LegendThemeable()
class Bad {
  const Bad({this.background});

  @Style<Color>.resolve(_background)
  final Color? background;
  Color _background(LegendTokens t) => t.colors.surface;
}
'''),
        allOf(
          contains('"_background"'),
          contains(
            'neither a static method of "Bad" nor a top-level '
            'function',
          ),
          contains('must be const tear-offs'),
        ),
      );
    });

    test('accepts a top-level function as the .resolve target', () {
      final widgets = parseThemableWidgets(
        'toplevel.dart',
        _widgetFile('''
@LegendThemeable()
class TopLevel {
  const TopLevel({this.padding});

  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
}

EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.all(t.sizes.md);
''').replaceFirst("part 'bad.theme.g.dart';", "part 'toplevel.theme.g.dart';"),
      );
      final field = widgets.single.fields.single;
      expect(field.kind, StyleDefaultKind.resolve);
      expect(field.defaultCode, '_padding');
      expect(field.defaultDescription, 'EdgeInsets.all(t.sizes.md)');
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
      final widgets = parseThemableWidgets(
        'stateful_chip.dart',
        statefulChip,
        styleClasses: chipIndex(),
      );
      _matchGolden(emitThemeFile(widgets), 'stateful_chip.theme.g.dart.golden');
    });

    test('stateful_chip emits the expected style part file '
        '(RFC-002 R6 amendment 7)', () {
      final styles = parseStyleClasses('stateful_chip.dart', statefulChip);
      _matchGolden(
        emitStyleFile(styles, styleClasses: chipIndex()),
        'stateful_chip.style.g.dart.golden',
      );
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
      // Ref-catalog tear-offs are called as written, class statics
      // class-qualified, top-level functions unqualified; consts are
      // inlined.
      expect(output, contains('background: LegendColorsRef.surface(t)'));
      expect(output, contains('padding: FancyBox._padding(t)'));
      expect(output, contains('stripeWidth: _stripeWidth(t)'));
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

    test('style value class fields merge member-wise and lerp via the '
        "class's own lerp static", () {
      final output = emitThemeFile(
        parseThemableWidgets(
          'stateful_chip.dart',
          statefulChip,
          styleClasses: chipIndex(),
        ),
      );
      // Resolved theme (non-null field): instance merge, other wins.
      expect(output, contains('accent: accent.merge(other.accent)'));
      // Sparse theme: null receivers pass the other through.
      expect(
        output,
        contains('accent: accent?.merge(other.accent) ?? other.accent'),
      );
      expect(output, contains('ChipAccent.lerp(a.accent, b.accent, t)!'));
      // The withDerived post-hook is gone (RFC-002 R6 amendment 7) —
      // derivation now happens at pick/resolve call sites only.
      expect(output, isNot(contains('withDerived')));
    });

    test('style part: member-wise merge/==/lerp with the type-appropriate '
        'lerper table', () {
      final output = emitStyleFile(
        parseStyleClasses('stateful_chip.dart', statefulChip),
        styleClasses: chipIndex(),
      );
      expect(output, contains("part of 'stateful_chip.dart';"));
      expect(output, contains(r'mixin _$ChipAccent {'));
      expect(output, contains('ChipAccent merge(ChipAccent? other)'));
      expect(output, contains('fill: other.fill ?? _self.fill,'));
      expect(output, contains('bool operator ==(Object other)'));
      expect(output, contains('Color.lerp(a?.fill, b?.fill, t)'));
      expect(
        output,
        contains(r'_$ChipAccentLerpDouble(a?.weight, b?.weight, t)'),
      );
      expect(output, isNot(contains('lerpDouble(')));
    });

    test('nested style classes lerp via their own lerp static', () {
      const source = r'''
import 'package:legend_ui/legend_ui.dart';

part 'nested.style.g.dart';

@Style()
class Inner with _$Inner {
  const Inner({this.fill});
  final Color? fill;
  static Inner? lerp(Inner? a, Inner? b, double t) => _$InnerLerp(a, b, t);
}

@Style()
class Outer with _$Outer {
  const Outer({this.inner});
  final Inner? inner;
  static Outer? lerp(Outer? a, Outer? b, double t) => _$OuterLerp(a, b, t);
}
''';
      final styles = parseStyleClasses('nested.dart', source);
      final output = emitStyleFile(
        styles,
        styleClasses: {for (final s in styles) s.className: s},
      );
      expect(output, contains('inner: Inner.lerp(a?.inner, b?.inner, t)'));
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
      // Ref-catalog defaults read as the catalog member itself; tear-off
      // bodies keep reading as their expression over `t`.
      expect(output, contains("defaultDescription: 'LegendColorsRef.surface'"));
      expect(output, contains("defaultDescription: 't.sizes.borderWidth * 2'"));
      expect(output, contains("defaultDescription: '8.0'"));
      expect(output, contains("owner: 'FancyBox'"));
    });

    test('stateful_chip emits the expected docs manifest (style class + '
        'widget)', () {
      final output = emitDocsFile(
        parseDocsDeclarations(
          'stateful_chip.dart',
          statefulChip,
          styleClasses: chipIndex(),
        ),
      );
      _matchGolden(output, 'stateful_chip.docs.g.dart.golden');
    });

    test('style-value-class fields emit one dot-path entry per member '
        '(RFC-002 R6 amendment 7)', () {
      final output = emitDocsFile(
        parseDocsDeclarations(
          'stateful_chip.dart',
          statefulChip,
          styleClasses: chipIndex(),
        ),
      );
      for (final member in ['accent.fill', 'accent.outline', 'accent.weight']) {
        expect(output, contains("name: '$member'"));
      }
      // Member entries carry the member's own dartdoc.
      expect(output, contains("doc: 'Fill behind the chip label.'"));
      expect(
        output,
        contains("defaultDescription: 'ChipAccent(fill: t.colors.primary)'"),
      );
    });

    test("the style class file gets its own group: 'style' manifest", () {
      final output = emitDocsFile(
        parseDocsDeclarations(
          'stateful_chip.dart',
          statefulChip,
          styleClasses: chipIndex(),
        ),
      );
      expect(
        output,
        contains('const List<LegendDocEntry> chipAccentDocEntries'),
      );
      expect(output, contains("owner: 'ChipAccent'"));
      expect(output, contains("group: 'style'"));
    });
  });

  group('diagnostics name the fix (RFC-002 R11.6)', () {
    test('non-nullable @Style field: states the exact replacement', () {
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
        allOf(
          contains('must be nullable'),
          contains('change the declaration to "final Color? background;"'),
          contains('all @Style fields are nullable'),
        ),
      );
    });

    test('non-null constructor default: says to remove the default', () {
      _expectSingleDiagnostic(
        _widgetFile('''
@LegendThemeable()
class Bad {
  const Bad({this.gap = 8.0});

  @Style<double>(4.0)
  final double? gap;
}
'''),
        allOf(
          contains('has a non-null default'),
          contains('must default to null'),
          contains('remove the default value (write "this.gap,")'),
        ),
      );
    });

    test('missing tear-off: gives the declaration to add', () {
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
          contains(
            'neither a static method of "Bad" nor a top-level '
            'function',
          ),
          contains('declare "Color _missing(LegendTokens t) => …;"'),
          contains('ColorRef.primary'),
        ),
      );
    });

    test('missing field type: shows an example declaration', () {
      _expectSingleDiagnostic(
        _widgetFile('''
@LegendThemeable()
class Bad {
  const Bad({this.background});

  @Style<Color>(null)
  final background;
}
'''),
        allOf(
          contains('needs an explicit type annotation'),
          contains('e.g. "final Color? background;"'),
        ),
      );
    });

    test('annotation/field type mismatch: names the corrected annotation', () {
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
        contains('change the annotation to @Style<Color>'),
      );
    });
  });

  group('@Style() class-form contract (RFC-002 R6 amendment 7)', () {
    void expectStyleDiagnostic(String body, Matcher matcher) {
      expect(
        () => parseStyleClasses('bad.dart', '''
import 'package:legend_ui/legend_ui.dart';

part 'bad.style.g.dart';

$body
'''),
        throwsA(
          isA<LegendGenException>().having(
            (e) => e.diagnostics.single.toString(),
            'diagnostic',
            matcher,
          ),
        ),
      );
    }

    test('the class form takes no value, resolve, flags, or type '
        'argument', () {
      expectStyleDiagnostic(r'''
@Style(Color(0xFF000000))
class Bad with _$Bad {
  const Bad({this.fill});
  final Color? fill;
  static Bad? lerp(Bad? a, Bad? b, double t) => _$BadLerp(a, b, t);
}
''', allOf(contains('bad.dart:5'), contains('exactly @Style()')));
      expectStyleDiagnostic(r'''
@Style<Color>()
class Bad with _$Bad {
  const Bad({this.fill});
  final Color? fill;
  static Bad? lerp(Bad? a, Bad? b, double t) => _$BadLerp(a, b, t);
}
''', contains('takes no value, resolve tear-off, flags, or type argument'));
    });

    test('rejects double-marking with @LegendThemeable', () {
      expectStyleDiagnostic(r'''
@LegendThemeable()
@Style()
class Bad with _$Bad {
  const Bad({this.fill});
  final Color? fill;
  static Bad? lerp(Bad? a, Bad? b, double t) => _$BadLerp(a, b, t);
}
''', contains('keep exactly one marker'));
    });

    test('members must be final, typed, and nullable', () {
      expectStyleDiagnostic(r'''
@Style()
class Bad with _$Bad {
  const Bad({this.fill});
  final Color fill;
  static Bad? lerp(Bad? a, Bad? b, double t) => _$BadLerp(a, b, t);
}
''', allOf(contains('must be nullable'), contains('sparse')));
    });

    test('constructor must be const with every member as a named '
        'null-defaulted parameter', () {
      expectStyleDiagnostic(r'''
@Style()
class Bad with _$Bad {
  const Bad({this.fill});
  final Color? fill;
  final Color? outline;
  static Bad? lerp(Bad? a, Bad? b, double t) => _$BadLerp(a, b, t);
}
''', contains('missing the named parameter "this.outline"'));
      expectStyleDiagnostic(r'''
@Style()
class Bad with _$Bad {
  const Bad({this.fill = const Color(0xFF000000)});
  final Color? fill;
  static Bad? lerp(Bad? a, Bad? b, double t) => _$BadLerp(a, b, t);
}
''', contains('has a non-null default'));
    });

    test('the generated mixin and the lerp redirect must be applied, '
        'with the fix named', () {
      expectStyleDiagnostic(r'''
@Style()
class Bad {
  const Bad({this.fill});
  final Color? fill;
  static Bad? lerp(Bad? a, Bad? b, double t) => _$BadLerp(a, b, t);
}
''', contains(r'add `with _$Bad`'));
      expectStyleDiagnostic(r'''
@Style()
class Bad with _$Bad {
  const Bad({this.fill});
  final Color? fill;
}
''', allOf(contains('missing its lerp redirect'), contains(r'_$BadLerp')));
    });

    test('requires the style part directive', () {
      expect(
        () => parseStyleClasses('bad.dart', r'''
import 'package:legend_ui/legend_ui.dart';

@Style()
class Bad with _$Bad {
  const Bad({this.fill});
  final Color? fill;
  static Bad? lerp(Bad? a, Bad? b, double t) => _$BadLerp(a, b, t);
}
'''),
        throwsA(
          isA<LegendGenException>().having(
            (e) => e.diagnostics.single.toString(),
            'diagnostic',
            contains("missing `part 'bad.style.g.dart';`"),
          ),
        ),
      );
    });

    test('lerp: true on an unindexed opaque type still diagnoses', () {
      _expectSingleDiagnostic(
        _widgetFile('''
@LegendThemeable()
class Bad {
  const Bad({this.accent});

  @Style<UnknownThing>.resolve(_accent, lerp: true)
  final UnknownThing? accent;
  static UnknownThing _accent(LegendTokens t) => UnknownThing();
}
'''),
        allOf(
          contains('lerp: true on "accent" is not supported'),
          contains('style value classes'),
        ),
      );
    });
  });
}
