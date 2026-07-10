---
name: legend-cli
description: legend_gen command reference — themes/docs/tokens/create/doctor/update subcommands with their real flags, --check/--watch semantics, and the exit-code table. Invoke when running, scripting, or debugging Legend UI code generation.
---

# legend_gen CLI reference

Run from `packages/legend_ui` (or any package that dev-depends on `legend_gen`): `dart run legend_gen <command>`. Global flags: `-v/--verbose` (per-file output), `-q/--quiet` (errors only), `--version`.

## Generation commands

All three share the same shape: positional source paths (**default `lib`** when omitted), plus `--check` and `--watch` (mutually exclusive — combining them is a usage error, exit 64).

| Command | Reads | Writes (next to each source, as a `part`) |
|---|---|---|
| `themes [paths…]` | `@Style()` value classes, then `@LegendThemeable` widgets | `<source>.style.g.dart` (member-wise merge/lerp, value `==`), `<source>.theme.g.dart` (Theme/Nullable/Override/of, `_theme` hook, per-field accessors, State getter/mixin, `_$XBase`, listenables) |
| `docs [paths…]` | the same `@LegendThemeable` annotations | `<source>.docs.g.dart` (a const `List<LegendDocEntry>` per widget — the docs-CMS manifest) |
| `tokens [paths…]` | `@LegendTokenData` token classes | `<source>.tokens.g.dart` (`copyWith`, member-wise lerp, value `==`, and the `Ref` tear-off catalog when `mountedAt:` is set) |

The repo's canonical invocations (kit + consumer fixtures):

```bash
cd packages/legend_ui
dart run legend_gen themes lib test/consumer
dart run legend_gen docs lib test/consumer
dart run legend_gen tokens lib
```

**Generated files are committed.** Generation is strictly one-file-in/one-file-out — no cross-file analysis (the `themes` style-class index is built per run from the configured paths plus compiled-in kit builtins; emission stays per-file).

### `--check` (the CI gate)

Verifies committed output is fresh instead of writing; exits **65** when anything is stale or missing. CI runs exactly:

```bash
dart run legend_gen themes lib test/consumer --check
dart run legend_gen docs lib test/consumer --check
dart run legend_gen tokens lib --check
```

### `--watch`

Regenerates only changed files on save (150 ms debounce) until Ctrl-C. **Source errors never stop the watch** — diagnostics print with `file:line` naming the fix, the last good output is kept, and the next save rebuilds. Single-file regeneration still resolves style classes against the full configured path set.

## `create <ClassName>`

```bash
dart run legend_gen create LegendBadge
dart run legend_gen create LegendBadge --dir lib/widgets
```

Scaffolds an annotated component stub (compiled-in template) and immediately generates its `.theme.g.dart` + `.docs.g.dart`, so the `part` directive resolves from the first second. Default `--dir`: `lib/src/components/<name>/` where `<name>` is the snake_case class name without its `Legend` prefix (`LegendBadge` → `badge`). Requires exactly one UpperCamelCase name (else exit 64); refuses to overwrite an existing file (exit 73).

## `doctor [paths…]`

Default path `lib`. Checks, in order: `@LegendThemeable` widgets with a missing `.theme.g.dart`; stale generated output; orphaned `*.theme.g.dart` whose source is gone or no longer annotated; generated files stamped by a different legend_gen version (warning); the project's resolved `legend_gen` pin vs the running CLI version (warning); plus any decorator-contract violation. Any finding — warnings included — exits **65**.

## `update`

Self-updates the globally activated `legend_gen` via pub.dev; exits **69** when pub.dev is unreachable, 0 when already latest.

## Exit codes

| code | name | meaning / CI interpretation |
|---|---|---|
| 0 | success | the run did what was asked |
| 64 | usage | bad invocation: unknown command/flag, bad args |
| 65 | dirty | `--check` found stale/missing output, or `doctor` found problems → regenerate/fix and commit |
| 66 | sourceError | recoverable decorator-contract violations; `file:line` diagnostics printed, nothing broken written |
| 69 | unavailable | `update` could not reach pub.dev |
| 70 | software | internal legend_gen fault (a generator bug) |
| 73 | cantCreate | `create` refused to overwrite an existing file |

Watch mode never exits on dirty/sourceError-class problems; only an internal fault (or Ctrl-C → 0) ends a `--watch` run.
