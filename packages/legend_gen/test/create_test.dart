import 'dart:io';

import 'package:legend_gen/legend_gen.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('legend_gen_create_');
  });

  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  test(
    'scaffolds a stub the parser accepts and generates its theme file',
    () async {
      final code = await runCreate('LegendBadge', dir: tmp.path);
      expect(code, 0);

      final stub = File(p.join(tmp.path, 'legend_badge.dart'));
      expect(stub.existsSync(), isTrue, reason: 'stub file must exist');

      // The stub must satisfy the decorator contract end to end.
      final widgets = parseThemableWidgets(stub.path, stub.readAsStringSync());
      expect(widgets, hasLength(1));
      final widget = widgets.single;
      expect(widget.className, 'LegendBadge');
      expect(widget.fields.map((f) => f.name), ['background', 'padding']);
      expect(widget.fields[0].kind, StyleDefaultKind.resolve);
      expect(widget.fields[0].defaultCode, 'LegendBadge._background');
      expect(widget.fields[0].defaultDescription, 't.colors.surface');
      expect(widget.fields[1].defaultDescription, 'EdgeInsets.all(t.sizes.md)');

      // create runs themes + docs immediately: fresh output must exist.
      final generated = File(p.join(tmp.path, 'legend_badge.theme.g.dart'));
      expect(generated.existsSync(), isTrue);
      expect(generated.readAsStringSync(), emitThemeFile(widgets));
      expect(generated.readAsStringSync(), contains('class LegendBadgeTheme '));
      expect(
        generated.readAsStringSync(),
        contains("part of 'legend_badge.dart';"),
      );
      final docs = File(p.join(tmp.path, 'legend_badge.docs.g.dart'));
      expect(docs.existsSync(), isTrue);
      expect(docs.readAsStringSync(), emitDocsFile(widgets));
    },
  );

  test(
    'defaults --dir to lib/src/components/<name-without-legend-prefix>/',
    () {
      // In-process on purpose: exercising the real default requires running
      // the CLI with a temp cwd, and cold-compiling the analyzer-heavy CLI
      // in a subprocess deadlines out on slow CI runners. runCreate's
      // scaffold+generate path is covered above with an explicit dir.
      expect(
        defaultCreateDir('LegendBadge'),
        p.join('lib', 'src', 'components', 'badge'),
      );
      expect(
        defaultCreateDir('Chip'),
        p.join('lib', 'src', 'components', 'chip'),
      );
      expect(
        defaultCreateDir('LegendUIBox'),
        p.join('lib', 'src', 'components', 'ui_box'),
      );
    },
  );

  test(
    'refuses to overwrite an existing file with exit cantCreate (73)',
    () async {
      final existing = File(p.join(tmp.path, 'legend_badge.dart'))
        ..writeAsStringSync('// hands off\n');

      final code = await runCreate('LegendBadge', dir: tmp.path);
      expect(code, LegendGenExit.cantCreate);
      expect(existing.readAsStringSync(), '// hands off\n');
      expect(
        File(p.join(tmp.path, 'legend_badge.theme.g.dart')).existsSync(),
        isFalse,
        reason: 'a refused create must not generate anything',
      );
    },
  );

  test('rejects a non-UpperCamelCase class name with exit 64', () async {
    expect(await runCreate('legendBadge', dir: tmp.path), 64);
    expect(await runCreate('Legend_Badge', dir: tmp.path), 64);
    expect(tmp.listSync(), isEmpty);
  });
}
