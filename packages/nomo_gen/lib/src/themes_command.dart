import 'dart:io';

import 'package:nomo_gen/src/emitter.dart';
import 'package:nomo_gen/src/model.dart';
import 'package:nomo_gen/src/parser.dart';
import 'package:path/path.dart' as p;

/// Runs `nomo_gen themes`: scans [paths] for `@NomoThemeable` widgets and
/// writes `<source>.theme.g.dart` next to each source file.
///
/// With [check], nothing is written; stale or missing output makes the run
/// fail — the CI freshness gate (DESIGN.md §5.3).
///
/// Returns the process exit code.
Future<int> runThemes(List<String> paths, {bool check = false}) async {
  var generated = 0;
  var stale = 0;
  final failures = <NomoGenDiagnostic>[];

  for (final path in paths) {
    final files = _dartFilesIn(path);
    for (final file in files) {
      final List<ThemableWidget> widgets;
      try {
        widgets = parseThemableWidgets(file.path, file.readAsStringSync());
      } on NomoGenException catch (e) {
        failures.addAll(e.diagnostics);
        continue;
      }
      if (widgets.isEmpty) continue;

      final output = emitThemeFile(widgets);
      final outputPath =
          '${file.path.substring(0, file.path.length - '.dart'.length)}'
          '.theme.g.dart';
      final outputFile = File(outputPath);

      if (check) {
        final current = outputFile.existsSync()
            ? outputFile.readAsStringSync()
            : null;
        if (current != output) {
          stale++;
          stderr.writeln('STALE: $outputPath (rerun `nomo_gen themes`)');
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
    stdout.writeln('all generated theme files are fresh');
    return 0;
  }
  stdout.writeln('$generated file(s) generated');
  return 0;
}

List<File> _dartFilesIn(String path) {
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
