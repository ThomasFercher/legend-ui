import 'dart:io';

import 'package:args/args.dart';
import 'package:legend_gen/legend_gen.dart';

const _usage =
    '''
legend_gen v$legendGenVersion — Legend UI Kit code generation CLI

Usage:
  legend_gen themes [paths…]     Generate *.theme.g.dart from @LegendThemeable
                               widgets (default path: lib)
      --check                  Verify committed output is fresh; fail on
                               stale/missing files (CI gate)
      --watch                  Regenerate on source changes (Ctrl-C to stop)
  legend_gen create <ClassName>  Scaffold an annotated component and generate
                               its theme file
      --dir <path>             Target directory (default:
                               lib/src/components/<name>/)
  legend_gen doctor [paths…]     Report missing, stale, or orphaned generated
                               theme files (default path: lib)

Planned (see docs/DESIGN.md §5): icons.
''';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('check', negatable: false)
    ..addFlag('watch', negatable: false)
    ..addOption('dir');
  final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln(_usage);
    exitCode = 64;
    return;
  }

  final rest = results.rest;
  final command = rest.firstOrNull;
  if (command != null &&
      command != 'themes' &&
      (results.flag('check') || results.flag('watch'))) {
    stderr.writeln('--check and --watch are only valid with `themes`.');
    exitCode = 64;
    return;
  }
  if (command != null && command != 'create' && results.option('dir') != null) {
    stderr.writeln('--dir is only valid with `create`.');
    exitCode = 64;
    return;
  }

  switch (command) {
    case 'themes':
      final paths = rest.length > 1 ? rest.sublist(1) : const ['lib'];
      if (results.flag('watch') && results.flag('check')) {
        stderr.writeln('--watch and --check are mutually exclusive.');
        exitCode = 64;
        return;
      }
      exitCode = results.flag('watch')
          ? await runThemesWatch(paths)
          : await runThemes(paths, check: results.flag('check'));
    case 'create':
      if (rest.length != 2) {
        stderr.writeln('create needs exactly one ClassName.');
        stdout.write(_usage);
        exitCode = 64;
        return;
      }
      exitCode = await runCreate(rest[1], dir: results.option('dir'));
    case 'doctor':
      final paths = rest.length > 1 ? rest.sublist(1) : const ['lib'];
      exitCode = await runDoctor(paths);
    default:
      stdout.write(_usage);
      exitCode = 64;
  }
}
