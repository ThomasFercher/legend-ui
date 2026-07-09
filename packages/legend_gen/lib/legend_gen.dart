/// legend_gen — the Legend UI Kit code generation CLI, as a library.
///
/// The CLI in `bin/` is a thin wrapper; everything here is packaging-
/// agnostic so an optional build_runner Builder can wrap the same core
/// later (DESIGN.md §5.3).
library;

export 'src/create_command.dart';
export 'src/doctor_command.dart';
export 'src/emitter.dart';
export 'src/model.dart';
export 'src/parser.dart';
export 'src/themes_command.dart';
export 'src/version.dart';
