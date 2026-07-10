---
name: legend-gate
description: The Legend UI quality gate — the exact format/analyze/test/freshness commands to run in order before any commit or merge of substance, plus the non-negotiable test norms. Invoke before committing or merging changes to kit, generator, or example code.
---

# Legend UI quality gate

Run the whole ladder from the repo root before every merge/commit of substance. Every step must pass — the gates are non-negotiable (CLAUDE.md rule 8).

```bash
# 0. Resolve the workspace (once per checkout / after pubspec changes)
flutter pub get

# 1. Format + lint (CI: dart format --output=none --set-exit-if-changed .)
dart format .
flutter analyze

# 2. Kit tests
cd packages/legend_ui && flutter test && cd ../..

# 3. Generator tests
cd packages/legend_gen && dart test && cd ../..

# 4. Example / docs-site tests (includes the selectable-text crash guard)
cd example && flutter test && cd ..

# 5. Generated output is fresh — all three checks, exit 65 = stale (regenerate & commit)
cd packages/legend_ui
dart run legend_gen themes lib test/consumer --check
dart run legend_gen docs lib test/consumer --check
dart run legend_gen tokens lib --check
cd ../..
```

If a `--check` fails, regenerate with the same command minus `--check` and commit the `.g.dart` diff — generated files are committed, never gitignored.

CI additionally builds the docs site (`cd example && flutter build web`); run it locally if you touched the example app's build surface.

## Norms enforced alongside the commands

- **Tests ship with every feature** — behavior is covered by widget tests (`example/test/`, `packages/*/test/`); no feature lands test-less.
- **Generator changes need golden tests** — `packages/legend_gen/test/` pins emitted output; extend the goldens with any emission change.
- **Closing a legacy bug** (list: legacy-docs `01-overview.md` §4.2) requires a regression test AND naming the bug in the commit message.
- **Analyzer must be clean** (very_good_analysis) — the docs-site launch configs are lint-gated and will not start on findings.
- No public-API typos; doc comments on every public/base widget in the standardized order (they are the docs-CMS content).
- New/ported components are incomplete without a playground rung (`example/lib/docs/pages/playground_page.dart` + `theme_panel.dart`).
