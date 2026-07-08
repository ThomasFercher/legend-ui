import 'dart:io';

const _usage = '''
nomo_gen — Nomo UI Kit code generation CLI (scaffold; not yet implemented)

Planned subcommands (see docs/DESIGN.md §5):
  themes    Generate *.theme.g.dart from @NomoThemeable widgets
  icons     Regenerate icon codepoint tables from upstream metadata
  create    Scaffold a new themed component
  doctor    Validate a project's Nomo theme setup

Planned flags:
  --check   Verify committed generated output is fresh (CI gate)
  --watch   Regenerate on file changes
''';

void main(List<String> args) {
  stdout.write(_usage);
  exitCode = 64; // EX_USAGE until subcommands exist
}
