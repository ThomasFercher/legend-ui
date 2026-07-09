import 'dart:async';
import 'dart:io';

import 'package:legend_gen/legend_gen.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

/// Drives [watchGeneration] with synthetic events — no real file-system
/// watcher, no timing flakiness.
class _FakeWatcher implements Watcher {
  _FakeWatcher(this.path);

  @override
  final String path;

  final controller = StreamController<WatchEvent>.broadcast();

  @override
  Stream<WatchEvent> get events => controller.stream;

  @override
  bool get isReady => true;

  @override
  Future<void> get ready async {}
}

String _widget(String className, String basename, {bool lerp = true}) =>
    '''
import 'package:legend_ui/legend_ui.dart';

part '$basename.theme.g.dart';

@LegendThemeable()
class $className {
  const $className({this.background});

  /// Fill behind the child.
  @Style<Color>.resolve(_background, lerp: $lerp)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.surface;
}
''';

String _brokenWidget(String className, String basename) =>
    '''
import 'package:legend_ui/legend_ui.dart';

part '$basename.theme.g.dart';

@LegendThemeable()
class $className {
  const $className({required this.background});

  @Style<Color>.resolve(_background)
  final Color background;
  static Color _background(LegendTokens t) => t.colors.surface;
}
''';

void main() {
  late Directory tmp;
  late _FakeWatcher watcher;
  late Completer<void> stop;
  late Completer<void> ready;
  late StreamController<(List<String>, int)> batchCtrl;
  late StreamIterator<(List<String>, int)> batches;
  final quiet = Logger(level: Level.quiet);

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('legend_gen_watch_');
    watcher = _FakeWatcher(tmp.path);
    stop = Completer<void>();
    ready = Completer<void>();
    batchCtrl = StreamController<(List<String>, int)>();
    batches = StreamIterator(batchCtrl.stream);
  });

  tearDown(() async {
    await batches.cancel();
    // Not awaited: a single-subscription controller's close() future only
    // completes once a listener has consumed the done event, which never
    // happens in tests that finished without draining the stream.
    unawaited(batchCtrl.close());
    tmp.deleteSync(recursive: true);
  });

  String write(String name, String content) {
    final file = File(p.join(tmp.path, name))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
    return file.path;
  }

  /// Starts the loop; the returned future completes only via [stop] or an
  /// internal fault. Await [ready] before sending events.
  Future<int> startWatch({Future<int> Function(List<String> paths)? generate}) {
    return watchGeneration(
      [tmp.path],
      label: 'theme',
      logger: quiet,
      debounce: const Duration(milliseconds: 30),
      generate: generate ?? (paths) => runThemes(paths, logger: quiet),
      createWatcher: (_) => watcher,
      until: stop.future,
      onBatch: (batch, code) => batchCtrl.add((batch, code)),
      onReady: ready.complete,
    );
  }

  Future<(List<String>, int)> nextBatch() async {
    final has = await batches.moveNext().timeout(const Duration(seconds: 10));
    expect(has, isTrue, reason: 'expected another watch batch');
    return batches.current;
  }

  test('initial full pass, then regenerates only the changed file', () async {
    final a = write('box_a.dart', _widget('BoxA', 'box_a'));
    write('box_b.dart', _widget('BoxB', 'box_b'));

    final run = startWatch();
    await ready.future;

    // The initial pass generated both.
    final generatedA = File(p.join(tmp.path, 'box_a.theme.g.dart'));
    final generatedB = File(p.join(tmp.path, 'box_b.theme.g.dart'));
    expect(generatedA.existsSync(), isTrue);
    expect(generatedB.existsSync(), isTrue);
    final initialA = generatedA.readAsStringSync();
    final initialB = generatedB.readAsStringSync();

    // Edit only box_a (flip the lerp flag → different generated output).
    write('box_a.dart', _widget('BoxA', 'box_a', lerp: false));
    watcher.controller.add(WatchEvent(ChangeType.MODIFY, a));

    final (batch, code) = await nextBatch();
    expect(batch, [a], reason: 'only the changed file regenerates');
    expect(code, LegendGenExit.success);
    expect(generatedA.readAsStringSync(), isNot(initialA));
    expect(generatedB.readAsStringSync(), initialB);

    stop.complete();
    expect(await run, LegendGenExit.success);
  });

  test('debounce batches a save burst into one deduplicated run', () async {
    final a = write('box_a.dart', _widget('BoxA', 'box_a'));
    final b = write('box_b.dart', _widget('BoxB', 'box_b'));

    final run = startWatch();
    await ready.future;
    watcher.controller
      ..add(WatchEvent(ChangeType.MODIFY, a))
      ..add(WatchEvent(ChangeType.MODIFY, b))
      ..add(WatchEvent(ChangeType.MODIFY, a)); // duplicate within the window

    final (batch, code) = await nextBatch();
    expect(batch, [a, b], reason: 'one sorted, deduplicated batch');
    expect(code, LegendGenExit.success);

    stop.complete();
    expect(await run, LegendGenExit.success);
  });

  test('a contract error never stops the watch and keeps the last good '
      'output on disk', () async {
    final a = write('box_a.dart', _widget('BoxA', 'box_a'));

    final run = startWatch();
    await ready.future;
    final generated = File(p.join(tmp.path, 'box_a.theme.g.dart'));
    final lastGood = generated.readAsStringSync();

    // Break the source: recoverable diagnostics, watch stays alive,
    // generated output untouched.
    write('box_a.dart', _brokenWidget('BoxA', 'box_a'));
    watcher.controller.add(WatchEvent(ChangeType.MODIFY, a));
    final (_, brokenCode) = await nextBatch();
    expect(brokenCode, LegendGenExit.sourceError);
    expect(
      generated.readAsStringSync(),
      lastGood,
      reason:
          'a failing save must not truncate or delete the last '
          'good generated output',
    );

    // Fix it on the next save: the loop is still watching and rebuilds.
    write('box_a.dart', _widget('BoxA', 'box_a', lerp: false));
    watcher.controller.add(WatchEvent(ChangeType.MODIFY, a));
    final (_, fixedCode) = await nextBatch();
    expect(fixedCode, LegendGenExit.success);
    expect(generated.readAsStringSync(), isNot(lastGood));

    stop.complete();
    expect(await run, LegendGenExit.success);
  });

  test('generated, non-Dart, and delete events are ignored', () async {
    final a = write('box_a.dart', _widget('BoxA', 'box_a'));

    final run = startWatch();
    await ready.future;
    watcher.controller
      ..add(
        WatchEvent(ChangeType.MODIFY, p.join(tmp.path, 'box_a.theme.g.dart')),
      )
      ..add(WatchEvent(ChangeType.MODIFY, p.join(tmp.path, 'notes.txt')))
      ..add(WatchEvent(ChangeType.REMOVE, a))
      // The only event that may regenerate:
      ..add(WatchEvent(ChangeType.MODIFY, a));

    final (batch, _) = await nextBatch();
    expect(batch, [a], reason: 'ignored events must not enter the batch');

    stop.complete();
    expect(await run, LegendGenExit.success);
  });

  test(
    'an internal fault during the initial pass exits software (70)',
    () async {
      expect(
        await startWatch(generate: (_) async => throw StateError('boom')),
        LegendGenExit.software,
      );
    },
  );

  test('an internal fault mid-watch exits software (70)', () async {
    write('box_a.dart', _widget('BoxA', 'box_a'));
    var calls = 0;
    final run = startWatch(
      generate: (paths) async {
        calls++;
        if (calls > 1) throw StateError('boom');
        return LegendGenExit.success;
      },
    );
    await ready.future;

    watcher.controller.add(
      WatchEvent(ChangeType.MODIFY, p.join(tmp.path, 'box_a.dart')),
    );
    // The loop classifies the fault and exits without `until` completing.
    expect(
      await run.timeout(const Duration(seconds: 10)),
      LegendGenExit.software,
    );
  });

  test('nothing to watch exits usage (64)', () async {
    expect(
      await watchGeneration(
        [p.join(tmp.path, 'does_not_exist')],
        label: 'theme',
        logger: quiet,
        generate: (paths) => runThemes(paths, logger: quiet),
        createWatcher: (_) => watcher,
        until: stop.future,
      ),
      LegendGenExit.usage,
    );
  });
}
