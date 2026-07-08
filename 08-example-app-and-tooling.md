# 08 — Example App & Repo Tooling/Metadata

Documentation of the `example/` showcase app and the repository-level tooling, metadata, CI, and hygiene of **nomo_ui_kit** (repo checkout: `/Users/thomas/src/legend-ui`). This document feeds the rewrite decision.

---

## 1. Example App Architecture

### 1.1 Overall shape

The example app (`/Users/thomas/src/legend-ui/example/`) is a single-page-app-style component gallery: a persistent shell (app bar + sider/drawer) around a nested navigator that swaps between ~18 "section" pages, one per component family. It is deployed as a web demo (`https://dev.nomo.app/nomo-ui-kit/example_app/` per the README) and uses `usePathUrlStrategy()` for clean web URLs.

Key files:

| File | Role |
|---|---|
| `example/lib/main.dart` | Entry point; `NomoNavigator` + `NomoApp` setup; `HomePage` (renders the repo README via `markdown_widget` fetched over HTTP) |
| `example/lib/theme.dart` | `AppThemeDelegate` — full `NomoThemeDelegate<ColorMode, SizingMode>` implementation |
| `example/lib/routes.dart` | Route table via `route_gen` annotations + scaffold shell `wrapper` function |
| `example/lib/routes.g.dart` | Generated `AppRouter` (by `route_gen` / build_runner) — checked into git |
| `example/lib/widgets/` | Shell chrome: `sider.dart`, `drawer.dart`, `bottom_bar.dart` |
| `example/lib/sections/` | 17 showcase pages (see section 2) |

### 1.2 Routing (`route_gen` + `nomo_router`)

