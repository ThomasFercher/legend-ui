import 'dart:io';

import 'package:legend_gen/src/emitter.dart';
import 'package:legend_gen/src/exit_codes.dart';
import 'package:legend_gen/src/model.dart';
import 'package:legend_gen/src/parser.dart';
import 'package:legend_gen/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

const _generatedSuffix = '.theme.g.dart';

/// How much a [DoctorFinding] matters; both count as problems
/// (exit [LegendGenExit.dirty]).
enum DoctorSeverity { error, warning }

/// One `legend_gen doctor` finding: a located diagnostic plus a severity.
class DoctorFinding {
  const DoctorFinding(this.severity, this.diagnostic);

  /// How much this finding matters.
  final DoctorSeverity severity;

  /// The located problem, message naming the fix.
  final LegendGenDiagnostic diagnostic;

  @override
  String toString() =>
      '${severity.name}: ${diagnostic.path}:${diagnostic.line} '
      '${diagnostic.message}';
}

/// Runs `legend_gen doctor`: validates the theme setup under [paths] and
/// prints one `severity: path:line message` line per finding
/// (DESIGN.md §5.3 "a `doctor` for mis-registered themes").
///
/// Checked, in order:
///
/// - a `@LegendThemeable` widget whose `.theme.g.dart` is missing,
/// - stale generated output (re-emit and diff, like `themes --check`),
/// - orphaned `*.theme.g.dart` whose source is gone or no longer
///   `@LegendThemeable`,
/// - a generated file stamped by a different legend_gen version (warning),
/// - the project's resolved `legend_gen` pin vs the running CLI version
///   (warning; RFC-002 R11.4 — see [versionPinFindings]),
///
/// plus any decorator-contract violation the parser reports.
///
/// Returns [LegendGenExit.dirty] when anything was found (warnings
/// included), else [LegendGenExit.success] after printing
/// `no problems found`.
Future<int> runDoctor(List<String> paths, {Logger? logger}) async {
  final log = logger ?? Logger();
  final findings = collectDoctorFindings(paths, logger: log);
  for (final finding in findings) {
    switch (finding.severity) {
      case DoctorSeverity.error:
        log.err('$finding');
      case DoctorSeverity.warning:
        log.warn('$finding');
    }
  }
  if (findings.isEmpty) {
    log.success('no problems found');
    return LegendGenExit.success;
  }
  log.info('${findings.length} problem(s) found');
  return LegendGenExit.dirty;
}

/// The pure core of [runDoctor]: collects findings without printing.
List<DoctorFinding> collectDoctorFindings(
  List<String> paths, {
  Logger? logger,
}) {
  final findings = <DoctorFinding>[];
  void error(String path, int line, String message) => findings.add(
    DoctorFinding(
      DoctorSeverity.error,
      LegendGenDiagnostic(path, line, message),
    ),
  );

  final sources = <File>[];
  final generated = <File>[];
  for (final path in paths) {
    for (final file in _dartFilesIn(path, logger)) {
      if (file.path.endsWith(_generatedSuffix)) {
        generated.add(file);
      } else if (!file.path.endsWith('.g.dart')) {
        sources.add(file);
      }
    }
  }

  // One parse per source file; null marks a decorator-contract violation
  // (reported once as error findings, right here).
  final parsed = <String, List<ThemableWidget>?>{};
  List<ThemableWidget>? widgetsOf(String sourcePath) {
    return parsed.putIfAbsent(sourcePath, () {
      try {
        return parseThemableWidgets(
          sourcePath,
          File(sourcePath).readAsStringSync(),
        );
      } on LegendGenException catch (e) {
        for (final d in e.diagnostics) {
          error(d.path, d.line, d.message);
        }
        return null;
      }
    });
  }

  // (a) missing generated file, (b) stale generated output.
  for (final file in sources) {
    final widgets = widgetsOf(file.path);
    if (widgets == null || widgets.isEmpty) continue;
    final outputPath =
        '${file.path.substring(0, file.path.length - '.dart'.length)}'
        '$_generatedSuffix';
    final outputFile = File(outputPath);
    if (!outputFile.existsSync()) {
      error(
        file.path,
        widgets.first.line,
        '@LegendThemeable "${widgets.first.className}" has no generated '
        'theme file — run `legend_gen themes`.',
      );
    } else if (outputFile.readAsStringSync() != emitThemeFile(widgets)) {
      error(outputPath, 1, 'stale generated output — run `legend_gen themes`.');
    }
  }

  // (c) orphaned generated files, (d) generator version drift.
  for (final file in generated) {
    final sourcePath =
        '${file.path.substring(0, file.path.length - _generatedSuffix.length)}'
        '.dart';
    if (!File(sourcePath).existsSync()) {
      error(
        file.path,
        1,
        'orphaned generated file — ${p.basename(sourcePath)} is gone; '
        'delete it.',
      );
    } else {
      final widgets = widgetsOf(sourcePath);
      if (widgets != null && widgets.isEmpty) {
        error(
          file.path,
          1,
          'orphaned generated file — ${p.basename(sourcePath)} has no '
          '@LegendThemeable widget; delete it or restore the annotation.',
        );
      }
    }

    final lines = file.readAsLinesSync();
    final header = lines.isEmpty ? '' : lines.first;
    final stamped = RegExp(
      r'GENERATED by legend_gen v(\S+)',
    ).firstMatch(header)?.group(1);
    if (stamped != null && stamped != legendGenVersion) {
      findings.add(
        DoctorFinding(
          DoctorSeverity.warning,
          LegendGenDiagnostic(
            file.path,
            1,
            'generated by legend_gen v$stamped, current is '
            'v$legendGenVersion — rerun `legend_gen themes`.',
          ),
        ),
      );
    }
  }

  // (e) version pin: running CLI vs the project's resolved legend_gen.
  if (paths.isNotEmpty) {
    findings.addAll(versionPinFindings(paths.first));
  }

  return findings;
}

