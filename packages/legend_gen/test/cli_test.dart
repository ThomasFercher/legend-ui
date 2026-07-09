import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:legend_gen/legend_gen.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:process/process.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

/// Manual fake — [PubUpdater]'s surface is three methods; no network.
class _FakePubUpdater implements PubUpdater {
  _FakePubUpdater({
    this.latest = legendGenVersion,
    this.failNetwork = false,
    this.failUpdate = false,
  });

  final String latest;
  final bool failNetwork;

  /// When true, only [update] fails (reaching pub.dev worked).
  final bool failUpdate;
  int updateCalls = 0;

  @override
  Future<String> getLatestVersion(String packageName) async {
    if (failNetwork) throw PackageInfoRequestFailure();
    return latest;
  }

  @override
  Future<bool> isUpToDate({
    required String packageName,
    required String currentVersion,
  }) async {
    if (failNetwork) throw PackageInfoRequestFailure();
    return currentVersion == latest;
  }

  @override
  Future<ProcessResult> update({
    required String packageName,
    ProcessManager processManager = const LocalProcessManager(),
    String? versionConstraint,
  }) async {
    if (failUpdate) throw PackageInfoRequestFailure();
    updateCalls++;
    return ProcessResult(0, 0, '', '');
  }
}

/// A command that models an internal generator fault.
class _BoomCommand extends Command<int> {
  @override
  String get name => 'boom';

  @override
  String get description => 'throws an internal fault';

  @override
  Future<int> run() async => throw StateError('kaboom');
}

const _goodWidget = '''
import 'package:legend_ui/legend_ui.dart';

part 'cool_box.theme.g.dart';

@LegendThemeable()
class CoolBox {
  const CoolBox({this.background});

  /// Fill behind the child.
  @Style<Color>.resolve(_background, lerp: true)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.surface;
}
''';

const _badWidget = '''
import 'package:legend_ui/legend_ui.dart';

part 'bad_box.theme.g.dart';

@LegendThemeable()
class BadBox {
  const BadBox({required this.background});

  @Style<Color>.resolve(_background)
  final Color background;
  static Color _background(LegendTokens t) => t.colors.surface;
}
''';

