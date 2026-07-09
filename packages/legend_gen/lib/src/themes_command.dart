import 'dart:async';
import 'dart:io';

import 'package:legend_gen/src/emitter.dart';
import 'package:legend_gen/src/generate_runner.dart';

/// Runs `legend_gen themes`: scans [paths] for `@LegendThemeable` widgets and
/// writes `<source>.theme.g.dart` — a `part` of the widget's library
/// (RFC-002 R1) — next to each source file.
///
/// With [check], nothing is written; stale or missing output makes the run
/// fail — the CI freshness gate (DESIGN.md §5.3).
///
/// Returns the process exit code.
Future<int> runThemes(List<String> paths, {bool check = false}) {
  return runGeneration(
    paths,
    suffix: '.theme.g.dart',
    label: 'theme',
    command: 'themes',
    emit: emitThemeFile,
    check: check,
  );
}

/// Runs `legend_gen themes --watch`: initial full pass, then regenerates a
/// source file whenever it changes. Blocks until SIGINT.
Future<int> runThemesWatch(List<String> paths) async {
  await runThemes(paths);
  final directories = paths.where(
    (p) => FileSystemEntity.typeSync(p) == FileSystemEntityType.directory,
  );
  final subscriptions = <StreamSubscription<FileSystemEvent>>[];
  for (final path in directories) {
    subscriptions.add(
      Directory(path).watch(recursive: true).listen((event) {
        final changed = event.path;
        if (!changed.endsWith('.dart') ||
            changed.endsWith('.g.dart') ||
            event is FileSystemDeleteEvent) {
          return;
        }
        // Atomic saves/renames can race the read — never kill the watch.
        unawaited(
          runThemes([changed]).catchError((Object e) {
            stderr.writeln('watch: $changed: $e');
            return 1;
          }),
        );
      }),
    );
  }
  stdout.writeln('watching ${directories.join(', ')} — Ctrl-C to stop');
  await ProcessSignal.sigint.watch().first;
  for (final subscription in subscriptions) {
    await subscription.cancel();
  }
  return 0;
}
