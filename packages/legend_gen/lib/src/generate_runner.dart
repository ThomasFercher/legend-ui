import 'dart:io';

import 'package:legend_gen/src/exit_codes.dart';
import 'package:legend_gen/src/model.dart';
import 'package:legend_gen/src/parser.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// Shared one-file-in/one-file-out driver behind `legend_gen themes`,
/// `legend_gen docs`, and `legend_gen tokens`: scans [paths], runs [parse]
/// then [emit] per source file, and writes `<source><suffix>` next to it.
///
/// [parse] returns the annotated declarations of one source file (empty
/// when the file declares none) and throws [LegendGenException] on
/// contract violations.
///
/// Guarantees relied on by watch mode (RFC-002 R11.2):
///
/// - **No write on error.** Output is written only after a clean parse and
///   emit — a source file that fails the contract never truncates, deletes,
///   or corrupts its last good generated output.
/// - **No write when unchanged.** Identical output is left untouched, so
///   downstream watchers (IDEs, `flutter run`) see no spurious changes.
///
/// With [check], nothing is written; stale or missing output makes the run
/// fail — the CI freshness gate (DESIGN.md §5.3).
///
/// Returns a [LegendGenExit] process exit code: [LegendGenExit.sourceError]
/// on contract diagnostics, [LegendGenExit.dirty] on a dirty `--check`,
/// else [LegendGenExit.success]. Progress goes through [logger]
/// (per-file lines at detail level — visible with `-v`).
Future<int> runGeneration<T>(
  List<String> paths, {
  required String suffix,
  required String label,
  required String command,
  required List<T> Function(String path, String content) parse,
  required String Function(List<T> declarations) emit,
  bool check = false,
  Logger? logger,
}) async {
  final log = logger ?? Logger();
  var written = 0;
  var unchanged = 0;
  final stale = <String>[];
  final failures = <LegendGenDiagnostic>[];
  final perFile = <String>[];

  final progress = log.progress(
    check ? 'Checking $label freshness' : 'Generating $label files',
  );

  for (final path in paths) {
    for (final file in sourceDartFilesIn(path, logger: log)) {
      final List<T> declarations;
      try {
        declarations = parse(file.path, file.readAsStringSync());
      } on LegendGenException catch (e) {
        failures.addAll(e.diagnostics);
        continue;
      }
      if (declarations.isEmpty) continue;

      final output = emit(declarations);
      final outputPath =
          '${file.path.substring(0, file.path.length - '.dart'.length)}'
          '$suffix';
      final outputFile = File(outputPath);
      final current = outputFile.existsSync()
          ? outputFile.readAsStringSync()
          : null;

      if (check) {
        if (current != output) stale.add(outputPath);
      } else if (current == output) {
        unchanged++;
        perFile.add('unchanged $outputPath');
      } else {
        outputFile.writeAsStringSync(output);
        written++;
        perFile.add('generated $outputPath');
      }
    }
  }

  final counts =
      '$written $label file(s) generated'
      '${unchanged > 0 ? ', $unchanged unchanged' : ''}';

  if (failures.isNotEmpty) {
    progress.fail(
      '${failures.length} $label error(s)'
      '${check ? '' : ' — kept the last good generated output ($counts)'}',
    );
    perFile.forEach(log.detail);
    for (final failure in failures) {
      log.err('$failure');
    }
    return LegendGenExit.sourceError;
  }
  if (check) {
    if (stale.isNotEmpty) {
      progress.fail('${stale.length} stale $label file(s)');
      for (final path in stale) {
        log.err('STALE: $path — rerun `legend_gen $command` and commit.');
      }
      return LegendGenExit.dirty;
    }
    progress.complete('all generated $label files are fresh');
    return LegendGenExit.success;
  }
  progress.complete(counts);
  perFile.forEach(log.detail);
  return LegendGenExit.success;
}

/// The worse of two `LegendGenExit` codes — combining multi-pass commands
/// (`themes` runs styles + themes): source errors beat a dirty `--check`,
/// which beats success. The numeric codes are ordered accordingly
/// (0 < 65 dirty < 66 sourceError < 70 software), so max is exact.
int worseExit(int a, int b) => a > b ? a : b;

/// Builds the run's style-class index (RFC-002 R6 amendment 7): declared
/// class name → parsed [StyleClass], from every source file under [paths]
/// plus the kit's compiled-in [builtinStyleClasses] (same-run declarations
/// win on a clash).
///
/// This is the *detection* half of "a field whose type resolves to an
/// `@Style()`-annotated class gets member-wise treatment": the same
/// pure-AST scan generation performs anyway, shared across the run —
/// emission stays strictly one-file-in/one-file-out, and the parser stays
/// synchronous and resolution-free (no analysis context, no on-disk
/// package config — the properties the never-crash watch loop and the
/// in-memory test fixtures rely on). Contract violations are *not*
/// reported here — a broken style class fails its own file's styles pass;
/// the index simply omits it.
Map<String, StyleClass> buildStyleClassIndex(
  List<String> paths, {
  Logger? logger,
}) {
  final index = {...builtinStyleClasses};
  for (final path in paths) {
    for (final file in sourceDartFilesIn(path, logger: logger)) {
      final (classes, _) = collectStyleClasses(
        file.path,
        file.readAsStringSync(),
      );
      for (final styleClass in classes) {
        index[styleClass.className] = styleClass;
      }
    }
  }
  return index;
}

/// All non-generated `.dart` source files under [path] (a file or a
/// directory), sorted for deterministic output order.
List<File> sourceDartFilesIn(String path, {Logger? logger}) {
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
            f.path.endsWith('.dart') &&
            !f.path.endsWith('.g.dart') &&
            !p.split(f.path).contains('.dart_tool'),
      )
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}
