import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:legend_gen/src/create_command.dart';
import 'package:legend_gen/src/docs_command.dart';
import 'package:legend_gen/src/doctor_command.dart';
import 'package:legend_gen/src/exit_codes.dart';
import 'package:legend_gen/src/themes_command.dart';
import 'package:legend_gen/src/tokens_command.dart';
import 'package:legend_gen/src/version.dart';
import 'package:legend_gen/src/watch.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

/// Shared shell of `themes` / `docs` / `tokens` (RFC-002 R11.1): positional
/// source paths (default `lib`), `--check` (the CI freshness gate, exit
/// [LegendGenExit.dirty] when stale) and `--watch` (the R11.2 loop —
/// see [watchGeneration]).
abstract class GenerationCommand extends Command<int> {
  /// Wires the shared `--check`/`--watch` flags onto [logger]-driven runs.
  GenerationCommand({required Logger logger}) : cliLogger = logger {
    argParser
      ..addFlag(
        'check',
        negatable: false,
        help:
            'Verify committed output is fresh instead of writing; exits '
            '${LegendGenExit.dirty} when stale or missing (the CI gate).',
      )
      ..addFlag(
        'watch',
        negatable: false,
        help:
            'Regenerate changed files on save until Ctrl-C; source errors '
            'never stop the watch.',
      );
  }

  /// The CLI logger (honors the global `-v`/`-q`).
  final Logger cliLogger;

  /// Human label for progress lines ('theme', 'docs', 'token').
  String get label;

  /// The wrapped generation core (e.g. `runThemes`).
  Future<int> generate(List<String> paths, {required bool check});

  @override
  String get invocation => 'legend_gen $name [paths…]';

  @override
  Future<int> run() async {
    final results = argResults!;
    final check = results.flag('check');
    final watch = results.flag('watch');
    if (check && watch) {
      usageException('--watch and --check are mutually exclusive.');
    }
    final paths = results.rest.isEmpty ? const ['lib'] : results.rest;
    if (watch) {
      return watchGeneration(
        paths,
        label: label,
        logger: cliLogger,
        generate: (changed) => generate(changed, check: false),
      );
    }
    return generate(paths, check: check);
  }
}

/// `legend_gen themes` — the component-theme plumbing generator.
class ThemesCommand extends GenerationCommand {
  /// Creates the command on the shared CLI [logger].
  ThemesCommand({required super.logger});

  @override
  String get name => 'themes';

  @override
  String get description =>
      'Generate *.theme.g.dart (a part of the widget library) from '
      '@LegendThemeable widgets.';

  @override
  String get label => 'theme';

  @override
  Future<int> generate(List<String> paths, {required bool check}) =>
      runThemes(paths, check: check, logger: cliLogger);
}

/// `legend_gen docs` — the docs-manifest generator (RFC-002 R9).
class DocsCommand extends GenerationCommand {
  /// Creates the command on the shared CLI [logger].
  DocsCommand({required super.logger});

  @override
  String get name => 'docs';

  @override
  String get description =>
      'Generate *.docs.g.dart manifests (a const List<LegendDocEntry> per '
      'widget) from the same @LegendThemeable annotations.';

  @override
  String get label => 'docs';

  @override
  Future<int> generate(List<String> paths, {required bool check}) =>
      runDocs(paths, check: check, logger: cliLogger);
}

/// `legend_gen tokens` — the token-class mechanical-member generator
/// (RFC-002 R5).
class TokensCommand extends GenerationCommand {
  /// Creates the command on the shared CLI [logger].
  TokensCommand({required super.logger});

  @override
  String get name => 'tokens';

  @override
  String get description =>
      'Generate *.tokens.g.dart (copyWith, lerp, value ==) from '
      '@LegendTokenData token classes.';

  @override
  String get label => 'token';

  @override
  Future<int> generate(List<String> paths, {required bool check}) =>
      runTokens(paths, check: check, logger: cliLogger);
}

/// `legend_gen create <ClassName>` — scaffolds an annotated component from
/// the compiled-in template and generates its theme + docs files.
class CreateCommand extends Command<int> {
  /// Creates the command on the shared CLI [logger].
  CreateCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'dir',
      help: 'Target directory (default: lib/src/components/<name>/).',
    );
  }

  final Logger _logger;

  @override
  String get name => 'create';

  @override
  String get description =>
      'Scaffold an annotated component and generate its theme file and '
      'docs manifest.';

  @override
  String get invocation => 'legend_gen create <ClassName>';

  @override
  Future<int> run() {
    final results = argResults!;
    if (results.rest.length != 1) {
      usageException(
        'create needs exactly one UpperCamelCase class name, '
        'e.g. `legend_gen create LegendBadge`.',
      );
    }
    return runCreate(
      results.rest.single,
      dir: results.option('dir'),
      logger: _logger,
    );
  }
}

/// `legend_gen doctor` — validates a project's theme setup.
class DoctorCommand extends Command<int> {
  /// Creates the command on the shared CLI [logger].
  DoctorCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'doctor';

  @override
  String get description =>
      'Report missing, stale, or orphaned generated theme files and '
      'version-pin drift.';

  @override
  String get invocation => 'legend_gen doctor [paths…]';

  @override
  Future<int> run() {
    final rest = argResults!.rest;
    return runDoctor(rest.isEmpty ? const ['lib'] : rest, logger: _logger);
  }
}

/// `legend_gen update` — self-update via `dart pub global activate`
/// (RFC-002 R11.4, on `package:pub_updater`).
class UpdateCommand extends Command<int> {
  /// Creates the command; [pubUpdater] is injectable for tests.
  UpdateCommand({required Logger logger, PubUpdater? pubUpdater})
    : _logger = logger,
      _pubUpdater = pubUpdater ?? PubUpdater();

  /// The pub.dev package this CLI updates to.
  static const packageName = 'legend_gen';

  final Logger _logger;
  final PubUpdater _pubUpdater;

  @override
  String get name => 'update';

  @override
  String get description => 'Update legend_gen to the latest version.';

  @override
  Future<int> run() async {
    final progress = _logger.progress('Checking for a newer legend_gen');
    final String latest;
    try {
      latest = await _pubUpdater.getLatestVersion(packageName);
    } on Exception catch (e) {
      progress.fail(
        'could not reach pub.dev ($e) — check your network and rerun '
        '`legend_gen update`.',
      );
      return LegendGenExit.unavailable;
    }
    if (latest == legendGenVersion) {
      progress.complete(
        'legend_gen is already at the latest version ($legendGenVersion).',
      );
      return LegendGenExit.success;
    }
    progress.update('Updating legend_gen to $latest');
    try {
      await _pubUpdater.update(
        packageName: packageName,
        versionConstraint: latest,
      );
    } on Exception catch (e) {
      progress.fail(
        'update failed ($e) — run `dart pub global activate '
        '$packageName $latest` manually.',
      );
      return LegendGenExit.unavailable;
    }
    progress.complete('Updated legend_gen $legendGenVersion → $latest.');
    return LegendGenExit.success;
  }
}
