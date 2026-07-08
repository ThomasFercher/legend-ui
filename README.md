# Nomo UI Kit — Legacy Documentation & Rewrite Proposal

This is an **orphan branch** containing no code — only the complete documentation of the legacy `nomo_ui_kit` codebase as it exists on `main` (commit `bccec60`, snapshot taken 2026-07-09), plus the architecture proposal for the planned full rewrite.

`main` is considered the **legacy branch**. It stays frozen as the reference implementation while the rewrite proceeds; these documents are the map of what it does, how it works, and what must not be rebuilt the same way.

## Contents

| Chapter | Scope |
|---|---|
| [01 — Overview & Assessment](01-overview.md) | Repo facts, key numbers, architecture map, consolidated problem inventory, what's worth keeping |
| [02 — Theme System](02-theme-system.md) | NomoTheme / ThemeProvider / delegate, core sub-themes, component theme resolution |
| [03 — Code Generation](03-code-generation.md) | The `nomo_ui_generator` builders, annotations, generated-file anatomy, complexity costs |
| [04 — App Framework](04-app-framework.md) | NomoApp, MetricReactor, ThemeAnimator, scaffold, app bar, sider, bottom bar, route body, notifications |
| [05 — Buttons, Text, Input](05-buttons-text-input.md) | Button family, NomoText, NomoInput + CupertinoTextInput fork, NomoForm |
| [06 — Components](06-components.md) | Surfaces, overlays, menus & selection, feedback/loading, layout, misc |
| [07 — Utilities, Icons, Public API](07-utilities-icons-api.md) | Extensions, PlatformInfo, icon system, entities, export surface |
| [08 — Example App & Tooling](08-example-app-and-tooling.md) | Example gallery, dependencies, lint/test/CI, repo hygiene |
| [09 — Rewrite Proposal](09-rewrite-proposal.md) | **The theorized slim architecture** — tokens, decorator-declared component themes with defaults/overrides at every level, primitives, icon unbundling, and a rebuilt in-repo generator (CLI-first, build_runner optional) |

## How this was produced

Chapters 02–08 were written by exhaustively reading the legacy source (file paths and line numbers are cited throughout). Chapter 01 synthesizes them; chapter 09 is the forward-looking RFC and the starting point for the rewrite discussion.
