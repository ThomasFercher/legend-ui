# RFC-004 — Widget catalog & expansion roadmap

> Status: **proposed** (2026-07-10) — the prioritized plan for growing Legend UI's component set beyond the rewrite's foundation. Synthesizes three parallel research passes (2026-07-10): an industry gap analysis across 8 design systems, and component-demand studies for the two flagship consumer apps (a cross-platform crypto wallet; a NotebookLM-class AI workspace). Build agents run under `.claude/agents/legend-widget-author.md`. Naming follows the existing `Legend*` vocabulary.

## 1. Method — three lenses, one priority

Each candidate component is scored on three independently-gathered signals:

- **Industry frequency** — how many of 8 surveyed systems ship it (Ant Design v5, MUI, Fluent 2, shadcn/ui, Radix, Chakra, Ant Design Mobile, React Native Paper).
- **Flagship demand** — whether the crypto wallet and/or the AI workspace need it (from the two app studies).
- **Composition cost** — how cheaply it builds on Legend's existing primitives, and how many *other* widgets it unlocks.

The three lenses converged sharply: **the tappable list item/tile is the #1 gap in all three**, and a set of ~10 "boring" components (list, tabs, segmented, checkbox, chip, badge, avatar, tooltip, banner, progress) are simultaneously high-frequency *and* demanded by both apps — the highest-ROI additions.

## 2. What already exists (baseline)

**HAVE (post-Phase-F):** buttons (Primary/Secondary/Text on `LegendButtonCore`), `LegendCard`, `LegendContextMenu`, `LegendDialog`, `LegendDivider`, `LegendDropdown` (single-select), `LegendExpandable` (single disclosure), `LegendForm`/`FormField`/`Validators`, `LegendInfoItem` (static label/value row), `LegendTextField`, `LegendLoading`, `LegendShimmer` (skeleton), `LegendSwitch`, `LegendText`(+`.rich`), `LegendToast`, `LegendBody` + `LegendSliver*`, `LegendVerticalMenu`. Primitives: `LegendSurface`, `LegendInteractive`, `LegendButtonCore`, `LegendFieldCore`, `LegendAnchoredOverlay`, `LegendModal`, `LegendCaret`. Shell: `LegendApp`/`Scaffold`/`AppBar`/`BottomBar`/`Sider`/`NavItem`.

