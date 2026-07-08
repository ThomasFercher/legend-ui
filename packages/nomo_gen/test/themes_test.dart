import 'dart:io';

import 'package:nomo_gen/nomo_gen.dart';
import 'package:test/test.dart';

void main() {
  final fixture = File('test/fixtures/fancy_box.dart').readAsStringSync();

  group('parser', () {
    test('extracts themed fields with defaults and lerp flags', () {
      final widgets = parseThemableWidgets('fancy_box.dart', fixture);
      expect(widgets, hasLength(1));
      final w = widgets.single;
      expect(w.className, 'FancyBox');
      expect(w.fields.map((f) => f.name), ['background', 'gap', 'padding']);
      expect(w.fields[0].defaultsTo, 't.colors.surface');
      expect(w.fields[0].lerp, isTrue);
      expect(w.fields[2].lerp, isFalse);
      expect(w.fields[2].resolvedType, 'EdgeInsetsGeometry');
    });

    test('rejects non-nullable themed fields with file:line', () {
      const bad = '''
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

@NomoThemeable()
class Bad {
  const Bad({required this.background});

  @Themed(defaultsTo: 't.colors.surface')
  final Color background;
}
''';
      expect(
        () => parseThemableWidgets('bad.dart', bad),
        throwsA(
          isA<NomoGenException>().having(
            (e) => e.diagnostics.single.toString(),
            'diagnostic',
            allOf(contains('bad.dart:8'), contains('must be nullable')),
          ),
        ),
      );
    });

    test('rejects non-null constructor defaults on themed params', () {
      const bad = '''
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

@NomoThemeable()
class Bad {
  const Bad({this.gap = 8.0});

  @Themed(defaultsTo: 't.sizes.sm')
  final double? gap;
}
''';
      expect(
        () => parseThemableWidgets('bad.dart', bad),
        throwsA(
          isA<NomoGenException>().having(
            (e) => e.diagnostics.single.toString(),
            'diagnostic',
            contains('must default to null'),
          ),
        ),
      );
    });

    test('never copies generated-file self-imports', () {
      final widgets = parseThemableWidgets('fancy_box.dart', fixture);
      expect(
        widgets.single.sourceImports,
        everyElement(isNot(contains('.theme.g.dart'))),
      );
    });
  });

  group('emitter (golden)', () {
    test('fixture emits the expected theme file', () {
      final widgets = parseThemableWidgets('fancy_box.dart', fixture);
      final output = emitThemeFile(widgets);
      final goldenFile = File('test/goldens/fancy_box.theme.g.dart.golden');

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
    });

    test('emitted code contains the full artifact set', () {
      final output = emitThemeFile(
        parseThemableWidgets('fancy_box.dart', fixture),
      );
      expect(output, contains('class FancyBoxTheme '));
      expect(output, contains('class FancyBoxThemeNullable '));
      expect(output, contains('class FancyBoxThemeOverride '));
      expect(output, contains('factory FancyBoxTheme.defaults(NomoTokens t)'));
      expect(output, contains('static FancyBoxTheme of('));
      expect(output, contains('Color.lerp(a.background, b.background, t)!'));
      expect(output, contains('lerpDouble(a.gap, b.gap, t)!'));
      expect(output, contains('t < 0.5 ? a.padding : b.padding'));
      expect(output, isNot(contains('.theme.g.dart')));
    });
  });
}
