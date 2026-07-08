# 01 — Repository Overview & Architecture Assessment

> Snapshot of `nomo_ui_kit` (repo `legend-ui`), branch `main` at commit `bccec60`, taken 2026-07-09.
> This documentation set describes the **legacy** codebase in full, as the baseline for a planned rewrite.

## 1. What this repository is

**Nomo UI Kit** (`nomo_ui_kit`, v0.0.36) is a Flutter UI kit built as an opinionated, customizable alternative to Material UI. It was originally created for the Nomo App and is distributed as a git submodule (`publish_to: none`). It targets all six Flutter platforms (iOS, Android, web, Windows, macOS, Linux).

Despite the `CLAUDE.md` in the repo describing a `/packages/` monorepo, **this checkout is the package itself**: `lib/` sits at the repo root, and the code generator (`nomo_ui_generator`) is a *path dependency on a sibling directory* (`../nomo-ui-kit-generator`) that is **not part of this repository** — and is currently absent from disk, meaning the repo cannot `pub get` or run `build_runner` standalone. (See [08 — Example App & Tooling](08-example-app-and-tooling.md).)

## 2. Key numbers

| Metric | Value |
|---|---|
| Version / commits / history | 0.0.36 · 313 commits · 2023-11-02 → 2025-12-12 |
| Branches | single `main` (this docs branch is an orphan) |
| Dart LOC in `lib/` | 36,571 total |
| — handwritten | 26,985 (73 files); ~12,378 excluding the vendored FontAwesome codepoint tables |
| — generated | 9,586 (29 files) |
| — of which theme-data boilerplate | 6,217 LOC across 26 `*.theme_data.g.dart` files |
| Themed-property expansion ratio | 175 annotated fields → ~35 generated LOC **per property** (~239 per component) |
| Icon system | 2,716 `IconData` consts (FontAwesome 6.4.2 fork), 106 KB reflection map, ~632 KB bundled TTFs |
| Runtime dependencies | `flutter_svg` only (plus the generator as an ill-placed *runtime* dep) |
| Tests | **none** (example app has only the broken counter-template test) |
| CI | two configs (`.github/workflows/dart.yml`, `.gitlab-ci.yml`), **both dead** — trigger on a nonexistent `develop` branch / nonexistent submodule layout |

## 3. Architecture map

```
NomoApp (WidgetsApp.router + wrappers)
 ├─ ThemeProvider (InheritedWidget, mode switching)
 ├─ MetricReactor (window width → sizing mode → theme swap)
 ├─ ThemeAnimator (lerps the ENTIRE NomoThemeData over 400 ms on every change)
 └─ per route: NomoScaffold (wraps Material Scaffold)
     ├─ NomoAppBar (custom slotted RenderBox)
     ├─ NomoSider / NomoBottomBar (visibility driven by sizing theme booleans)
     └─ NomoRouteBody (6 exclusive content modes)
```

- **Theme system** — `NomoThemeDelegate<ColorMode, SizingMode>` produces a core theme (17 colors, 10 sizes, 6 text styles) plus 48 generated per-component data classes; per-component resolution precedence is *widget param → local `…ThemeOverride` InheritedWidget → global theme → annotation defaults*. Full details in [02 — Theme System](02-theme-system.md).
- **Code generation** — three builders (`theme_data_builder`, `theme_utils_builder`, `reflection_builder`) in the external `nomo_ui_generator` (~1,050 LOC) expand `@NomoComponentThemeData` / `@NomoColorField` / `@NomoSizingField` / `@NomoConstant` / `@StaticFieldsList` annotations. Full details in [03 — Code Generation](03-code-generation.md).
- **Components** — app shell ([04](04-app-framework.md)), buttons/text/input ([05](05-buttons-text-input.md)), and ~20 display/overlay/layout components ([06](06-components.md)).
- **Utilities, icons, public API** — [07](07-utilities-icons-api.md). Note: there is no `lib/src/`; the barrel exports only 2 files, so consumers deep-import and **all 102 files are de-facto public API**.
- **Example app & tooling** — [08](08-example-app-and-tooling.md).

## 4. Consolidated problem inventory

These findings are drawn from the detailed chapters; each chapter cites file paths and line numbers.

### 4.1 Structural / architectural

1. **Broken, load-bearing codegen dependency.** The generator is a path dep outside the repo and missing on disk; the repo does not build standalone. It also extracts types/defaults by *string-slicing annotation source text*, so it is silently fragile (chapter 03).
2. **Extreme boilerplate economics.** ~35 generated LOC per themed property; 4 unchecked naming/registration conventions; every generated file exports a colliding `getFromContext` requiring `hide` in every barrel (chapter 03).
3. **Responsiveness entangled with theming.** Breakpoint crossings are theme swaps, and every theme change lerps ~48 component data classes at 60 fps for 400 ms, rebuilding every themed widget (chapters 02/04).
4. **Half-hearted Material independence.** The kit claims to replace Material but depends on `Scaffold`, `InkWell`, `ScaffoldMessenger`, `showDialog` (chapters 04/06).
5. **No API boundary.** No `lib/src/`, near-empty barrel, consumers deep-import everything (chapter 07).
6. **~3,500+ lines of vendored third-party code** drifting from upstream: CupertinoTextField fork (1,535 LOC), CupertinoSwitch fork, FadeIn (animate_do), InAppNotification, FontAwesome fork (chapters 05/06/07).