**PARTIAL (upgrade, don't rename):**
- `LegendDropdown` is a closed single-select — **not** a searchable/typeahead `Combobox`, no multi-select, no icon/subtitle items.
- `LegendExpandable` is a single disclosure — **not** a grouped `Accordion` (single-open set).
- `LegendInfoItem` is a static label/value row — **not** a tappable list tile with title/subtitle + leading/trailing slots.
- `LegendModal` slides edge sheets but has no drag-handle/snap-point `Drawer`/`Sheet` ergonomics.
- `LegendContextMenu` is right-click only — no button-anchored action `Menu`.

## 3. Priority — build waves

`[P]` = primitive-shaped (many widgets reuse it, build first). `[L]` = leaf. Frequency = /8 systems. Demand: **W**allet, **A**I-workspace.

### Wave 0 — foundations (gate the rest; build first)
| # | Name | Kind | Freq | Unlocks |
|---|---|---|---|---|
| 1 | `LegendSelectionControl` | [P] | 8/8 | shared checked/pressed/focus base behind Checkbox, Radio, Toggle, Segmented, selectable tiles/menu items — 5+ widgets collapse into it |
| 2 | `LegendPopover` | [P] | 7/8 | a reusable positioned-surface component over the existing `LegendAnchoredOverlay` engine — unlocks Tooltip, HoverCard, action Menu, the Combobox panel, Popconfirm |

`LegendFieldCore` (the third foundation, gating the field family) **already landed** in Phase F.

### Wave 1 — the shared high-frequency core (both apps × 7–8/8)
| # | Name | Kind | Freq | Demand | Composes |
|---|---|---|---|---|---|
| 3 | `LegendListItem` (+ `LegendList`) | [L] | 7/8 | W+A | Surface + Interactive; generalizes `LegendInfoItem`. **Top single-component priority.** |
| 4 | `LegendTabs` | [L] | 8/8 | W+A | Interactive + Surface (indicator) |
| 5 | `LegendCheckbox` | [L] | 8/8 | W+A | on #1 + Caret (check paint) |
| 6 | `LegendChip` | [L] | 7/8 | W+A | Surface + Interactive (selectable/dismissible) |
| 7 | `LegendBadge` | [L] | 7/8 | W+A | Surface + Text |
| 8 | `LegendAvatar` | [L] | 8/8 | W+A | Surface + Text (image + fallback + badge slot) |
| 9 | `LegendTooltip` | [L] | 7/8 | W+A | thin wrapper on #2 |
| 10 | `LegendBanner` | [L] | 7/8 | W+A | Surface + Text (persistent inline alert; sibling to Toast) |
| 11 | `LegendProgress` | [L] | 8/8 | W+A | Surface paint (`variant: bar/circle`, determinate + indeterminate) |
| 12 | `LegendSegmented` | [L] | 7/8 | W+A | on #1 (exclusive segmented choice) |

### Wave 2 — high-frequency + structural
| # | Name | Kind | Freq | Demand | Composes |
|---|---|---|---|---|---|
| 13 | `LegendRadioGroup` + `LegendRadio` | [L] | 8/8 | W | on #1 |
| 14 | `LegendSlider` | [L] | 8/8 | W | Interactive (drag) + Surface |
| 15 | `LegendDrawer` (`edge:` side/bottom sheet) | [L] | 7/8 | W | wraps `LegendModal`; handle/snap/drag-dismiss |
| 16 | `LegendMenu` | [L] | 7/8 | W+A | button-anchored action menu on #2 |
| 17 | `LegendNumberField` | [L] | 6/8 | W | on `LegendFieldCore` (decimal + stepper) |
| 18 | `LegendEmpty` | [L] | 5/8 | W+A | Surface + Text (zero-state) |
| 19 | `LegendCombobox` | [L] | 6/8 | W+A | on #2 + `LegendFieldCore` (typeahead; distinct from Dropdown) |
| 20 | `LegendAccordion` | upgrade | 6/8 | A | single-open controller over `LegendExpandable` |

### Wave 3 — domain & specialized
| # | Name | Kind | Demand | Notes |
|---|---|---|---|---|
| 21 | `LegendMarkdown` | [L] | A | block renderer (lists/tables/headings/code) over `LegendText.rich` — the biggest AI-workspace gap |
| 22 | `LegendSplitPane` | [P] | A | resizable multi-column workspace layout (MVP can start breakpoint-driven) |
| 23 | copy-to-clipboard + address-truncation utilities | [L] | W | small; ubiquitous in wallet |
| 24 | `LegendQrCode` | [L] | W | needs a QR-encode dep — **flag for maintainer approval** |
| 25 | `LegendPinField` | [L] | W | fixed-length code entry on `LegendFieldCore` (unlock/2FA) |
| 26 | `LegendStat` | [L] | W | emphasized KPI (balances/prices) |
| 27 | `LegendSteps` / `LegendTimeline` | [L] | W+A | sequential progress / tx history |
| 28 | `LegendBreadcrumb`, `LegendPagination` | [L] | — | data-navigation pair, low cost |
| 29 | `LegendCodeBlock` | [L] | A | monospace + copy |
| 30 | `LegendCitationChip`-shaped needs | app | A | covered by `LegendChip` (#6) — app-composed |

### Deferred (build only when a real need lands)
DataTable/`LegendTable` (heavy), DatePicker + Calendar (large, own effort), chart/sparkline (MVP shows price + % delta text), Rating, Carousel, file-upload dropzone, media player, HoverCard, Tour. Layout utilities (Box/Stack/Grid/Flex) are **intentionally not built** — Flutter's own layout widgets fill that role (Material-free, compose-primitives rule).

## 4. Fan-out plan

Each numbered item (or bracketed family) = one worktree agent running `legend-widget-author`. Ordering:

1. **Wave 0 first** (2 agents) — `LegendSelectionControl` and `LegendPopover` gate Wave 1's checkbox/radio/segmented/selectable-tile and tooltip/menu/combobox respectively. Merge both before fanning out Wave 1.
2. **Waves 1–3** fan out in parallel within a wave; merge one at a time behind the gate. Wave N+1 starts after Wave N merges (later waves compose earlier widgets).
3. Every agent runs the same spec, so the kit stays coherent. That spec is also the seed for the MCP's consistency layer.

## 5. Open decisions for the maintainer
- **Dependency additions**: `LegendQrCode` (#24) and any chart work need third-party packages — *resolved 2026-07-10: per-case approval; QR deferred to Wave 3.*
- **`LegendInfoItem` future**: *resolved 2026-07-10: keep both — static label/value row stays, `LegendListItem` is the new tappable tile.*
- **First-wave scope**: *resolved 2026-07-10: full march authorized (Wave 0 → 3, gate+merge per widget, check in at wave boundaries).*
- **Rich text / markdown EDITOR** (new 2026-07-10, AI-workspace requirement) — distinct from the read-only `LegendMarkdown` renderer (#21). A cross-platform (incl. web) editable surface with markdown syntax + selection. *Resolved 2026-07-11 (maintainer)*: **in-house** — built on `LegendFieldCore`/`EditableText`, wholesale editor engines rejected; existing markdown **parser** packages are acceptable dependencies where sensible; the syntax layer must be **extensible** (the team embeds domain-specific custom notations beyond CommonMark). Landscape research (parser packages + their custom-syntax extension APIs, web viability, what to borrow from super_editor/quill/appflowy) in flight → an architecture proposal (`LegendMarkdownEditor`) precedes the build. Tracked as the ROADMAP Phase 2.7 editor track.

## Sources
Industry: [Ant Design](https://ant.design/components/overview/), [MUI](https://mui.com/material-ui/all-components/), [Fluent 2](https://fluent2.microsoft.design/components/web/react/), [shadcn/ui](https://ui.shadcn.com/docs/components), [Radix](https://www.radix-ui.com/primitives/docs/components), [Chakra](https://chakra-ui.com/docs/components/concepts/overview), [Ant Design Mobile](https://mobile.ant.design/), [React Native Paper](https://callstack.github.io/react-native-paper/). App studies: session research 2026-07-10 (wallet: MetaMask/Rainbow/Phantom/Trust/Rabby/Ledger/WalletConnect; workspace: NotebookLM/ChatGPT/Claude/Perplexity/Notion AI).
