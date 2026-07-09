// The subprocess tests cold-JIT the analyzer-heavy CLI — well over the
// default 30s on slow CI runners.
@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:nomo_gen/nomo_gen.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Walks up from [start] to the workspace root's package config (pub
/// workspaces resolve at the root, not per member package).
String _packageConfigPath(String start) {
  var dir = start;
  while (true) {
    final candidate = p.join(dir, '.dart_tool', 'package_config.json');
    if (File(candidate).existsSync()) return candidate;
    final parent = p.dirname(dir);
    if (parent == dir) {
      throw StateError('no package_config.json above $start');
    }
    dir = parent;
  }
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('nomo_gen_create_');
  });

  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  test(
    'scaffolds a stub the parser accepts and generates its theme file',
    () async {
      final code = await runCreate('NomoBadge', dir: tmp.path);
      expect(code, 0);

      final stub = File(p.join(tmp.path, 'nomo_badge.dart'));
      expect(stub.existsSync(), isTrue, reason: 'stub file must exist');

      // The stub must satisfy the decorator contract end to end.
      final widgets = parseThemableWidgets(stub.path, stub.readAsStringSync());
      expect(widgets, hasLength(1));
      final widget = widgets.single;
      expect(widget.className, 'NomoBadge');
      expect(widget.fields.map((f) => f.name), ['background', 'padding']);
      expect(widget.fields[0].defaultsTo, 't.colors.surface');
      expect(widget.fields[1].defaultsTo, 'EdgeInsets.all(t.sizes.md)');

      // create runs themes immediately: fresh output must already exist.
      final generated = File(p.join(tmp.path, 'nomo_badge.theme.g.dart'));
      expect(generated.existsSync(), isTrue);
      expect(generated.readAsStringSync(), emitThemeFile(widgets));
      expect(generated.readAsStringSync(), contains('class NomoBadgeTheme '));
    },
  );

  test(
    'defaults --dir to lib/src/components/<name-without-nomo-prefix>/',
    () async {
      // Run the real CLI in the temp dir: mutating Directory.current here
      // would race the other suites (the cwd is process-wide).
      final packageDir = Directory.current.path;
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${_packageConfigPath(packageDir)}',
        p.join(packageDir, 'bin', 'nomo_gen.dart'),
        'create',
        'NomoBadge',
      ], workingDirectory: tmp.path);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      final stub = File(
        p.join(
          tmp.path,
          'lib',
          'src',
          'components',
          'badge',
          'nomo_badge.dart',
        ),
      );
      expect(stub.existsSync(), isTrue);
      expect(
        File(
          '${stub.path.substring(0, stub.path.length - '.dart'.length)}'
          '.theme.g.dart',
        ).existsSync(),
        isTrue,
      );
    },
  );

  test('refuses to overwrite an existing file with exit 65', () async {
    final existing = File(p.join(tmp.path, 'nomo_badge.dart'))
      ..writeAsStringSync('// hands off\n');

    final code = await runCreate('NomoBadge', dir: tmp.path);
    expect(code, 65);
    expect(existing.readAsStringSync(), '// hands off\n');
    expect(
      File(p.join(tmp.path, 'nomo_badge.theme.g.dart')).existsSync(),
      isFalse,
      reason: 'a refused create must not generate anything',
    );
  });

  test('rejects a non-UpperCamelCase class name with exit 64', () async {
    expect(await runCreate('nomoBadge', dir: tmp.path), 64);
    expect(await runCreate('Nomo_Badge', dir: tmp.path), 64);
    expect(tmp.listSync(), isEmpty);
  });
}
