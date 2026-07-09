import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:legend_gen/src/exit_codes.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:watcher/watcher.dart';

/// Creates the [Watcher] for one watched directory — injectable so tests
/// can drive the loop with synthetic [WatchEvent]s.
typedef WatcherFactory = Watcher Function(String directory);

/// The `--watch` loop shared by `themes`, `docs`, and `tokens`
/// (RFC-002 R11.2, the Dart Frog shape): one initial full pass over
/// [paths], then regenerate **only the changed files** on every save,
/// batched behind a [debounce] window, until [until] completes
/// (Ctrl-C by default).
///
/// Guarantees:
///
/// - **Never exits on a source error.** Decorator-contract violations are
///   printed as `file:line` diagnostics and the loop keeps watching; the
///   last good generated output stays on disk untouched (the generation
///   core never writes after a failed parse — see `runGeneration`).
/// - **Only internal faults exit**, with [LegendGenExit.software] — a
///   crash inside the generator is a bug, not something a rebuild-on-save
///   loop can recover from.
/// - Events are debounced and deduplicated: an editor's save burst
///   (atomic rename + modify) becomes one regeneration batch.
/// - Generated (`*.g.dart`), non-Dart, and delete events are ignored, so
///   the loop never feeds on its own output.
///
/// [generate] is the wrapped core (e.g. `runThemes` without `--check`);
/// it receives only the changed paths — one-file-in/one-file-out makes
/// incremental regeneration exact (DESIGN.md §5.3). [onBatch] observes
/// every completed batch with its exit code, and [onReady] fires once the
/// initial pass is done and the watchers are live (both used by tests;
/// also handy for logging).
///
/// Returns [LegendGenExit.success] when stopped via [until]/Ctrl-C,
/// [LegendGenExit.usage] when [paths] contains no directory to watch, or
/// [LegendGenExit.software] on an internal fault.
Future<int> watchGeneration(
  List<String> paths, {
  required String label,
  required Future<int> Function(List<String> changedPaths) generate,
  Logger? logger,
  Duration debounce = const Duration(milliseconds: 150),
  WatcherFactory? createWatcher,
  Future<Object?>? until,
  void Function(List<String> batch, int exitCode)? onBatch,
  void Function()? onReady,
}) async {
  final log = logger ?? Logger();
  final newWatcher = createWatcher ?? DirectoryWatcher.new;

  // Initial full pass. Source errors are recoverable — report, keep the
  // last good output, and watch for the fixing save.
  final initial = await _guarded(() => generate(paths), log);
  if (initial == LegendGenExit.software) return initial;

  final directories = paths
      .where(
        (path) =>
            FileSystemEntity.typeSync(path) == FileSystemEntityType.directory,
      )
      .toList();
  for (final path in paths.where((path) => !directories.contains(path))) {
    log.warn('not a directory, not watching: $path');
  }
  if (directories.isEmpty) {
    log.err('nothing to watch — pass at least one directory.');
    return LegendGenExit.usage;
  }

  final done = Completer<int>();
  final pending = SplayTreeSet<String>();
  var queue = Future<void>.value();
  Timer? timer;

  void flush() {
    final batch = pending.toList();
    pending.clear();
    if (batch.isEmpty) return;
    // Serialize batches: a save burst during a slow regeneration queues up
    // instead of racing it.
    queue = queue.then((_) async {
      if (done.isCompleted) return;
      final code = await _guarded(() => generate(batch), log);
      if (code == LegendGenExit.sourceError) {
        log.info(
          'kept the last good generated output — fix the error(s) above '
          'and save again.',
        );
      }
      onBatch?.call(batch, code);
      if (code == LegendGenExit.software && !done.isCompleted) {
        done.complete(code);
      }
    });
  }

  void onEvent(WatchEvent event) {
    if (event.type == ChangeType.REMOVE) return;
    final changed = event.path;
    if (!changed.endsWith('.dart') || changed.endsWith('.g.dart')) return;
    pending.add(changed);
    timer?.cancel();
    timer = Timer(debounce, flush);
  }

  final subscriptions = <StreamSubscription<WatchEvent>>[
    for (final directory in directories)
      newWatcher(directory).events.listen(
        onEvent,
        // A watcher stream error (a directory vanishing mid-scan, an
        // exhausted inotify budget) is environmental, not a legend_gen
        // bug: report it and keep the remaining watchers alive.
        onError: (Object error) => log.warn('watcher: $error'),
      ),
  ];

  log.info('watching ${directories.join(', ')} — Ctrl-C to stop');
  onReady?.call();
  final stop = until ?? ProcessSignal.sigint.watch().first;
  unawaited(
    stop.then((_) {
      if (!done.isCompleted) done.complete(LegendGenExit.success);
    }),
  );

  final code = await done.future;
  timer?.cancel();
  for (final subscription in subscriptions) {
    await subscription.cancel();
  }
  // Let an in-flight batch settle before returning, so nothing writes
  // after the loop reports itself stopped.
  await queue;
  return code;
}

/// Classifies failures out of one generation run (RFC-002 R11.6):
/// recoverable environment races keep the watch alive as
/// [LegendGenExit.sourceError]; anything unexpected is an internal fault
/// ([LegendGenExit.software]). Contract violations never reach here —
/// `runGeneration` already converts them to diagnostics + exit code.
Future<int> _guarded(Future<int> Function() run, Logger log) async {
  try {
    return await run();
  } on FileSystemException catch (e) {
    // Atomic saves/renames can delete the file between the event and our
    // read — recoverable; the next save retries.
    log.warn(
      'file system race: ${e.message} ${e.path ?? ''} — will retry on the '
      'next save.',
    );
    return LegendGenExit.sourceError;
    // The watch loop must never crash on a generator fault (R11.2); it
    // classifies and exits `software` deliberately.
    // ignore: avoid_catches_without_on_clauses
  } catch (error, stackTrace) {
    log
      ..err(
        'internal legend_gen fault: $error — this is a bug in legend_gen, '
        'please report it.',
      )
      ..detail('$stackTrace');
    return LegendGenExit.software;
  }
}