`example/lib/routes.dart` declares the route tree as a `const _routes` list annotated with `@AppRoutes()` (from `package:route_gen/anotations.dart` — note the typo'd package path "anotations" is upstream). `build_runner` generates `routes.g.dart` containing `class AppRouter extends NomoAppRouter` with a `RouterConfig`, a `NomoRouterDelegate`, and typed route classes (e.g. `ModalSheet1Route`).

Structure:

- One top-level `NestedNavigator(key: ValueKey("main"), wrapper: wrapper, children: [...])` — all pages render inside the shell provided by `wrapper`.
- 18 `MenuPageRouteInfo` children (path + title + page class): `/` (Home), `/modalSheet`, `/typography`, `/button`, `/data`, `/notifications`, `/icons`, `/dialogs`, `/input`, `/dropdown`, `/card`, `/list`, `/grid`, `/loading`, `/expandable`, `/tile`, `/layout`, `/menu`.
- One nested `ModalRouteInfo` (`/modalSheet/sheet1` → `ModalSheet1`, `useRootNavigator: true`) demonstrating modal routes layered above the shell.

Menu generation: `routes.dart` defines extensions (`MenuUtilList.toMenuItems`, `MenuUtil.toMenuItem`) that convert `MenuRouteInfoMixin` route infos into `NomoMenuItem<String>` (icon/image/text variants keyed by path). `main.dart` materializes this once as a global: `final menuItems = appRouter.routeInfos.toMenuRoutes.toMenuItems;` — the same list drives sider, drawer, and bottom bar. This "routes are the menu" pattern is the app's central architectural idea.

Navigation is via `NomoNavigator.of(context).pushNamed(item.key)` (path string as key) or typed push (`push(ModalSheet1Route())`). Current-route awareness comes from `NomoNavigatorInformationProvider.of(context).current`, pattern-matched against `MenuPageRouteInfo` to highlight the active menu item.

`main.dart` wraps everything in `NomoNavigator(delegate: appRouter.delegate, defaultTransistion: PageSharedAxisTransition(...))` (note the `defaultTransistion` typo in the public API, and the `animations` package supplying shared-axis transitions), containing `NomoApp(themeDelegate: AppThemeDelegate(), color: Colors.red, supportedLocales: [en_US], routerConfig: appRouter.config)`.

### 1.3 Theme setup (`theme.dart`)

`AppThemeDelegate extends NomoThemeDelegate<ColorMode, SizingMode>` with app-defined enums `ColorMode {LIGHT, DARK}` and `SizingMode {SMALL, MEDIUM, LARGE}`. This is the reference implementation of the kit's theme-delegate contract:

- **Color themes** (`getColorThemes()`): two `NomoColorThemeDataNullable` entries (light/dark) supplying the full `NomoColors` core palette (primary/secondary + containers, background1-3, surface, foreground1-3, error, disabled/onDisabled, brightness). `initialColorTheme()` → LIGHT. Runtime switching via `ThemeProvider.of(context).changeColorTheme(...)` (wired to a sun/moon `IconButton` in the app bar).
- **Sizing themes** (`getSizingThemes()`): three breakpoint-keyed `NomoSizingThemeDataNullable` entries; `sizingThemeBuilder(width)` maps `<600` → SMALL, `<1080` → MEDIUM, else LARGE. Each tier sets core font sizes (b1-b3, h1-h3), spacing1-3, and per-component sizing overrides via `buildComponents` — notably SMALL sets `NomoScaffoldSizingDataNullable(showSider: false)` (mobile hides the sider; the app bar then shows a hamburger that opens the end drawer), MEDIUM/LARGE set `NomoSiderSizingDataNullable(width: 200)`, LARGE sets `maxContentWidth: 1000`.
- **Typography**: `NomoTypographyTheme` fed by `google_fonts` (Roboto for body, Inter for headings) — font *sizes* come from the sizing theme, families from here.
- **Constants / component defaults**: `constants`, `defaultComponentsSize`, `defaultComponentsColor` all return empty/default objects — demonstrating the minimum-viable delegate.

This delegate is verbose (~180 lines of boilerplate for a two-color, three-size theme) and is a good exhibit of the generated-theme ergonomics a rewrite should improve.

### 1.4 Shell assembly (scaffold / sider / drawer / bottom bar)

The shell is the `wrapper(nav)` function in `routes.dart` (passed to `NestedNavigator`). It builds:

- `NomoScaffold` with:
  - `appBar: NomoAppBar` — `leading` title text "Nomo UI Kit"; `trailling` (typo'd param name, upstream API) row with the dark/light-mode toggle and, when `!context.componentSizes.scaffoldSizing.showSider` (i.e. mobile), a hamburger button calling `NomoScaffold.of(context).openEndDrawer()`.
  - `sider: const Sider()` (`example/lib/widgets/sider.dart`) — `NomoSider` wrapping a `NomoVerticalMenu<String>` over the shared `menuItems`, highlighting the current route, `pushNamed` on tap. Visibility is controlled by the sizing theme, not by the widget.
  - `endDrawer: const DrawerEx()` (`example/lib/widgets/drawer.dart`) — same `NomoVerticalMenu` inside a 280-wide `NomoSider`, with a "Components" title and `closeEndDrawer()` after navigation. Mobile substitute for the sider.
  - `child: nav` — the nested navigator's page content.
- `example/lib/widgets/bottom_bar.dart` defines a `BottomBar` (`NomoBottomBar<String>` over the same `menuItems`) but it is **not wired into the wrapper** — dead code in the current shell (likely a remnant or manual-test widget; recent library commits actively touched `NomoBottomBar`, so it's probably used ad-hoc during development).

Pages themselves use `NomoRouteBody` (children / slivers / builder variants), which handles content max-width, padding, and scroll (`DefaultScrollController.of(context)`).

---

## 2. Showcase Sections Inventory

All in `example/lib/sections/`. Line counts give a sense of depth; five sections are **empty stubs** (bare `Container()`), so the gallery over-promises relative to what it demonstrates.

| Section file | Route | LOC | Demonstrates |
|---|---|---|---|
| `button_section.dart` (`TextButtonWrapper`) | `/button` | 590 | The deepest section. `PrimaryNomoButton` (text, icon+text, circle/square icon-only, `ActionType.danger/disabled/nonInteractive/loading`), `SecondaryNomoButton` (same matrix), `NomoTextButton`, `NomoLinkButton`; theme overrides (`PrimaryNomoButtonThemeOverride`, `SecondaryNomoButtonThemeOverride`, `NomoOutlineContainerThemeOverride`), `MultiWrapper`, `DynamicRow`, color utils (`.lighten()`). **~320 of 590 lines are commented-out legacy code** for an old `NomoButton.icon`/`ButtonSize` API. |
| `card_section.dart` | `/card` | 28 | Minimal: one `NomoCard` (backgroundColor, borderRadius, elevation) around an empty SizedBox. |
| `data_section.dart` | `/data` | 32 | `NoData` placeholder component inside `NomoOutlineContainer`; `NomoText` + `.vSpacing` extensions. |
| `dialog_section.dart` | `/dialogs` | 73 | `NomoDialog` via `showDialog` — title/titleStyle, scrollable content, close button, action buttons (Secondary + Primary). |
| `dropdown_section.dart` | `/dropdown` | 10 | **Empty stub** (`Container()`), despite `NomoDropDownButton/Menu` existing in the kit. |
| `expandable_section.dart` | `/expandable` | 92 | `Expandable` — simple and nested (expandable inside expandable), inside `NomoOutlineContainer`. |
| `grid_section.dart` | `/grid` | 10 | **Empty stub**. |
| `icon_section.dart` | `/icons` | 101 | The full generated icon registry (`allIcons` map from `nomo_icons.dart`), live search via `NomoInput` + `ValueNotifier`, rendered in a `SliverGrid` inside `NomoRouteBody(slivers:)` — also demonstrates the `.toBox` sliver adapter extension. |
| `input_section.dart` | `/input` | 220 | `NomoInput` in depth: leading/trailing widgets (incl. an embedded "max" `PrimaryNomoButton`), placeholder-as-title, per-corner borderRadius composition (grouped input cluster), `valueNotifier` binding, inline validators; `NomoForm` with `NomoFormValues`/`NomoFormValidator`, `formKey`-registered inputs, multiline input, submit-triggered validation, live display of form values/validity via `ListenableBuilder`. |
| `layout_section.dart` | `/layout` | 26 | `DynamicRow` with random-width children (wrap/spacing behavior). |
| `list_section.dart` | `/list` | 10 | **Empty stub** (list tiles are actively developed in the library but undemonstrated). |
| `loading_section.dart` | `/loading` | 183 | `Loading` spinner (color/endColor/strokeWidth variants), `Shimmer` (default + custom gradient/duration) with `LoadingContainer` blocks; `spacingH/spacingV` list extensions. |
| `menu_section.dart` | `/menu` | 10 | **Empty stub** (ironically, `NomoVerticalMenu` is only demonstrated implicitly by the shell's sider/drawer). |
| `modal_sheet_section.dart` | `/modalSheet` | 56 | Nested modal routing: typed `push(ModalSheet1Route())`, `RouteInfoProvider`, a hand-rolled drag-to-dismiss bottom sheet. The `wolt_modal_sheet` dependency is declared but **not used here**. |
| `notification_section.dart` | `/notifications` | 36 | `InAppNotification.show(...)` overlay API + `NomoNotification` (leading icon, title, subtitle, duration, positioning). |
| `text_section.dart` | `/typography` | 51 | `NomoText` for h1–h3/b1–b3 scale plus `fit: true` auto-fitting with `maxLines`. |
| `tile_section.dart` | `/tile` | 10 | **Empty stub** (Horizontal/Vertical list tiles undemonstrated despite recent commits to them). |

`HomePage` (in `main.dart`, route `/`) additionally showcases typography config by rendering the GitHub README through `markdown_widget` styled with `context.typography` — it does a network fetch **in `build()`** (a `get(...)` future created per rebuild), a known anti-pattern worth not carrying into the rewrite.

---

## 3. Dependency Inventory

### 3.1 Root package (`/Users/thomas/src/legend-ui/pubspec.yaml`)

`nomo_ui_kit` v**0.0.36**, `publish_to: none`, SDK `>=3.6.0 <4.0.0`, Flutter `>=3.27.3` (FVM pin: **3.27.4** via `.fvmrc`). Declares all six platforms (ios/android/web/windows/macos/linux).

| Dependency | Version | Notes |
|---|---|---|
| `flutter`, `flutter_localizations` | SDK | |
| `flutter_svg` | ^2.0.10+1 | The one third-party runtime dep — the README's "almost zero runtime-dependencies" claim hinges on "almost" |
| `nomo_ui_generator` | **`path: ../nomo-ui-kit-generator`** | **Regular dependency (not dev!), pointing OUTSIDE the repo. The sibling directory does not exist on this machine (`/Users/thomas/src/nomo-ui-kit-generator` missing) → `flutter pub get` fails; the repo does not build standalone.** |
| `very_good_analysis` | ^5.1.0 (dev) | Lint base |
| `build_runner` | ^2.0.0 (dev) | Codegen driver |

Also bundles three FontAwesome font assets (brands/regular/solid TTFs under `lib/icons/fonts/`).

A commented-out `# resolution: workspace` line (and commit `deebcf4 "Update pubspec.yaml to enable workspace resolution"`) shows a pub-workspace setup was attempted and rolled back.

### 3.2 Example app (`example/pubspec.yaml`)

`example` v1.0.0+1, `publish_to: none`, SDK `>=3.3.0 <4.0.0`.

| Dependency | Version | Used for |
|---|---|---|
| `nomo_ui_kit` | `path: ../` | The kit itself |
| `nomo_router` | ^0.0.3 (pub) | Router runtime (NomoNavigator/NomoAppRouter) — a separate nomo-app package, pinned at a pre-1.0 version |
| `route_gen` | ^0.1.0 (pub) | Route codegen annotations + generator |
| `animations` | ^2.0.7 | SharedAxis page transitions |
| `markdown_widget` | ^2.3.1 | Home page README rendering |
| `wolt_modal_sheet` | ^0.1.2 | Declared; **no usage found** in `example/lib` — removable |
| `google_fonts` | ^6.1.0 | Roboto/Inter typography |
| `http` | ^1.1.0 | Home page README fetch |
| `cupertino_icons` | ^1.0.2 | Boilerplate |
| `flutter_test`, `build_runner` ^2.4.15, `flutter_lints` ^5.0.0 | dev | |
| **`dependency_overrides: collection: 1.19.0`** | | Pin to resolve an ecosystem conflict — a mild smell |

Implicit coupling: the example depends on **three** nomo-app packages (`nomo_ui_kit`, `nomo_router`, `route_gen`) plus the out-of-repo `nomo_ui_generator` transitively. A rewrite should decide whether router integration remains a first-class concern of the UI kit's app shell (`NomoApp` takes a `routerConfig`; `NomoScaffold`'s menu story assumes `nomo_router` idioms).

---

## 4. Lint / Analysis Setup

- **Root** (`analysis_options.yaml`): `include: package:very_good_analysis/analysis_options.yaml` (strict VGA base) but with substantial relaxations: `public_member_api_docs: false` (so the kit is largely undocumented at the API level), plus `lines_longer_than_80_chars`, `prefer_int_literals`, `sort_constructors_first`, `avoid_positional_boolean_parameters`, `sort_pub_dependencies`, `prefer_constructors_over_static_methods`, `no_leading_underscores_for_local_identifiers` all disabled; `constant_identifier_names` demoted to ignore.
- **Example** (`example/analysis_options.yaml`): stock `flutter_lints` include (near-default Flutter template), `constant_identifier_names` ignored (for the `LIGHT`/`DARK`/`SMALL` enum names).
- **`build.yaml`** (root): only excludes `example/**` and `test/**` from the default codegen target. The three builders described in CLAUDE.md (theme_data/theme_utils/reflection) are defined in the *generator* package's build.yaml — i.e., the codegen contract is invisible from this repo.

---

## 5. Test Coverage: effectively zero (and worse than zero)

- The library package has **no `test/` directory at all** (`/Users/thomas/src/legend-ui/test` does not exist).
- The example has exactly one file, `example/test/widget_test.dart` — the **unmodified Flutter counter-app template test**. It pumps `MyApp` and asserts a counter/`Icons.add` that don't exist, so it would **fail if ever run** (and can't even build without the missing generator dependency).
- Net: zero real coverage; the single existing test is broken boilerplate. The GitLab CI `test_coverage` job (below) is therefore aspirational.

## 6. CI/CD Status: two configs, both stale

- **GitHub Actions** (`.github/workflows/dart.yml`, "UI-KIT CI/CD"):
  - Triggers only on push/PR to **`develop`** — a branch that **does not exist** (only `main` exists, locally and on origin). The workflow can essentially never run.
  - The lint job references `packages/nomo-router` as a **git submodule** — a layout this repo does not have (no `.gitmodules`, no `packages/`). Copied from an older repo incarnation.
  - A `generate-docs` job runs `dartdoc` and deploys to GitHub Pages (matches the `dev.nomo.app/nomo-ui-kit` docs link) — also gated on the nonexistent `develop` branch.
- **GitLab CI** (`.gitlab-ci.yml`): a second, parallel pipeline (Cirrus Flutter image, `kubernetes` runner tags) with `lint` and `test_coverage` jobs (junit + lcov/genhtml artifacts). Presence of both configs suggests a GitLab mirror at some point; the coverage job would fail today (broken template test, missing path dep on any clean runner).
- **Effective CI: none.** Nothing runs on `main`, and no pipeline could pass as-is because `pub get` requires the out-of-repo generator.

## 7. Versioning & Changelog Practice

- `CHANGELOG.md` is genuinely maintained: 36 entries, 0.0.1 → **0.0.36**, one short bullet list per patch release. All releases are 0.0.x patches — no semver discipline signaling breaking vs. additive changes (several entries are clearly breaking, e.g. "Make NomoDropDownItem sealed class").
- `publish_to: none` on both packages: distribution is **by git submodule** (the README says "seamlessly integrating as a submodule"), so version numbers are informational, not resolvable constraints.
- Git history (`git log --oneline -30`): active but informal solo development on a **single `main` branch** (no develop, no tags visible, no PR flow). Message quality is mixed — some descriptive, some `ww`, `Fix`, `Cook`, `QoL`, `merge`. No release tagging discipline detected.

## 8. Repo Hygiene Observations (rewrite considerations)

1. **CLAUDE.md is stale/wrong about the layout.** `/Users/thomas/src/legend-ui/CLAUDE.md` describes a monorepo with `/packages/nomo-ui-kit/` and `/packages/nomo-ui-kit-generator/`. **Reality: the kit's `lib/` is at the repo root and there is no `packages/` directory; the generator lives in a separate repo entirely.** Several CLAUDE.md claims are also aspirational (e.g. `NomoFormValidator.required/compose` helpers and `submitButtonBuilder` shown in its examples don't match the actual `NomoForm` API used in `input_section.dart`). Treat CLAUDE.md as unreliable documentation.
2. **External generator path dependency — the biggest build hazard.** `nomo_ui_generator: path: ../nomo-ui-kit-generator` is a *runtime* dependency of the published package pointing outside the repo, and the sibling checkout is absent on this machine. Anyone cloning this repo alone cannot `pub get`, build, run the example, or regenerate `*.g.dart` files. The rewrite must either vendor the generator (true monorepo/pub workspace), publish it, or eliminate codegen.
3. **Generated files are checked in** (`routes.g.dart`, `*.theme_data.g.dart` across `lib/`), which is the only reason the code is browsable/buildable-ish without the generator — but they can silently drift from source annotations.
4. **`publish_to: none` + submodule distribution** means no pub.dev presence, no automated API-doc pipeline actually running, and consumers pinned to git SHAs.
5. **Dead/vestigial code in the example**: `widgets/bottom_bar.dart` unwired; 5 of 17 sections are empty stubs; ~320 lines of commented-out legacy button API in `button_section.dart`; unused `wolt_modal_sheet` dependency; network fetch in `build()` on the home page.
6. **CI configs for two hosts, both non-functional** (wrong branch, wrong layout, submodule assumptions) — delete or rewrite alongside the code.
7. **Upstream API typos** leak into every consumer: `trailling` (NomoAppBar/NomoInput), `defaultTransistion` (NomoNavigator), `scrollabe` (NomoDialog), `route_gen/anotations.dart` — a rewrite is the natural moment to fix these as breaking renames.
8. **Toolchain pinning** exists via FVM (`.fvmrc` → Flutter 3.27.4), which is good; nothing in CI honors it.

---

*Sources: all paths under `/Users/thomas/src/legend-ui/` as cited inline; git history via `git log --oneline -30` and `git branch -a` on 2026-07-09.*