/// The R11.4 version-pin check (Serverpod's pin policy: generated output
/// must match the runtime API the project resolves).
///
/// Walks up from [startPath] to the nearest `pubspec.lock` and warns when
///
/// - the project resolves a `legend_gen` version different from the
///   running CLI (`v$legendGenVersion`) — stale global activation or an
///   un-fetched bump; regenerated output would not match the committed
///   files, or
/// - the project resolves `legend_ui` but does not pin `legend_gen` at
///   all — nothing guarantees teammates and CI generate with the same
///   version.
///
/// `legend_gen` and `legend_ui` deliberately do not share a version line
/// (unlike Serverpod's CLI/runtime), so the CLI is *not* compared to the
/// `legend_ui` version for equality; pinning `legend_gen` in the same
/// lockfile that resolves `legend_ui` is what keeps generator and runtime
/// API in agreement.
///
/// Projects with no lockfile, or with neither package resolved, produce
/// no findings — doctor may legitimately run against a bare directory.
List<DoctorFinding> versionPinFindings(String startPath) {
  final lock = _findPubspecLock(p.normalize(p.absolute(startPath)));
  if (lock == null) return const [];
  final content = lock.readAsStringSync();
  final genVersion = lockedVersion(content, 'legend_gen');
  final uiVersion = lockedVersion(content, 'legend_ui');
  if (genVersion == null && uiVersion == null) return const [];

  DoctorFinding warning(String message) => DoctorFinding(
    DoctorSeverity.warning,
    LegendGenDiagnostic(lock.path, 1, message),
  );

  if (genVersion == null) {
    return [
      warning(
        'the project resolves legend_ui v$uiVersion but does not pin '
        'legend_gen — add it as a dev dependency '
        '(`dart pub add --dev legend_gen`) so every machine generates '
        'with the same version.',
      ),
    ];
  }
  if (genVersion != legendGenVersion) {
    return [
      warning(
        'this CLI is legend_gen v$legendGenVersion but the project '
        'resolves v$genVersion — run the pinned version via '
        '`dart run legend_gen`, or align them (`dart pub get` / '
        '`legend_gen update`) so generated output matches the committed '
        'files.',
      ),
    ];
  }
  return const [];
}

/// The `version` of [package] in [lockContent] (a `pubspec.lock` body), or
/// null when the package is not resolved. Line-based on the stable lock
/// layout (2-space package key, 4-space attributes) — no yaml dependency.
String? lockedVersion(String lockContent, String package) {
  return RegExp(
    '^  $package:\\n(?:    .*\\n)*?    version: "([^"]+)"',
    multiLine: true,
  ).firstMatch(lockContent)?.group(1);
}

File? _findPubspecLock(String start) {
  var dir = FileSystemEntity.isDirectorySync(start) ? start : p.dirname(start);
  while (true) {
    final candidate = File(p.join(dir, 'pubspec.lock'));
    if (candidate.existsSync()) return candidate;
    final parent = p.dirname(dir);
    if (parent == dir) return null;
    dir = parent;
  }
}

List<File> _dartFilesIn(String path, Logger? logger) {
  final entity = FileSystemEntity.typeSync(path);
  if (entity == FileSystemEntityType.file) return [File(path)];
  if (entity != FileSystemEntityType.directory) {
    (logger ?? Logger()).warn('$path does not exist, skipping');
    return const [];
  }
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (f) =>
            f.path.endsWith('.dart') && !p.split(f.path).contains('.dart_tool'),
      )
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}
