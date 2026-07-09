import 'dart:io';

import 'package:nomo_gen/nomo_gen.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Minimal healthy fixture; `CoolBox` sits on line 7.
const _source = '''
import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

import 'cool_box.theme.g.dart';

@NomoThemeable()
class CoolBox extends StatelessWidget {
  const CoolBox({super.key, this.background});

  @Themed(defaultsTo: 't.colors.surface', lerp: true)
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = CoolBoxTheme.of(
      context,
      CoolBoxThemeNullable(background: background),
    );
    return ColoredBox(color: theme.background);
  }
}
''';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('nomo_gen_doctor_');
  });

  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  String write(String name, String content) {
    final file = File(p.join(tmp.path, name))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
    return file.path;
  }

  test('healthy tree: no findings, exit 0', () async {
    write('cool_box.dart', _source);
    await runThemes([tmp.path]);

    expect(collectDoctorFindings([tmp.path]), isEmpty);
    expect(await runDoctor([tmp.path]), 0);
  });

  test('(a) missing .theme.g.dart for a @NomoThemeable widget', () async {
    write('cool_box.dart', _source);

    final findings = collectDoctorFindings([tmp.path]);
    expect(findings, hasLength(1));
    expect(findings.single.severity, DoctorSeverity.error);
    expect(
      '${findings.single}',
      allOf(
        startsWith('error: '),
        contains('cool_box.dart:7'),
        contains('"CoolBox" has no generated theme file'),
      ),
    );
    expect(await runDoctor([tmp.path]), 1);
  });

  test('(b) stale generated output after the source changed', () async {
    final source = write('cool_box.dart', _source);
    await runThemes([tmp.path]);
    File(source).writeAsStringSync(
      _source.replaceFirst('t.colors.surface', 't.colors.primary'),
    );

    final findings = collectDoctorFindings([tmp.path]);
    expect(findings, hasLength(1));
    expect(findings.single.severity, DoctorSeverity.error);
    expect(
      '${findings.single}',
      allOf(contains('cool_box.theme.g.dart:1'), contains('stale')),
    );
    expect(await runDoctor([tmp.path]), 1);
  });

  test('(c) orphaned generated file whose source is gone', () async {
    final source = write('cool_box.dart', _source);
    await runThemes([tmp.path]);
    File(source).deleteSync();

    final findings = collectDoctorFindings([tmp.path]);
    expect(findings, hasLength(1));
    expect(findings.single.severity, DoctorSeverity.error);
    expect(
      '${findings.single}',
      allOf(
        contains('cool_box.theme.g.dart:1'),
        contains('orphaned'),
        contains('cool_box.dart is gone'),
      ),
    );
    expect(await runDoctor([tmp.path]), 1);
  });

  test(
    '(c) orphaned generated file whose source lost @NomoThemeable',
    () async {
      write('cool_box.dart', _source);
      await runThemes([tmp.path]);
      write('cool_box.dart', 'class CoolBox {}\n');

      final findings = collectDoctorFindings([tmp.path]);
      expect(findings, hasLength(1));
      expect(findings.single.severity, DoctorSeverity.error);
      expect(
        '${findings.single}',
        allOf(contains('orphaned'), contains('no @NomoThemeable widget')),
      );
      expect(await runDoctor([tmp.path]), 1);
    },
  );

  test('(d) version-stamp drift in the header is a warning', () async {
    write('cool_box.dart', _source);
    await runThemes([tmp.path]);
    final generated = File(p.join(tmp.path, 'cool_box.theme.g.dart'));
    generated.writeAsStringSync(
      generated.readAsStringSync().replaceFirst(
        'nomo_gen v$nomoGenVersion',
        'nomo_gen v0.0.1',
      ),
    );

    final findings = collectDoctorFindings([tmp.path]);
    final warnings = findings
        .where((f) => f.severity == DoctorSeverity.warning)
        .map((f) => '$f');
    expect(
      warnings,
      contains(
        allOf(
          startsWith('warning: '),
          contains('cool_box.theme.g.dart:1'),
          contains('v0.0.1'),
          contains('v$nomoGenVersion'),
        ),
      ),
    );
    expect(await runDoctor([tmp.path]), 1);
  });

  test('decorator-contract violations surface as error findings', () async {
    write('bad_box.dart', '''
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

@NomoThemeable()
class BadBox {
  const BadBox({required this.background});

  @Themed(defaultsTo: 't.colors.surface')
  final Color background;
}
''');

    final findings = collectDoctorFindings([tmp.path]);
    expect(findings, hasLength(1));
    expect(findings.single.severity, DoctorSeverity.error);
    expect(
      '${findings.single}',
      allOf(contains('bad_box.dart:8'), contains('must be nullable')),
    );
    expect(await runDoctor([tmp.path]), 1);
  });
}
