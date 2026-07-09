import 'package:mason_logger/mason_logger.dart';

/// The documented exit-code taxonomy of the `legend_gen` CLI
/// (RFC-002 R11.1/R11.6).
///
/// CI workflows only need "non-zero means fail"; the distinct codes let a
/// pipeline tell *why* without parsing output:
///
/// | code | name          | meaning                                          |
/// |------|---------------|--------------------------------------------------|
/// | 0    | `success`     | the run did what was asked                       |
/// | 64   | `usage`       | bad invocation: unknown command/flag, bad args   |
/// | 65   | `dirty`       | `--check` found stale/missing generated output,  |
/// |      |               | or `doctor` found problems (regenerate/fix)      |
/// | 66   | `sourceError` | recoverable decorator-contract violations in the |
/// |      |               | scanned sources (`file:line` diagnostics printed)|
/// | 69   | `unavailable` | `update` could not reach pub.dev                 |
/// | 70   | `software`    | an internal legend_gen fault (a generator bug)   |
/// | 73   | `cantCreate`  | `create` refused to overwrite an existing file   |
///
/// Watch mode never exits on [dirty]/[sourceError]-class problems — it
/// reports and keeps watching; only [software] (or Ctrl-C → [success])
/// ends a `--watch` run (RFC-002 R11.2).
abstract final class LegendGenExit {
  /// 0 — the run did what was asked.
  static final int success = ExitCode.success.code;

  /// 64 — bad invocation (unknown command/flag, invalid arguments).
  static final int usage = ExitCode.usage.code;

  /// 65 — the project is out of date: `--check` found stale or missing
  /// generated output (the CI freshness gate), or `doctor` found problems.
  static final int dirty = ExitCode.data.code;

  /// 66 — recoverable source errors: the scanned files violate the
  /// decorator contract; `file:line` diagnostics naming the fix were
  /// printed and nothing broken was written.
  static final int sourceError = ExitCode.noInput.code;

  /// 69 — `update` could not reach pub.dev (network/service failure).
  static final int unavailable = ExitCode.unavailable.code;

  /// 70 — an internal legend_gen fault (a bug in the generator itself).
  static final int software = ExitCode.software.code;

  /// 73 — `create` refused to overwrite an existing file.
  static final int cantCreate = ExitCode.cantCreate.code;
}
