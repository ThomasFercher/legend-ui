import 'dart:io';

import 'package:legend_gen/legend_gen.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Minimal healthy fixture; `CoolBox` sits on line 7.
const _source = '''
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

part 'cool_box.theme.g.dart';

@LegendThemeable()
class CoolBox extends StatelessWidget {
  const CoolBox({super.key, this.background});

  /// Fill behind the child.
  @Style<Color>.resolve(_background, lerp: true)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.surface;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    return ColoredBox(color: theme.background);
  }
}
''';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('legend_gen_doctor_');
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

  test('(a) missing .theme.g.dart for a @LegendThemeable widget', () async {
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
    expect(await runDoctor([tmp.path]), LegendGenExit.dirty);
  });

  test('(b) stale generated output after the source changed', () async {
    final source = write('cool_box.dart', _source);
    await runThemes([tmp.path]);
    // A tear-off *body* edit doesn't change the generated file (the body
    // lives in the widget library) — flip the lerp flag instead.
    File(
      source,
    ).writeAsStringSync(_source.replaceFirst('lerp: true', 'lerp: false'));

    final findings = collectDoctorFindings([tmp.path]);
    expect(findings, hasLength(1));
    expect(findings.single.severity, DoctorSeverity.error);
    expect(
      '${findings.single}',
      allOf(contains('cool_box.theme.g.dart:1'), contains('stale')),
    );
    expect(await runDoctor([tmp.path]), LegendGenExit.dirty);
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
    expect(await runDoctor([tmp.path]), LegendGenExit.dirty);
  });

  test(
    '(c) orphaned generated file whose source lost @LegendThemeable',
    () async {
      write('cool_box.dart', _source);
      await runThemes([tmp.path]);
      write('cool_box.dart', 'class CoolBox {}\n');

      final findings = collectDoctorFindings([tmp.path]);
      expect(findings, hasLength(1));
      expect(findings.single.severity, DoctorSeverity.error);
      expect(
        '${findings.single}',
        allOf(contains('orphaned'), contains('no @LegendThemeable widget')),
      );
      expect(await runDoctor([tmp.path]), LegendGenExit.dirty);
    },
  );

  test('(d) version-stamp drift in the header is a warning', () async {
    write('cool_box.dart', _source);
    await runThemes([tmp.path]);
    final generated = File(p.join(tmp.path, 'cool_box.theme.g.dart'));
    generated.writeAsStringSync(
      generated.readAsStringSync().replaceFirst(
        'legend_gen v$legendGenVersion',
        'legend_gen v0.0.1',
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
          contains('v$legendGenVersion'),
        ),
      ),
    );
    expect(await runDoctor([tmp.path]), LegendGenExit.dirty);
  });

  test('decorator-contract violations surface as error findings', () async {
    write('bad_box.dart', '''
import 'package:legend_ui/legend_ui.dart';

@LegendThemeable()
class BadBox {
  const BadBox({required this.background});

  @Style<Color>(Color(0xFF000000))
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
    expect(await runDoctor([tmp.path]), LegendGenExit.dirty);
  });

  group('(e) version pin (RFC-002 R11.4)', () {
    String lockContent({String? legendGen, String? legendUi}) {
      final buffer = StringBuffer('''
# Generated by pub
# See https://dart.dev/tools/pub/glossary#lockfile
packages:
  args:
    dependency: transitive
    description:
      name: args
      sha256: "0000"
      url: "https://pub.dev"
    source: hosted
    version: "2.7.0"
''');
      if (legendGen != null) {
        buffer.write('''
  legend_gen:
    dependency: "direct dev"
    description:
      path: "packages/legend_gen"
      relative: true
    source: path
    version: "$legendGen"
''');
      }
      if (legendUi != null) {
        buffer.write('''
  legend_ui:
    dependency: "direct main"
    description:
      path: "packages/legend_ui"
      relative: true
    source: path
    version: "$legendUi"
''');
      }
      buffer.write('''
sdks:
  dart: ">=3.10.0 <4.0.0"
''');
      return '$buffer';
    }

    test('lockedVersion parses package versions out of a lockfile', () {
      final lock = lockContent(legendGen: '1.2.3', legendUi: '4.5.6');
      expect(lockedVersion(lock, 'legend_gen'), '1.2.3');
      expect(lockedVersion(lock, 'legend_ui'), '4.5.6');
      expect(lockedVersion(lock, 'args'), '2.7.0');
      expect(lockedVersion(lock, 'missing'), isNull);
    });

    test('matching pin: no findings', () async {
      write('cool_box.dart', _source);
      await runThemes([tmp.path]);
      write(
        'pubspec.lock',
        lockContent(legendGen: legendGenVersion, legendUi: '1.0.0-dev.5'),
      );

      expect(collectDoctorFindings([tmp.path]), isEmpty);
      expect(await runDoctor([tmp.path]), LegendGenExit.success);
    });

    test('running CLI ≠ resolved legend_gen: warning naming the fix', () async {
      write('cool_box.dart', _source);
      await runThemes([tmp.path]);
      write('pubspec.lock', lockContent(legendGen: '9.9.9'));

      final findings = collectDoctorFindings([tmp.path]);
      expect(findings, hasLength(1));
      expect(findings.single.severity, DoctorSeverity.warning);
      expect(
        '${findings.single}',
        allOf(
          contains('pubspec.lock:1'),
          contains('v$legendGenVersion'),
          contains('v9.9.9'),
          contains('dart run legend_gen'),
        ),
      );
      expect(await runDoctor([tmp.path]), LegendGenExit.dirty);
    });

    test('legend_ui resolved without a legend_gen pin: warning', () async {
      write('cool_box.dart', _source);
      await runThemes([tmp.path]);
      write('pubspec.lock', lockContent(legendUi: '1.0.0-dev.5'));

      final findings = collectDoctorFindings([tmp.path]);
      expect(findings, hasLength(1));
      expect(findings.single.severity, DoctorSeverity.warning);
      expect(
        '${findings.single}',
        allOf(
          contains('does not pin legend_gen'),
          contains('dart pub add --dev legend_gen'),
        ),
      );
    });

    test('a lockfile without either package produces no findings', () async {
      write('cool_box.dart', _source);
      await runThemes([tmp.path]);
      write('pubspec.lock', lockContent());

      expect(collectDoctorFindings([tmp.path]), isEmpty);
    });
  });
}
