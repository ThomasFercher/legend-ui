import 'dart:io';

import 'package:legend_gen/src/model.dart';
import 'package:path/path.dart' as p;

/// Shared one-file-in/one-file-out driver behind `legend_gen themes`,
/// `legend_gen docs`, and `legend_gen tokens`: scans [paths], runs [parse]
/// then [emit] per source file, and writes `<source><suffix>` next to it.
///
/// [parse] returns the annotated declarations of one source file (empty
/// when the file declares none) and throws [LegendGenException] on
/// contract violations.
///
/// With [check], nothing is written; stale or missing output makes the run
/// fail — the CI freshness gate (DESIGN.md §5.3).
///
/// Returns the process exit code.
Future<int> runGeneration<T>(
  List<String> paths, {
  required String suffix,
  required String label,
  required String command,
  required List<T> Function(String path, String content) parse,
  required String Function(List<T> declarations) emit,
  bool check = false,
}) async {
  var generated = 0;
  var stale = 0;
  final failures = <LegendGenDiagnostic>[];

  for (final path in paths) {
    final files = sourceDartFilesIn(path);
    for (final file in files) {
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

      if (check) {
        final current = outputFile.existsSync()
            ? outputFile.readAsStringSync()
            : null;
        if (current != output) {
          stale++;
          stderr.writeln('STALE: $outputPath (rerun `legend_gen $command`)');
        }
      } else {
        outputFile.writeAsStringSync(output);
        generated++;
        stdout.writeln('generated $outputPath');
      }
    }
  }

  for (final failure in failures) {
    stderr.writeln('ERROR: $failure');
  }
  if (failures.isNotEmpty) return 2;
  if (check) {
    if (stale > 0) return 1;
    stdout.writeln('all generated $label files are fresh');
    return 0;
  }
  stdout.writeln('$generated file(s) generated');
  return 0;
}

/// All non-generated `.dart` source files under [path] (a file or a
/// directory), sorted for deterministic output order.
List<File> sourceDartFilesIn(String path) {
  final entity = FileSystemEntity.typeSync(path);
  if (entity == FileSystemEntityType.file) return [File(path)];
  if (entity != FileSystemEntityType.directory) {
    stderr.writeln('WARNING: $path does not exist, skipping');
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