### 4.2 Correctness bugs (selection)

- `NomoText` auto-fit was deleted (commit `30aba3e`) but its API remains: `fit: true` silently overflows; 7 dead params (chapter 05).
- `disabled`/`loading` buttons remain tappable; only `nonInteractive` nulls `onPressed` (chapter 05).
- Secondary/text buttons bypass themed padding entirely (chapter 05).
- `NomoInput`: dispose-order bug on internal FocusNode, listener re-registration every `didChangeDependencies`, render box with wrong intrinsics recreated per animation frame via `ValueKey(hashCode)` (chapter 05).
- `NomoForm`: validator-less fields pin the form invalid forever; no unregistration; the `NomoFormValidator` API documented in CLAUDE.md does not exist (chapter 05).
- CupertinoSwitch fork: `Opacity(opacity: 42)` — debug-mode assert crash when disabled (chapter 06).
- DropDownMenu disposes its ValueNotifier before removing listeners and `firstWhere`-throws on unknown values (chapter 06).
- Sliver mode of `NomoRouteBody` ignores `appBar`; per-build ScrollControllers leak (chapter 04).
- Theming annotation misuse: size fields marked `@NomoColorField` end up color-lerped in the wrong theme bucket (chapter 06).
- Non-null constructor defaults (e.g. card/dialog `elevation`) make theme values unreachable (chapter 06).

### 4.3 Duplication & dead code

- Two shadow systems (`ElevatedBox` vs `NomoElevation`); two dropdowns (`NomoDropDownMenu` vs `NomoDropDownButton`) with separate item models; three hand-rolled overlay systems sharing zero code (chapter 06).
- `NomoModalSheet` is a `Placeholder()`; `nomo_scaffold_layout.dart` is empty; `CardConst`, `NoData` unused; many dead constructor params across components (chapters 04/06).
- 4× copy-pasted ~25-line switch arms for `textFirst` in the primary button; `NomoLinkButton` re-implements hover/tap and ignores 6 of its own params (chapter 05).
- 691 deprecated icon aliases; the generated `allIcons` reflection map defeats Flutter's icon tree-shaking for every consumer (chapter 07).

### 4.4 API hygiene

- Baked-in public API typos: `trailling`, `traillingStyle`, `scrollabe`, `valueNotifer`, `errorNotifer`, `inital`, `seperatorBulder`, `defaultTransistion`.
- CLAUDE.md documents multiple APIs that do not exist (`NomoFormValidator`, `DynamicRow(breakWidth:)`, form `submitButtonBuilder`, spacing extensions with wrong receivers).
- Informal commit history ("ww", "Cook"), no tags, patch-only version bumps.

### 4.5 Process

- Zero test coverage; dead CI on both platforms; FVM pins Flutter 3.27.4 but CI ignores it.
- Example app: 5 of 18 showcase sections are empty stubs; 590-LOC button section is half commented out.

## 5. What is worth keeping (conceptually)

The rewrite should not discard these *ideas*, which are sound and battle-tested in the Nomo App:

1. **The resolution precedence** — widget param → local override → global theme → default — is a good, predictable model. Only its *implementation* (35 LOC/property of codegen) is the problem.
2. **A delegate-driven theme** with orthogonal color mode × sizing mode, and typography assembled from both.
3. **First-class responsive shell** (app bar / sider / bottom bar switching by breakpoint) as a kit concern rather than an app concern.
4. **Zero runtime dependencies** as a design constraint (currently true except for `flutter_svg` and the misplaced generator dep).
5. **NomoRouteBody's goal** (unified scrolling content container) — but with one mode, not six.
6. The overall visual language and the component inventory itself (the *what*, not the *how*).

## 6. Reading order

| Chapter | Contents |
|---|---|
| [02 — Theme System](02-theme-system.md) | NomoTheme/ThemeProvider, core sub-themes, delegate, resolution chain |
| [03 — Code Generation](03-code-generation.md) | Annotations, the three builders, generated file anatomy, costs |
| [04 — App Framework](04-app-framework.md) | NomoApp, MetricReactor, ThemeAnimator, scaffold/app bar/sider/bottom bar/route body, notifications |
| [05 — Buttons, Text, Input](05-buttons-text-input.md) | Button family, NomoText, NomoInput/CupertinoTextInput fork, NomoForm |
| [06 — Components](06-components.md) | Surfaces, overlays, menus/selection, feedback/loading, layout, misc |
| [07 — Utilities, Icons, Public API](07-utilities-icons-api.md) | Extensions, PlatformInfo, icon system, entities, export surface |
| [08 — Example App & Tooling](08-example-app-and-tooling.md) | Example gallery, dependencies, lint/test/CI, repo hygiene |
| [09 — Rewrite Proposal](09-rewrite-proposal.md) | The theorized slim architecture for the rewrite |
