# RFC-005 — LegendMarkdownEditor: in-house markdown source editor with extensible syntax

> Status: **proposed** (2026-07-11) — the architecture for the AI-workspace editor track (ROADMAP Phase 2.7), per the maintainer decision: in-house, on `LegendFieldCore`; markdown *parser* packages acceptable; custom/extensible syntax required. Backed by the 2026-07-11 landscape research (engines super_editor / flutter_quill / appflowy_editor / fleather / re_editor vs parser packages; full matrix and sources in the session report).

## 1. Why in-house is confirmed (research verdicts)

Every wrappable engine fails at least one hard gate:

- **super_editor** — re-implements the entire input stack (own SuperTextField/IME wiring) → inherits the web IME/selection maintenance the Flutter team otherwise fixes in `EditableText`; pre-1.0, dev-channel releases.
- **flutter_quill** — Material-coupled (requires MaterialApp delegates + Material toolbar), native platform plugin, **no rich paste on web**; Delta model.
- **appflowy_editor** — heaviest deps (~20, incl. native plugins), web-build breakage history, **MPL/AGPL dual license** (outside the MIT/BSD/Apache policy).
- **fleather** — least-bad (MIT, 6 deps, no native code) but a Delta document model where markdown — and especially *custom* notation — is a lossy edge conversion; Material-leaning theming.
- **re_editor** — fine MIT source editor, but a fully custom render/input stack (own web-IME risk) built for line-numbered code, not prose.

The common failure: engines interpose their own document model between you and the source text, so domain-specific notation can never be first-class *in the markdown*. And every fork away from `EditableText` re-creates the legacy bug class DESIGN §3 was written to kill (the 1,535-line CupertinoTextField fork).

## 2. The one new dependency: `package:markdown` (dart-lang)

BSD-3, pure Dart (2 transitive deps, zero Flutter/native), verified publisher `tools.dart.dev`, actively released. Its `InlineSyntax` / `BlockSyntax` subclass API + `Document(blockSyntaxes:, inlineSyntaxes:, extensionSet:)` is exactly the required extension point: a domain notation (e.g. `@[ref:…]` inline, `:::note` block) is a ~30-line syntax subclass emitting a custom `Element`. **Approved dependency class per the 2026-07-11 maintainer decision** ("build upon existing markdown packages").

## 3. Architecture

The editor is a **markdown source editor**: the document *is* plain markdown text (portable, diffable, AI-prompt-friendly); the editor styles the source in place and renders a live preview beside it.

1. **`LegendMarkdownEditingController extends TextEditingController`** — overrides `buildTextSpan(context, style, withComposing)` to return a styled span tree over the *unchanged* source. Hard rule: concatenated span text `==` `controller.text` exactly (style only — never hide/insert characters; that is what breaks IME composing regions). Preserve the composing underline.
2. **Incremental line tokenizer** — block state per line (heading/fence/quote/list, with open-fence carry-over), inline marks by regex within the line, only dirty lines re-tokenized on `TextEditingValue` diffs. A highlighter, not a full parse; no parser on the hot path.
3. **One syntax registry, two consumers** — each custom notation is registered once (`InlineSyntax`/`BlockSyntax` + a highlight rule + a span/widget builder) and consumed by BOTH the editor's highlighter and the `LegendMarkdown` renderer, so notation can never diverge between editing and rendering.
4. **`LegendFieldCore` plumbing additions** (all existing `EditableText` params, no invention): `maxLines: null`, `scrollController`/`scrollPhysics`, `textInputAction: newline`, selection-controls/context-menu pass-through; `contentInsertionConfiguration` deferrable.
5. **Keyboard conveniences as pure `TextEditingValue → TextEditingValue` transforms** (unit-testable per the repo's norm): Enter continues list markers, Tab indent/outdent, wrap-selection toolbar actions (`**`, `_`, `` ` ``), fence auto-close.
6. **Theming** — a `MarkdownSourceStyle` `@Style` value class (heading/emphasis/code/link/marker/custom-tag styles) resolved through the standard four-level chain; the controller consumes it via `listen: false` (imperative-consumer pattern).
7. **Preview** — `package:markdown` parse → AST → the RFC-004 #21 **`LegendMarkdown`** renderer (`LegendText.rich` spans + block widgets), debounced ~100–200 ms. Scroll-sync deferrable.

Borrowed ideas (not code): super_editor's stylesheet-rule concept → `MarkdownSourceStyle`; appflowy's shortcut-event registry shape → the convenience layer; markdown_widget's tag→span generator → `LegendMarkdown`.

## 4. Scope & sequencing

- **Ships**: source editor + highlighter + custom-syntax registry, field-core plumbing, keyboard conveniences, `MarkdownSourceStyle`, `LegendMarkdown` renderer (#21 — needed by the catalog anyway), toolbar, playground rung, tests. Estimated ~4–5 focused weeks total; the renderer is the natural first slice (unblocks chat display in the workspace app before the editor lands).
- **Deferred**: WYSIWYG (the later path is *hybrid source rendering* — richer styling inside the same controller, e.g. dimmed markers/checked boxes — never a model swap), scroll-synced preview, rich-content paste.
- **Sequencing vs the waves**: renderer (#21) stays in Wave 3; the editor builds on it as its own track — after Wave 1 merges, so it can compose `LegendTabs`/`LegendCodeBlock` conventions where useful.

## 5. Decisions locked here
- Document format = plain markdown text; no Delta/node model, ever (custom syntax must stay first-class in source).
- `package:markdown` is the parser/serialization backbone; syntax extensions are defined once and shared highlighter+renderer.
- Never hide/insert characters in `buildTextSpan`.
- No wrapped editor engine; re-evaluate only if requirements change to true WYSIWYG.