void main() {
  late Directory tmp;
  late _MockLogger logger;
  late _FakePubUpdater pubUpdater;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('legend_gen_cli_');
    logger = _MockLogger();
    when(() => logger.progress(any())).thenReturn(_MockProgress());
    pubUpdater = _FakePubUpdater();
  });

  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  LegendGenCommandRunner runner({Map<String, String> environment = const {}}) {
    return LegendGenCommandRunner(
      logger: logger,
      pubUpdater: pubUpdater,
      environment: environment,
    );
  }

  String write(String name, String content) {
    final file = File(p.join(tmp.path, name))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
    return file.path;
  }

  group('invocation and global flags', () {
    test('--version prints the version and exits 0', () async {
      expect(await runner().run(['--version']), LegendGenExit.success);
      verify(() => logger.info(legendGenVersion)).called(1);
    });

    test('an unknown command exits usage (64)', () async {
      expect(await runner().run(['frobnicate']), LegendGenExit.usage);
      verify(() => logger.err(any(that: contains('frobnicate')))).called(1);
    });

    test('an unknown flag exits usage (64)', () async {
      expect(
        await runner().run(['themes', '--nope', tmp.path]),
        LegendGenExit.usage,
      );
    });

    test('--check with --watch exits usage (64)', () async {
      expect(
        await runner().run(['themes', '--check', '--watch', tmp.path]),
        LegendGenExit.usage,
      );
      verify(
        () => logger.err(any(that: contains('mutually exclusive'))),
      ).called(1);
    });

    test('create without a class name exits usage (64)', () async {
      expect(await runner().run(['create']), LegendGenExit.usage);
    });

    test('the usage footer documents the exit-code taxonomy', () {
      expect(
        runner().usageFooter,
        allOf(contains('--check dirty'), contains('65'), contains('70')),
      );
    });
  });

  group('exit codes (RFC-002 R11.1)', () {
    test(
      'a dirty --check exits the distinct dirty code 65 (ExitCode.data)',
      () async {
        write('cool_box.dart', _goodWidget);
        final code = await runner().run(['themes', '--check', tmp.path]);
        expect(code, ExitCode.data.code);
        expect(code, 65);
        expect(code, LegendGenExit.dirty);
      },
    );

    test('a fresh --check exits 0', () async {
      write('cool_box.dart', _goodWidget);
      expect(await runner().run(['themes', tmp.path]), LegendGenExit.success);
      expect(
        await runner().run(['themes', '--check', tmp.path]),
        LegendGenExit.success,
      );
    });

    test(
      'contract violations exit sourceError (66) with a named fix',
      () async {
        write('bad_box.dart', _badWidget);
        expect(
          await runner().run(['themes', tmp.path]),
          LegendGenExit.sourceError,
        );
        verify(
          () => logger.err(any(that: contains('must be nullable'))),
        ).called(1);
      },
    );

    test('create refuses to overwrite with cantCreate (73)', () async {
      write('legend_badge.dart', '// hands off\n');
      expect(
        await runner().run(['create', 'LegendBadge', '--dir', tmp.path]),
        LegendGenExit.cantCreate,
      );
    });

    test('doctor findings exit dirty (65)', () async {
      write('cool_box.dart', _goodWidget); // no generated file yet
      expect(await runner().run(['doctor', tmp.path]), LegendGenExit.dirty);
    });

    test('an internal fault exits software (70), never a crash', () async {
      final r = runner()..addCommand(_BoomCommand());
      expect(await r.run(['boom']), LegendGenExit.software);
      verify(
        () => logger.err(any(that: contains('internal legend_gen fault'))),
      ).called(1);
    });
  });

  group('legend_gen update (RFC-002 R11.4)', () {
    test('already at the latest version: no activate call, exit 0', () async {
      expect(await runner().run(['update']), LegendGenExit.success);
      expect(pubUpdater.updateCalls, 0);
    });

    test('newer version available: activates it and exits 0', () async {
      pubUpdater = _FakePubUpdater(latest: '99.0.0');
      expect(await runner().run(['update']), LegendGenExit.success);
      expect(pubUpdater.updateCalls, 1);
    });

    test(
      'pub.dev unreachable: exits unavailable (69) naming the retry',
      () async {
        pubUpdater = _FakePubUpdater(failNetwork: true);
        expect(await runner().run(['update']), LegendGenExit.unavailable);
      },
    );

    test('a failing activate exits unavailable (69)', () async {
      pubUpdater = _FakePubUpdater(latest: '99.0.0', failUpdate: true);
      expect(await runner().run(['update']), LegendGenExit.unavailable);
    });
  });

  group('post-run version nudge (RFC-002 R11.4)', () {
    test('nudges when a newer version exists', () async {
      pubUpdater = _FakePubUpdater(latest: '99.0.0');
      expect(await runner().run(['doctor', tmp.path]), LegendGenExit.success);
      verify(
        () => logger.info(any(that: contains('Update available'))),
      ).called(1);
    });

    test('silent when up to date', () async {
      await runner().run(['doctor', tmp.path]);
      verifyNever(() => logger.info(any(that: contains('Update available'))));
    });

    test('auto-off in CI via env detection', () async {
      pubUpdater = _FakePubUpdater(latest: '99.0.0');
      await runner(environment: {'CI': 'true'}).run(['doctor', tmp.path]);
      verifyNever(() => logger.info(any(that: contains('Update available'))));
    });

    test('skippable via LEGEND_GEN_SKIP_UPDATE_CHECK', () async {
      pubUpdater = _FakePubUpdater(latest: '99.0.0');
      await runner(
        environment: {'LEGEND_GEN_SKIP_UPDATE_CHECK': '1'},
      ).run(['doctor', tmp.path]);
      verifyNever(() => logger.info(any(that: contains('Update available'))));
    });

    test('never fails or blocks the run when pub.dev is unreachable', () async {
      pubUpdater = _FakePubUpdater(failNetwork: true);
      expect(await runner().run(['doctor', tmp.path]), LegendGenExit.success);
    });

    test('never nudges after `update` itself', () async {
      pubUpdater = _FakePubUpdater(latest: '99.0.0');
      await runner().run(['update']);
      verifyNever(() => logger.info(any(that: contains('Update available'))));
    });
  });

  group('shell completion (RFC-002 R11.5)', () {
    test('the completion plumbing commands are installed', () {
      final commands = runner().commands.keys;
      expect(commands, contains('completion'));
      expect(commands, contains('install-completion-files'));
      expect(commands, contains('uninstall-completion-files'));
    });

    test('auto-install is disabled in CI', () {
      expect(runner().enableAutoInstall, isTrue);
      expect(runner(environment: {'CI': 'true'}).enableAutoInstall, isFalse);
    });
  });
}
