import 'dart:io';

import 'package:legend_gen/legend_gen.dart';

Future<void> main(List<String> args) async {
  // The runner owns all error handling and exit-code classification
  // (LegendGenExit); this entrypoint only flushes and exits.
  final code = await LegendGenCommandRunner().run(args);
  await stdout.flush();
  await stderr.flush();
  exit(code);
}
