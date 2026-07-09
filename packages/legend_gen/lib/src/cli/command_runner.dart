import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:legend_gen/src/cli/commands.dart';
import 'package:legend_gen/src/exit_codes.dart';
import 'package:legend_gen/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

/// The `legend_gen` CLI shell (RFC-002 R11): a
/// [CompletionCommandRunner]-based runner in the Serverpod / Dart Frog
/// mold —
///
/// - `package:args` subcommands + `package:mason_logger` output, with
///   global `-v`/`--verbose` (per-file detail) and `-q`/`--quiet`
///   (errors only),
/// - shell completion via `package:cli_completion` (auto-installed once
///   per shell; `install-completion-files` to redo it manually; disabled
///   in CI),
/// - [LegendGenExit] exit-code semantics — bad invocations exit `usage`,
///   internal faults exit `software`, a dirty `--check` exits the distinct
///   `dirty` code (65) that CI gates on,
/// - a post-run, non-blocking "update available" nudge (skipped in CI or
///   when `LEGEND_GEN_SKIP_UPDATE_CHECK` is set; RFC-002 R11.4).
class LegendGenCommandRunner extends CompletionCommandRunner<int> {
  /// Creates the runner; [logger], [pubUpdater], and [environment] are
  /// injectable for tests.
  LegendGenCommandRunner({
    Logger? logger,
    PubUpdater? pubUpdater,
    Map<String, String>? environment,
  }) : cliLogger = logger ?? Logger(),
       _pubUpdater = pubUpdater ?? PubUpdater(),
       _environment = environment ?? Platform.environment,
       super(
         'legend_gen',
         'Legend UI code generation CLI — component theme plumbing, docs '
             'manifests, token members, scaffolding, and setup diagnostics.',
       ) {
    environmentOverride = environment;
    argParser
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the legend_gen version.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Log everything, including per-file generation output.',
      )
      ..addFlag('quiet', abbr: 'q', negatable: false, help: 'Log errors only.');
    addCommand(ThemesCommand(logger: cliLogger));
    addCommand(DocsCommand(logger: cliLogger));
    addCommand(TokensCommand(logger: cliLogger));
    addCommand(CreateCommand(logger: cliLogger));
    addCommand(DoctorCommand(logger: cliLogger));
    addCommand(UpdateCommand(logger: cliLogger, pubUpdater: _pubUpdater));
  }

  /// The logger every command logs through; `-v`/`-q` set its level.
  final Logger cliLogger;

  final PubUpdater _pubUpdater;
  final Map<String, String> _environment;

  /// Commands that must not trigger the update nudge: `update` itself and
  /// the machine-invoked completion plumbing.
  static const _nudgeExempt = {
    'update',
    'completion',
    'install-completion-files',
    'uninstall-completion-files',
  };

  @override
  bool get enableAutoInstall => !_environment.containsKey('CI');

  @override
  String get usageFooter =>
      '\nExit codes: 0 success · 64 usage · 65 --check dirty / doctor '
      'findings · 66 source contract errors · 69 update unavailable · '
      '70 internal fault · 73 create refused to overwrite.';

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      return await runCommand(parse(args)) ?? LegendGenExit.success;
    } on UsageException catch (e) {
      cliLogger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return LegendGenExit.usage;
    } on FormatException catch (e) {
      cliLogger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return LegendGenExit.usage;
      // The process-level backstop (R11.6): anything a command did not
      // classify itself is an internal fault, never a stack-trace crash.
      // ignore: avoid_catches_without_on_clauses
    } catch (error, stackTrace) {
      cliLogger
        ..err(
          'internal legend_gen fault: $error — this is a bug in '
          'legend_gen, please report it.',
        )
        ..detail('$stackTrace');
      return LegendGenExit.software;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.flag('quiet')) cliLogger.level = Level.error;
    if (topLevelResults.flag('verbose')) cliLogger.level = Level.verbose;
    if (topLevelResults.flag('version')) {
      cliLogger.info(legendGenVersion);
      return LegendGenExit.success;
    }
    final exit = await super.runCommand(topLevelResults);
    await _updateNudge(topLevelResults.command?.name);
    return exit;
  }

  /// The post-run version nudge (RFC-002 R11.4): non-blocking (bounded by
  /// a short timeout, failures swallowed), skipped in CI and via
  /// `LEGEND_GEN_SKIP_UPDATE_CHECK`.
  Future<void> _updateNudge(String? commandName) async {
    if (commandName == null || _nudgeExempt.contains(commandName)) return;
    if (_environment.containsKey('CI') ||
        _environment.containsKey('LEGEND_GEN_SKIP_UPDATE_CHECK')) {
      return;
    }
    const timeout = Duration(seconds: 2);
    try {
      final upToDate = await _pubUpdater
          .isUpToDate(
            packageName: UpdateCommand.packageName,
            currentVersion: legendGenVersion,
          )
          .timeout(timeout);
      if (upToDate) return;
      final latest = await _pubUpdater
          .getLatestVersion(UpdateCommand.packageName)
          .timeout(timeout);
      cliLogger
        ..info('')
        ..info(
          'Update available: legend_gen $legendGenVersion → $latest — run '
          '`legend_gen update`. '
          '(Set LEGEND_GEN_SKIP_UPDATE_CHECK to silence this check.)',
        );
    } on Exception {
      // Never block or fail a run because pub.dev is unreachable.
    }
  }
}
