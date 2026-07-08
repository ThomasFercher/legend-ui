import 'dart:io';

import 'package:args/args.dart';
import 'package:nomo_gen/nomo_gen.dart';

const _usage =
    '''
nomo_gen v$nomoGenVersion — Nomo UI Kit code generation CLI

Usage:
  nomo_gen themes [paths…]     Generate *.theme.g.dart from @NomoThemeable
                               widgets (default path: lib)
      --check                  Verify committed output is fresh; fail on
                               stale/missing files (CI gate)

Planned (see docs/DESIGN.md §5): icons, create, doctor, --watch.
''';

Future<void> main(List<String> args) async {
  final parser = ArgParser()..addFlag('check', negatable: false);
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
  if (rest.isEmpty || rest.first != 'themes') {
    stdout.write(_usage);
    exitCode = 64;
    return;
  }

  final paths = rest.length > 1 ? rest.sublist(1) : const ['lib'];
  exitCode = await runThemes(paths, check: results.flag('check'));
}
