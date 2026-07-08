# 05 — Buttons, Text, and Input/Form Components

Legacy documentation of `nomo_ui_kit` (repo: `/Users/thomas/src/legend-ui`) as rewrite preparation.
All line numbers refer to the state of `main` at commit `bccec60`.

Covered files:

| Area | File |
|---|---|
| Button base | `/Users/thomas/src/legend-ui/lib/components/buttons/base/nomo_button.dart` (320 LOC) |
| Primary button | `/Users/thomas/src/legend-ui/lib/components/buttons/primary/nomo_primary_button.dart` |
| Secondary button | `/Users/thomas/src/legend-ui/lib/components/buttons/secondary/nomo_secondary_button.dart` |
| Text button | `/Users/thomas/src/legend-ui/lib/components/buttons/text/nomo_text_button.dart` |
| Link button | `/Users/thomas/src/legend-ui/lib/components/buttons/link/nomo_link_button.dart` |
| Text | `/Users/thomas/src/legend-ui/lib/components/text/nomo_text.dart` (207 LOC) |
| Animated default text style | `/Users/thomas/src/legend-ui/lib/animations/implicit/animated_nomo_default_textstyle.dart` |
| Input | `/Users/thomas/src/legend-ui/lib/components/input/textInput/nomo_input.dart` (594 LOC) |
| Input render layout | `/Users/thomas/src/legend-ui/lib/components/input/textInput/text_layout.dart` (317 LOC) |
| Editable core (Flutter fork) | `/Users/thomas/src/legend-ui/lib/components/input/cupertino_text_input.dart` (1535 LOC) |
| Form | `/Users/thomas/src/legend-ui/lib/components/input/form/nomo_form.dart` (82 LOC) |

---

## 1. Architecture overview & inheritance

There is **no class inheritance** between button variants. The relationship is:

```
NomoButtonMixin (interface-only mixin, nomo_button.dart:6-27)
 ├── NomoButton            (StatefulWidget — the actual behavior/rendering base)
 ├── PrimaryNomoButton     (StatelessWidget — composes/wraps a NomoButton)
 ├── SecondaryNomoButton   (StatelessWidget — composes/wraps a NomoButton)
 ├── NomoTextButton        (StatelessWidget — composes/wraps a NomoButton)
 └── NomoLinkButton        (StatefulWidget — does NOT use NomoButton at all;
                            implements its own hover/tap animation)
```

- `NomoButtonMixin` (`nomo_button.dart:6-27`) is a pure **abstract getter contract** (padding, margin, onPressed, onSecondaryPressed, enabled, elevation, width, height, backgroundColor, foregroundColor, selectionColor, borderRadius, border, shape, expandToConstraints, splashColor, focusColor, highlightColor, hoverColor, focusNode). It exists mainly so the theme generator (`getFromContext`) can treat all button widgets uniformly. Variants that don't use a property override the getter to return `null` and comment it `/// Not used` — i.e., the contract is broader than any variant actually needs.
- All variants except `NomoLinkButton` delegate rendering, hit-testing, hover animation, and sizing to `NomoButton`. `NomoLinkButton` re-implements hover/tap-down color animation from scratch (duplicated logic, see §6).
- `ActionType` is declared inside the **primary** button file (`nomo_primary_button.dart:10-16`) but is also used by `SecondaryNomoButton` — an awkward cross-file coupling for a rewrite to fix.

Theming: each themed variant carries `@NomoComponentThemeData('<name>')` and per-field `@NomoColorField` / `@NomoSizingField` / `@NomoConstant` annotations. The build_runner generator emits `*.theme_data.g.dart` with `<X>ColorData`, `<X>SizingData`, `<X>ThemeData`, `<X>ThemeDataNullable`, `<X>ThemeOverride` classes and a `getFromContext(context, widget)` resolver that merges: widget-instance value → local `ThemeOverride` → global theme → annotated default.

---

## 2. `NomoButton` (base)

**File:** `/Users/thomas/src/legend-ui/lib/components/buttons/base/nomo_button.dart`
**Purpose:** the single behavioral base for all buttons: Material surface + InkWell tap handling + hover-driven color animation + sizing/margin wrapper. Not themed itself (no annotations); variants feed it resolved theme values.

### Constructor parameters (`nomo_button.dart:86-115`)

| Name | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Content. |
| `onPressed` | `VoidCallback?` | null | Tap handler; passed to `InkWell.onTap` only when `enabled ?? true` (line 208). |
| `onSecondaryPressed` | `VoidCallback?` | null | Right-click handler (`InkWell.onSecondaryTap`, line 210). **Not gated by `enabled`** — fires even when disabled. |
| `enabled` | `bool?` | null (treated as `true`) | Gates `onTap` and mouse cursor only. Does **not** stop hover animation or secondary tap. |
| `focusNode` | `FocusNode?` | null | Forwarded to `InkWell.focusNode`. |
| `enableInkwellFeedback` | `bool` | `true` | **DEAD CODE** — declared (line 31) but never read in `build`. |
| `cursor` | `MouseCursor` | `SystemMouseCursors.click` | Used when enabled; `basic` when disabled (lines 215-217). |
| `gradient` | `Gradient?` | null | Wraps everything in a `DecoratedBox` (lines 265-276). |
| `image` | `DecorationImage?` | null | Same `DecoratedBox` wrapper. |
| `backgroundPainter` | `CustomPainter?` | null | `CustomPaint.painter` behind the InkWell (line 201-202). |
| `shape` | `BoxShape?` | null | `BoxShape.circle` produces a `CircleBorder` shape (lines 164-166). |
| `shapeBorder` | `ShapeBorder?` | null | Explicit shape; wins over `shape`/`borderRadius` (line 162-163). |
| `width` / `height` | `double?` | null | Fixed size via outer `SizedBox` (lines 290-294, 302-305). |
| `backgroundColor` | `Color?` | null | `Material.color`. |
| `foregroundColor` | `Color?` | null | Injected into descendants via `NomoTextTheme` + `IconTheme` (lines 249-257) when `selectionColor == null`. |
| `selectionColor` | `Color?` | null | Hover target color; enables the hover animation path. |
| `elevation` | `double` | `0.0` | `Material.elevation` — **not animated**; jumps instantly. |
| `border` | `BorderSide?` | null | Side of the computed `RoundedRectangleBorder`/`CircleBorder`. |
| `padding` | `EdgeInsetsGeometry?` | null → zero | Inner padding inside InkWell (line 218-219). |
| `margin` | `EdgeInsetsGeometry?` | null → zero | Outer padding around SizedBox (lines 288, 300). |
| `borderRadius` | `BorderRadiusGeometry?` | null | Builds `RoundedRectangleBorder` when `shapeBorder`/`shape` absent (lines 167-170). |
| `expandToConstraints` | `bool?` | null | When true, uses `LayoutBuilder` to expand to `constraints.maxWidth` (see below). |
| `splashColor`, `hoverColor`, `highlightColor`, `focusColor` | `Color?` | null | Forwarded to InkWell, **all default to `Colors.transparent`** (lines 211-214) — so by default there is no ink feedback whatsoever. |

### State handling / animation (`_NomoButtonState`, lines 121-158)

- One 200 ms `AnimationController` + `ColorTween(begin: foregroundColor, end: selectionColor)`.
- Tween is (re)created in **both** `didChangeDependencies` (136-143) **and** `didUpdateWidget` (145-152) with identical code — duplication.
- **Hover** (`MouseRegion` lines 203-205): `onEnter → controller.forward()`, `onExit → controller.reverse()`. Runs **even when `enabled == false`** — a disabled secondary button still animates its border/text color on hover.
- There is **no pressed / tap-down state** in the base at all (no scale, no highlight unless a variant passes `highlightColor`). Focus visuals: only `InkWell.focusColor`, transparent by default.
- The animated color is applied in two places, both gated on `selectionColor != null && border != null` vs. content:
  1. **Border**: `AnimatedBuilder` wrapping `Material` with `_shapeBorder.copyWithColor(animation.value)` (lines 176-190). The `copyWithColor` extension (lines 311-320) only works for `OutlinedBorder`s.
  2. **Content**: `AnimatedBuilder` wrapping `NomoTextTheme(color)` + `IconTheme(color)` (lines 228-246), so text/icons cross-fade `foregroundColor → selectionColor` on hover.
- If `selectionColor == null` but `foregroundColor != null`, a static `NomoTextTheme`/`IconTheme` wrapper is used instead (lines 247-257).

### Layout quirks

- If `width != null` the child is wrapped in `Center` (line 222); if only `height != null` it's wrapped in a single-child `Column(mainAxisAlignment: center)` (lines 223-227) — an idiosyncratic centering strategy that behaves differently horizontally vs. vertically.
- `expandToConstraints` (lines 278-298): wraps in `LayoutBuilder`; if `maxWidth` is infinite falls back to `width`; otherwise takes `maxWidth`. The inner `switch` re-checks `widget.expandToConstraints ?? false` (line 284) even though the outer `if` already guaranteed it's true — redundant branch.
- Shape resolution (lines 162-172): `shapeBorder` > `shape == circle` > `borderRadius` > null. If all null, `Material` gets a null shape → rectangle.

### Usage example

```dart
NomoButton(
  onPressed: () {},
  backgroundColor: context.colors.primary,
  foregroundColor: Colors.white,
  borderRadius: BorderRadius.circular(8),
  padding: const EdgeInsets.all(12),
  child: const Text('Raw base button'),
)
```

---

## 3. `PrimaryNomoButton`

**File:** `/Users/thomas/src/legend-ui/lib/components/buttons/primary/nomo_primary_button.dart`
**Purpose:** filled CTA button; text and/or icon (or arbitrary `child`), loading spinner support, danger/disabled variants via `ActionType`.

### `ActionType` enum (lines 10-16) — shared state machine for primary & secondary

| Value | Background | Foreground | onPressed | Cursor | Extra |
|---|---|---|---|---|---|
| `def` | theme `backgroundColor` (default `primaryColor`) | theme `foregroundColor` (default white) | active | click | — |
| `danger` | `context.colors.error` | theme foreground | **active** | click | — |
| `disabled` | `disabledBackgroundColor ?? colors.disabled` | `colors.onDisabled` | **still active!** (only `nonInteractive` nulls `onPressed`, lines 303-306) | click | Visual-only disable — quirk/bug. |
| `nonInteractive` | disabled colors | `onDisabled` | null | `forbidden` (lines 307-310) | True disable. |
| `loading` | theme background | theme foreground | **still active** — user can tap while loading | click | Icon replaced by `Loading` spinner sized `height/3` or 24 (lines 181-188). |

Note the overlap with the independent `enabled` parameter — there are **two orthogonal disable mechanisms** (`enabled: false` gates the InkWell tap in the base; `ActionType.disabled` only changes colors). CLAUDE.md examples set both, suggesting users must know to do so.

### Constructor parameters (lines 97-135)

| Name | Type | Default | Meaning |
|---|---|---|---|
| `text` | `String?` | null | Label rendered as `NomoText` (bold forced, line 171-173). |
| `icon` | `IconData?` | null | Leading (or trailing, see `textFirst`) icon. |
| `child` | `Widget?` | null | Custom content; asserts mutually exclusive with text/icon (lines 132-135). |
| `type` | `ActionType` | `ActionType.def` | See table above. |
| `textFirst` | `bool?` | null → `false` | **Added in commit `ba010a3` ("add textfirst parameter to primarynomobutton")**. When true, text is placed before the icon/spinner in the Row/Column (arms at lines 226-274). |
| `direction` | `Axis` | `Axis.horizontal` | Row vs Column content layout. |
| `spacing` | `double?` | `12` | Gap between icon and text. |
| `textStyle` | `TextStyle?` | null | Copied with resolved foreground color + `FontWeight.bold` (line 171-173). If null, color flows via `NomoTextTheme` from the base instead. |
| `iconSize` | `double?` | null | Icon size. |
| `translate` | `bool?` | null → true | Passes through to `NomoText.translate`. |
| `gradient` / `image` / `backgroundPainter` | — | null | Forwarded to base. |
| `disabledBackgroundColor` | `Color?` | null | Overrides `colors.disabled` for disabled/nonInteractive. |
| `shapeBorder`, `shape`, `width`, `height`, `margin`, `expandToConstraints`, `focusNode`, `onPressed`, `onSecondaryPressed`, `enabled` | — | null | Forwarded to base. |

### Themeable properties (annotations lines 59-89; generated `nomo_primary_button.theme_data.g.dart`)

| Property | Annotation | Default |
|---|---|---|
| `backgroundColor` | Color | `primaryColor` |
| `foregroundColor` | Color | `Colors.white` |
| `elevation` | Color(!) | `1.0` |
| `padding` | Sizing | `EdgeInsets.all(16)` |
| `borderRadius` | Color(!) | `BorderRadius.circular(8)` |
| `splashColor` / `hoverColor` / `highlightColor` / `focusColor` | Color | `null` |

(`elevation` and `borderRadius` live in the *Color* theme bucket — the annotation taxonomy is loose.)

### Behavior notes

- `padding` and `borderRadius` are passed to the base **from the resolved theme** (`theme.padding`, `theme.borderRadius`, lines 300-301) so widget-level overrides work through the merge. (Contrast with secondary/text buttons, §4/§5, which pass raw widget values.)
- `factory PrimaryNomoButton.iconButton` (lines 137-160): 42×42 circular transparent icon button preset; maps a `disabled` flag to `ActionType.nonInteractive` + `enabled: !disabled`.
- **Complexity hotspot:** the `effectiveChild` switch (lines 175-275) has **4 nearly identical arms** ((horizontal|vertical) × (textFirst true|false)), each duplicating the `Loading` spinner block and spacing logic — ~100 lines that reduce to ~15 with a list-reverse. The loading spinner size expression `switch (height) { final double height => height / 3, _ => 24 }` is copy-pasted 4×.
- Quirk in spacing: when loading with text, both the `icon != null && text != null` spacer **and** the `text != null && type == loading` spacer can apply (lines 191-193), giving double spacing if an icon was also set.

### Usage

```dart
PrimaryNomoButton(
  text: 'Save',
  icon: Icons.save,
  textFirst: true,                    // text before icon (new param)
  type: saving ? ActionType.loading : ActionType.def,
  onPressed: saving ? null : save,
  expandToConstraints: true,
)
```

---

## 4. `SecondaryNomoButton`

**File:** `/Users/thomas/src/legend-ui/lib/components/buttons/secondary/nomo_secondary_button.dart`
**Purpose:** outlined button; hover animates border + text/icon color from `foregroundColor` to `selectionColor` (this is the only shipped variant that exercises the base's `selectionColor` machinery).

### Constructor parameters (lines 90-125)

Same surface as primary minus `textFirst`, `gradient`, `image`, `backgroundPainter`, `disabledBackgroundColor`, plus:

| Name | Type | Default | Meaning |
|---|---|---|---|
| `border` | `BorderSide?` | theme | Outline; animated to `selectionColor` on hover (base lines 176-190). |
| `selectionColor` | `Color?` | theme | Hover color for border + content. |

### Themeable properties (annotations lines 44-88)

| Property | Default |
|---|---|
| `backgroundColor` | `Colors.white` |
| `foregroundColor` | `Color(0xAA000000)` |
| `elevation` | `0.0` |
| `selectionColor` | `primaryColor` |
| `border` | `BorderSide(color: Color(0xAA000000))` |
| `borderRadius` | `BorderRadius.circular(8)` |
| `padding` | `EdgeInsets.all(16)` |
| `splashColor`/`hoverColor`/`highlightColor`/`focusColor` | null |

### ActionType mapping (lines 167-208)

- Background: disabled/nonInteractive → `colors.disabled`, else theme.
- Foreground: disabled states → `onDisabled`; `danger` → `colors.error`.
- SelectionColor (hover target): `danger` → `error.darken()`; `disabled` → `onDisabled.darken()`; `nonInteractive` → `onDisabled`; else theme. So **disabled buttons still hover-animate** (base doesn't gate the MouseRegion) — they just animate to a similar gray.
- Same `disabled`-keeps-`onPressed` quirk as primary (lines 194-197 only null for `nonInteractive`).

### Quirks / bugs

- **Theme padding bypassed:** line 187 passes `padding: padding` (the raw constructor value) instead of `theme.padding` — if the caller doesn't set padding, the themed default `EdgeInsets.all(16)` is silently ignored and the button gets zero padding. Primary passes `theme.padding`; this is an inconsistency almost certainly unintended.
- **Layout hazard:** the vertical arm wraps `NomoText` in `Expanded` inside a `Column(mainAxisSize: MainAxisSize.min)` (lines 147-162). `Expanded` in a min-sized/unbounded column throws in unbounded contexts; works only when `height` is set. Horizontal arm has no `Expanded`. No loading spinner support at all (unlike primary) even though `ActionType.loading` is accepted — `loading` silently renders as `def`.
- Text uses `useInheritedTheme: true` (lines 143, 158) so the hover `NomoTextTheme` color wins over `textStyle.color` — subtle priority inversion vs. primary.

### Usage

```dart
SecondaryNomoButton(
  text: 'Process',
  icon: Icons.refresh,
  onPressed: process,
  selectionColor: context.colors.primary, // hover color
)
```

---

## 5. `NomoTextButton`

**File:** `/Users/thomas/src/legend-ui/lib/components/buttons/text/nomo_text_button.dart`
**Purpose:** flat/borderless text button — a `NomoButton` with `backgroundColor: Colors.transparent` and no elevation/border.

### Constructor parameters (lines 75-97)

| Name | Type | Default | Meaning |
|---|---|---|---|
| `text` | `String?` | null | Label (`NomoText`); assert `child != null || text != null` (line 97). |
| `child` | `Widget?` | null | Custom content. |
| `textStyle` | `TextStyle?` | null | Style for the label. |
| `translate` | `bool?` | null → true | Translation flag. |
| `foregroundColor`, `padding`, `borderRadius`, `splash/hover/highlight/focusColor` | themed | see below | — |
| `width`, `height`, `margin`, `shape`, `expandToConstraints`, `enabled`, `onPressed`, `onSecondaryPressed`, `focusNode` | — | null | Forwarded to base. |

No `ActionType`, no icon, no loading support.

### Themeable properties (annotations lines 39-63)

| Property | Default |
|---|---|
| `foregroundColor` | `Colors.black87` |
| `padding` | `EdgeInsets.all(16)` |
| `borderRadius` | `BorderRadius.circular(8)` |
| `splashColor`/`hoverColor`/`highlightColor`/`focusColor` | null |

### Quirks

- **Same theme-padding bypass as secondary:** line 109 passes raw `padding` to the base, so the themed `EdgeInsets.all(16)` default never applies unless the generator merge is consulted — it isn't (`theme.padding` unused). Also `foregroundColor` **is** taken from theme (line 103), making the inconsistency obvious within a single build method.
- No hover/selection feedback at all by default (all InkWell colors transparent, no `selectionColor`) — visually inert on hover unless themed.

---

## 6. `NomoLinkButton`

**File:** `/Users/thomas/src/legend-ui/lib/components/buttons/link/nomo_link_button.dart`
**Purpose:** hyperlink-style text with hover color + tap-down color (Ant-Design-like blue palette).

**Does not use `NomoButton`.** It's a `StatefulWidget` with two 200 ms `AnimationController`s (lines 110-120):

- `_controller`: hover — `ColorTween(foregroundColor → selectionColor)`, driven by `MouseRegion.onEnter/onExit` (lines 165-167).
- `_controllerTapDown`: press — `ColorTween(selectionColor → tapDownColor)`, driven by `GestureDetector.onTapDown/onTapUp` (lines 171-177). An `isClicked` bool selects which animation's value is displayed (line 162).
- Tweens rebuilt in both `didChangeDependencies` and `didUpdateWidget` (same duplication pattern as the base).

### Constructor parameters (lines 78-93)

| Name | Type | Default | Meaning |
|---|---|---|---|
| `text` | `String` | required | Label. |
| `textStyle` | `TextStyle?` | null | Style (color overridden via `NomoTextTheme` + `useInheritedTheme: true`, line 183). |
| `foregroundColor` | themed `Color(0xFF1677ff)` | Idle color. |
| `selectionColor` | themed `Color(0xFF4096ff)` | Hover color. Annotated `@NomoSizingField<Color>` (line 43) — a **color in the sizing theme bucket**, clearly a mistake. |
| `tapDownColor` | themed `Color(0xFF0958d9)` | Pressed color. |
| `padding` | themed `EdgeInsets.all(16)` | Around the text. |
| `onPressed` | `VoidCallback?` | null | Tap. |
| `enabled`, `width`, `height`, `margin`, `focusNode`, `onSecondaryPressed` | — | null | **Accepted but completely ignored in `build`** (lines 158-189 use none of them) — dead parameters. |

### Quirks / bugs

- No `onTapCancel` handler: if the user presses and drags away, `isClicked` stays true and the color can be stuck at `tapDownColor` until the next full tap cycle.
- `enabled: false` does nothing; `onSecondaryPressed`, `focusNode`, `width`, `height`, `margin` do nothing.
- No keyboard focus/activation support at all (plain `GestureDetector`).
- This is the third independent implementation of "animate a color on hover" in the buttons folder (base border path, base content path, link button) — prime consolidation target.

---

## 7. `NomoText`

**File:** `/Users/thomas/src/legend-ui/lib/components/text/nomo_text.dart`
**Purpose:** themed `Text` wrapper: pulls style from `NomoDefaultTextStyle`, color from `NomoTextTheme`, optional translation via `NomoTextTranslator`.

### History — the auto-fit algorithm was removed

Commit **`30aba3e` "Adjust Text to non resizable"** (Nov 16 2025) converted `NomoText` from a `StatefulWidget` with a full auto-fit engine into a thin `StatelessWidget` over `Text` (187 lines deleted). The removed algorithm (documented here because the constructor API still advertises it):

1. Started from `fontSize ?? style.fontSize` captured once in `initState` (`_initialFontSize`).
2. Inside a `LayoutBuilder`, laid the text out with a `TextPainter`, summing `computeLineMetrics()` heights.
3. **Shrink loop:** while `totalHeight > maxHeight || didExceedMaxLines` and `fontSize > minFontSize`, decreased the font size — either stepping down through the discrete `fontSizes` list (`firstWhere(size < fontSize)`) or by `decreaseBy` (default 1) — re-laying-out each iteration.
4. **Grow loop:** while it fit and still exceeded max lines(!) and `fontSize < initial`, increased symmetrically, backing off one step on overshoot.
5. **`textShortener` loop:** if still overflowing, repeatedly called `textShortener(text, length-1)` (e.g. middle-ellipsis for addresses) until it fit.
6. `fitHeight` mode instead binary-stepped font size down from `maxHeight` in 0.5 steps until the laid-out height fit (this helper, `findStyleForFitHeight`, still exists at lines 83-119).

This was O(iterations × full text layout) per build per text — a known perf hotspot, which is presumably why it was ripped out.

### Current state (post-`30aba3e`)

`build` (lines 54-80): resolve translator → resolve color → `copyWith` on `style ?? NomoDefaultTextStyle.of(context)` → plain `Text`.

Color resolution (lines 60-62): with `useInheritedTheme: true` the priority is `color` param → `NomoTextTheme` ancestor → `style.color`; otherwise `color` → `style.color` → `NomoTextTheme`. This flag is how buttons force hover colors to win over explicit text styles.

### Constructor parameters (lines 4-52)

| Name | Type | Default | Live? | Meaning |
|---|---|---|---|---|
| `text` | `String` | required | yes | Content. |
| `style` | `TextStyle?` | null | yes | Base style; falls back to `NomoDefaultTextStyle.of(context)` (asserts if absent, line 153). |
| `textAlign`, `textDirection`, `overflow`, `maxLines` | std | null | yes | Forwarded to `Text`. |
| `color` | `Color?` | null | yes | Highest-priority color. |
| `fontWeight`, `fontSize`, `opacity` | — | null | yes | `copyWith` overrides; `opacity` applied via `withValues(alpha:)`. |
| `translate` | `bool` | `true` | yes | Look up `NomoTextTranslator` and translate. |
| `useInheritedTheme` | `bool` | `false` | yes | Color priority flip (see above). |
| `fit` | `bool` | `false` | **DEAD** | No effect since `30aba3e` (a `// if (!widget.fit) {` comment remains at line 71). |
| `fitHeight` | `bool?` | null | **DEAD** | Only survives in asserts (lines 28-32). |
| `fontSizes` | `List<double>?` | null | **DEAD** | Only survives in assert (lines 24-27). |
| `decreaseBy` | `double` | `1` | **DEAD** | — |
| `minFontSize` | `double` | `6` | **DEAD** | — |
| `textShortener` | `String Function(String,int)?` | null | **DEAD** | — |

7 dead parameters + 2 stale asserts. Any downstream app relying on `fit: true` now silently overflows.

### Companions in the same file

- `findStyleForFitHeight` (lines 83-119): orphaned fit helper, no callers in the repo.
- `calculateTextSize` (lines 121-139): TextPainter measuring helper — still used by `cupertino_text_input.dart:1451,1465` to measure the floating title height.
- `NomoDefaultTextStyle` (lines 141-167): InheritedWidget carrying the ambient `TextStyle`; `updateShouldNotify` always `true` (over-notifies).
- `NomoTextTheme` (lines 169-186): InheritedWidget carrying a single `Color` (buttons use it for hover color injection); also always notifies.
- `NomoTextTranslator` (lines 188-207): InheritedWidget with `String Function(String)`; `updateShouldNotify` always `false` — swapping the translator at runtime (e.g. locale change) will **not** rebuild dependents.

---

## 8. `AnimatedNomoDefaultTextStyle`

**File:** `/Users/thomas/src/legend-ui/lib/animations/implicit/animated_nomo_default_textstyle.dart`
**Purpose:** `ImplicitlyAnimatedWidget` that tweens a `TextStyle` (via `TextStyleTween`) and republishes it as `NomoDefaultTextStyle` — the Nomo analogue of Flutter's `AnimatedDefaultTextStyle`.

| Param | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Subtree. |
| `style` | `TextStyle` | required | Target style; changes animate over `duration`. |
| `duration` / `curve` / `onEnd` | std | — | From `ImplicitlyAnimatedWidget`. |

Used by `NomoInput` (nomo_input.dart:484-487) to animate the input's text style (e.g. disabled-color transitions). Straightforward; no issues. Note: interpolating `TextStyle`s with different `fontSize`/inherit settings uses `TextStyle.lerp` semantics — fine here since styles come from the same base.

---

## 9. `NomoInput` — the flagship input

**File:** `/Users/thomas/src/legend-ui/lib/components/input/textInput/nomo_input.dart`
**Purpose:** fully themed text field: animated border/decoration state machine, title above, placeholder (optionally floating as title), animated error text below, validation, form integration, leading/trailing widgets. Composed as:

```
NomoInput (state machine, notifiers, validation, decoration)
 └─ AnimatedNomoDefaultTextStyle (animated text style)
     └─ CupertinoInput (forked Flutter editable, cupertino_text_input.dart)
         └─ _TextInputDependetAttachment (placeholder/title animation) [sic]
             └─ TextInputLayoutDelegate → TextInputLayoutRenderbox (text_layout.dart)
                 └─ EditableText
```

### Constructor parameters (lines 145-208)

| Name | Type | Default | Meaning |
|---|---|---|---|
| `leading` / `trailling` [sic] | `Widget?` | null | Prefix/suffix widgets (note the typo `trailling`, propagated through 3 files and an enum). |
| `title` | `String?` | null | Static label above the field (lines 473-480). |
| `placeHolder` | `String?` | null | Placeholder inside the field. |
| `usePlaceholderAsTitle` | `bool` | `false` | Floating-label mode: placeholder animates up into a small title on focus/content (see §10). |
| `style` / `placeHolderStyle` / `titleStyle` / `errorStyle` | `TextStyle?` | null | Defaults derived from `NomoDefaultTextStyle` with `onDisabled` / `error` colors (lines 450-456). |
| `valueNotifier` | `ValueNotifier<String>?` | null | External two-way value binding (mutually exclusive with `textEditingController`, assert line 205-208). |
| `textEditingController` | `TextEditingController?` | null | External controller. |
| `errorNotifier` | `ValueNotifier<String?>?` | null | External error binding; non-null value → error state. |
| `validator` | `String? Function(String)?` | null | Returns error text or null. |
| `autoValidate` | `bool` | `false` | Validate on every change (otherwise only on form-triggered validation). |
| `formKey` | `String?` | null | Registers field in enclosing `NomoForm` (see §12). |
| `initialText` | `String?` | null | Initial value; also re-applied when it *changes* in `didUpdateWidget` via `Future.microtask` (lines 268-275) — an odd "controlled-ish" behavior. |
| `minLines` / `maxLines` | `int?` | null | Multiline config (forwarded to `EditableText`). |
| `maxLength` | `int?` | null | Length limit (LengthLimitingTextInputFormatter, cupertino side line 1178-1182). |
| `maxParagraphs` | `int?` | null | Custom `ParagraphLimitingTextInputFormatter` (lines 571-594) limiting `\n`-separated paragraphs — truncates at the *last* newline, which can delete more than one char of input. |
| `inputFormatters` | `List<TextInputFormatter>?` | null | Appended after the paragraph limiter (lines 521-527). |
| `keyboardType`, `textInputAction`, `autoCorrect` (default `false`), `obscureText`, `textAlign` (default `start`), `autoFocus` | std | — | Forwarded. |
| `enabled` | `bool` | `true` | Disables editing (readOnly + IgnorePointer downstream) and grays the style (lines 462-464). |
| `scrollable` | `bool` | `false` | Creates a `ScrollController`; otherwise `NeverScrollableScrollPhysics` (lines 499-501). |
| `height` | `double?` | null | Fixed height container; asserted incompatible with `usePlaceholderAsTitle` — assert message: *"Not supported please ask Thomas to implement"* (line 203). |
| `onChanged`, `onFocusChanged`, `onTap`, `onTapOutside`, `onFieldSubmitted` | callbacks | null | Forwarded. |
| `top` / `bottom` | `Widget?` | null | Widgets inside the decorated box above/below the editable row. |
| `hitTestBehavior` | `HitTestBehavior` | `translucent` | For the selection gesture detector. |
| `centerPlaceholder` | `bool` | `false` | Vertically center placeholder (see render box §11). |
| `focusNode` | `FocusNode?` | null | External focus node. |

### Themeable properties (annotations lines 75-143; generated `nomo_input.theme_data.g.dart`)

| Property | Default |
|---|---|
| `elevation` | null |
| `background` | `Colors.white` |
| `errorColor` | `Colors.redAccent` (declared but not referenced in build — error color comes from `errorStyle`/`errorBorder`; likely dead) |
| `padding` | `EdgeInsets.symmetric(h:16, v:12)` |
| `textSpacing` | `8.0` |
| `borderRadius` | `BorderRadius.circular(8)` |
| `border` | transparent, width 2 |
| `selectedBorder` | `primaryColor`, width 2 |
| `errorBorder` | `Colors.red`, width 2 |
| `selectedErrorBorder` | `Colors.redAccent`, width 2 |
| `margin` | `EdgeInsets.zero` |
| `duration` | 200 ms |
| `curve` | `Curves.easeInOut` |
| `titleSpacing` | `2.0` |

### State machine (`InputState`, lines 14-20; `changeToState`, lines 416-446)

States: `nonError`, `selected`, `nonSelected`, `error`, `selectedWithError`. Inputs come from two listeners:

- `focusChanged` (360-369): focus → `selected`, blur → `nonSelected`.
- `errorChanged` (407-414): error text set → `error`, cleared → `nonError`.

`changeToState` merges the *requested* event with the *current* state via a transition table (lines 419-429):

| (current, requested) | resulting state |
|---|---|
| (selected, error) | selectedWithError |
| (selectedWithError, error) | selectedWithError |
| (error, selected) | selectedWithError |
| (selectedWithError, nonSelected) | error |
| (selectedWithError, nonError) | selected |
| anything else | requested state as-is |

The enum conflates **events** (`nonError`, `nonSelected` are really events, not states) with **states** — e.g. after blur-with-no-error the stored state is literally `nonSelected`. It works but is confusing; a rewrite should model `{focused: bool, hasError: bool}` instead.

Each transition maps to one of four precomputed `BoxDecoration`s (default/selected/error/selectedError, lines 224-234, rebuilt with elevation shadows in `didUpdateWidget` 279-295) and pushes a `BoxDecorationTween(begin: old.end, end: new)` plus a `shouldAnimate` flag into `decorationNotifier` (443-444). The Cupertino layer consumes it with `TweenAnimationBuilder` (cupertino lines 1314-1339), animating the border color/width. `shouldAnimate=false` is used for initial/error-on-mount states (line 319).

### Value/validation plumbing

Two-way sync between `textController` and `valueNotifier`, each listener guarded by an equality check to break cycles (`textControllerChanged` 371-379, `notifierChanged` 381-389). Both paths call `validate(false)`, update the form value, and fire `onChanged`.

`validate(bool fromForm)` (391-400): skips unless `fromForm || autoValidate`; runs `validator`, writes result to `errorNotifer` [sic], reports validity to the form's `NomoFormValidator`.

Quirks/bugs:

- `formValidate` (402-405) calls `validate(true)` — which already calls `formValidator?.validateField` — then calls `validateField` **again** with the boolean result. Harmless duplication, but shows the flow wasn't reasoned through.
- If `validator == null`, `validate` returns `true` **without ever telling the form** — but `NomoFormValidator.addField` initialized the field to `false` (form line 70-73), so a validator-less field keeps `isValid == false` for the whole form **unless** its value changes at least once... actually no: `validateField` is only called from `validate()` paths that require a validator. **A `NomoInput` with a `formKey` but no `validator` permanently pins the form invalid** unless something else flips it. Rewrite must define semantics here.
- `didChangeDependencies` (302-330) re-adds the `formValidate` listener and re-registers the field every time dependencies change, with no dedup — potential duplicate listeners after theme changes (ChangeNotifier allows duplicates; each fires separately).
- Dispose ordering bug (333-337): when the focus node is internal, `focusNode.dispose()` runs **before** `focusNode.removeListener(focusChanged)` — removing a listener from a disposed node throws in debug mode paths; order should be reversed.
- `errorNotifer` typo; `trailling` typo.
- The title/error column (lines 469-564): error text is an `AnimatedSize` + `AnimatedOpacity` + `Offstage` sandwich that grows in/fades in; it's left-padded by the theme padding's left inset (line 542) so it aligns with the text.

### Usage

```dart
NomoInput(
  title: 'Email',
  placeHolder: 'you@example.com',
  leading: const Icon(Icons.email),
  formKey: 'email',
  autoValidate: true,
  validator: (v) => v.contains('@') ? null : 'Invalid email',
)
```

---

## 10. `CupertinoInput` (forked Flutter editable layer)

**File:** `/Users/thomas/src/legend-ui/lib/components/input/cupertino_text_input.dart` (1535 LOC)
**Purpose:** a vendored, modified copy of Flutter's `CupertinoTextField` (Flutter copyright header, lines 1-3) that swaps the box decoration for `NomoInput`'s animated `decorationTween`, and replaces the standard prefix/suffix/placeholder Row with the custom `TextInputLayoutDelegate` render object plus the floating-title animation.

Not documented per-parameter here: ~60 of its ~70 constructor params (lines 155-260) are verbatim Flutter `CupertinoTextField` parameters (cursor*, selection*, smart*, scribble, restoration, autofill, spell-check, magnifier, etc.) and behave identically. Nomo-specific additions:

| Param | Meaning |
|---|---|
| `decorationTween` | `ValueNotifier<BoxDecorationTweenInfo?>` from `NomoInput`; consumed via `ValueListenableBuilder` + `TweenAnimationBuilder` + `DecoratedBox` + `ClipRRect` (lines 1314-1339). |
| `placeholderStyle` / `titleStyle` / `usePlaceholderAsTitle` / `duration` / `curve` / `textSpacing` | Floating-label configuration (all required). |
| `top` / `bottom` | Widgets stacked inside the decorated padding above/below the editable (lines 1346, 1367). |
| `hitTestBehavior`, `centerPlaceholder` | Pass-through to gesture detector / render box. |

### Behavior worth documenting

- **Selection/gestures:** `_CupertinoTextFieldSelectionGestureDetectorBuilder` (lines 35-68) — standard Flutter fork; single tap up requests keyboard + fires `widget.onTap`; handle visibility logic `_shouldShowSelectionHandles` (1052-1077) is stock iOS behavior (no handles for collapsed selection/keyboard cause).
- **Focus:** `_handleFocusChanged` just `setState`s (1045-1050); selection highlight color only applied while focused (line 1251). `enabled=false` → `readOnly` + `IgnorePointer` + `canRequestFocus=false` (1225, 1312, 977/999).
- **Keep-alive:** `wantKeepAlive` when non-empty text (line 1117); restoration supported via `RestorableTextEditingController`.
- **Formatters:** widget formatters + `LengthLimitingTextInputFormatter` when `maxLength` set (1176-1183). (So NomoInput's paragraph limiter runs *before* the length limiter.)
- **Floating label** (`_TextInputDependetAttachment` [sic], lines 1378-1535): an `AnimationController` whose value is 0 when the field is empty+unfocused and 1 otherwise (`focusChanged`, 1473-1488, listening to both focus node and controller). In `usePlaceholderAsTitle` mode the placeholder's `TextStyle` is tweened `placeholderStyle → titleStyle` (`TextStyleTween`, 1433-1440) and the render box shifts the editable down by the measured title height; otherwise the placeholder just fades out (`Opacity(1 - value)`, 1513-1520). Title height measured with `calculateTextSize(text: '')` (1450-1452) — measuring an **empty string**, so the height is the style's line height; fine, but subtle.

### Dead / vestigial fork code

- `clearButtonMode` param + `_clearGlobalKey` hit-test guard (lines 50-57, 173, 347, 936): **no clear button is ever built** — the entire Cupertino decoration/clear-button build path was deleted, but its supporting machinery remains.
- `prefixMode` / `suffixMode` (`OverlayVisibilityMode`) accepted (170-172) but never consulted — prefix/suffix are always visible (NomoInput passes them via `ifElseNull`).
- `textAlignVertical` accepted (180) never used.
- Commented-out `resolvedStyle` block (1186-1192).
- Being a fork, it silently drifts from upstream Flutter fixes (it has already been hand-migrated at least once: `stylusHandwritingEnabled`, `withValues(alpha:)`).

---

## 11. `TextInputLayoutDelegate` / `TextInputLayoutRenderbox`

**File:** `/Users/thomas/src/legend-ui/lib/components/input/textInput/text_layout.dart`
**Purpose:** custom `SlottedMultiChildRenderObjectWidget` laying out four slots — `text`, `leading`, `trailling` [sic], `placeHolder` (enum lines 6-11) — so the placeholder can overlay the editable text and the title inset can be animated.

### Layout algorithm (`performLayout`, lines 104-210)

1. Measure leading/trailing/placeholder at full `maxWidth`; measure text at `maxWidth - trailing - leading` ("intrinsic" sizes via real `layout()` calls, lines 89-93 — children are laid out **twice**: once for measurement, once final).
2. `maxHeight` = tallest child if unconstrained, else `constraints.maxHeight`; in floating-title mode, add the measured title height to the box height (lines 125-133).
3. Leading pinned left / trailing pinned right, both vertically centered (138-155).
4. Text laid out with `maxWidth - leading - trailing - 2*textSpacing`, offset by `textSpacing + leadingWidth` horizontally and `titleInset + centered` vertically (160-176).
5. Placeholder x depends on `textAlign` (start/end/center switch, 190-199); y is `animation * centeredOffset` when floating-title, but **only applied when `centerPlaceholder` is true** — otherwise `dy = 0` (lines 185-204, `dy = centerPlaceholder ? topInset : 0.0`). So the `animation` parameter (the title float progress) only affects placeholder y in `centerPlaceholder` mode; in the default mode the "float" is achieved purely by the style tween + the text inset. Confusing interplay; recent commit trail suggests this was patched around.
6. `size = Size(maxWidth, maxHeight)` — always takes **full available width**.

### Problems (rewrite-relevant)

- **Fields are effectively immutable:** `updateRenderObject` (54-59) only casts and updates nothing. Instead the *widget* is recreated with `key: ValueKey(children.hashCode)` (line 22) to force a fresh render object per frame of the animation — defeating the render-object update model and re-laying-out from scratch every animation tick.
- **Intrinsics are wrong:** `computeMinIntrinsicHeight`/`MaxIntrinsicHeight` **sum** all children's heights (290-305) though children overlap horizontally; `computeDryLayout` sums both width and height of all children (308-316). Anything relying on intrinsics (e.g. `IntrinsicHeight`, baseline rows) gets garbage.
- `paint` draws a fully transparent rect first (218-221) — pointless; also paints children in slot-map order with debug overflow indicator (234-242).
- Hit testing is straightforward child loop (249-265).

---

## 12. `NomoForm` / `NomoFormValues` / `NomoFormValidator`

**File:** `/Users/thomas/src/legend-ui/lib/components/input/form/nomo_form.dart`
**Purpose:** minimal form scope. `NomoForm` is a plain `InheritedWidget` (lines 4-23, `updateShouldNotify` always false) exposing:

- **`NomoFormValues extends ChangeNotifier`** (27-58): a `Map<String, dynamic> value`; `updateField` writes + fires `onChanged` + notifies (37-41); fields register their `ValueNotifier` via `setValueNotifierForField` (43-48) so `setValueForField` can push values *into* inputs programmatically (50-57, with a `hasListeners == false` guard against disposed notifiers — fragile, and `hasListeners` is `@protected`).
- **`NomoFormValidator extends ChangeNotifier`** (60-82): `Map<String, bool> values`; `addField` seeds `false` (69-74); `validate()` merely `notifyListeners()` (65-67) — every registered `NomoInput` hears it and runs its own `validator` (`formValidate`, nomo_input.dart:402-405) writing results back via `validateField` (76-78, silent, no notify). `isValid` = all true and non-empty (80-81).

### Flow

Registration: `NomoInput.didChangeDependencies` → `NomoForm.of(context)` → `validator.addField(formKey)` + `values.setValueNotifierForField(formKey, valueNotifier)` (nomo_input.dart:325-329).
Change: input edits → `values.updateField` → `NomoFormValues.onChanged(json)`.
Submit: **there is no submit flow.** Caller must hold the `NomoFormValidator`, call `validate()`, then (synchronously!) read `isValid` — which only works because each field validates synchronously inside the same notification dispatch.

### Mismatch with documented API

`CLAUDE.md` documents `NomoForm(formKey:, submitButtonBuilder:, onSubmitted:, children:)` and combinators like `NomoFormValidator.required`, `NomoFormValidator.minLength(8)`, `NomoFormValidator.compose([...])`, `NomoFormValidator.email`. **None of that exists in the code.** `NomoFormValidator` is a ChangeNotifier, not a validator library; there is no submit button builder, no `onSubmitted`, no built-in validators. The docs describe an aspirational or ancient API.

Other gaps: no unregistration on dispose (`values`/`validator` maps keep entries for removed fields → `isValid` can be pinned false by a dead field); duplicate-listener risk (§9); validator-less fields pin the form invalid (§9).

### Usage (as it actually works)

```dart
final values = NomoFormValues(onChanged: print);
final validator = NomoFormValidator();

NomoForm(
  values: values,
  validator: validator,
  child: Column(children: [
    NomoInput(formKey: 'user', validator: (v) => v.isEmpty ? 'Required' : null),
    PrimaryNomoButton(
      text: 'Submit',
      onPressed: () {
        validator.validate();               // triggers every field
        if (validator.isValid) submit(values.value);
      },
    ),
  ]),
)
```

---

## 13. Quirks, dead code, duplication — consolidated list

**Dead code / dead parameters**
1. `NomoButton.enableInkwellFeedback` — never read (nomo_button.dart:31).
2. `NomoText`: `fit`, `fitHeight`, `fontSizes`, `decreaseBy`, `minFontSize`, `textShortener` all dead since `30aba3e`; stale asserts remain; `findStyleForFitHeight` orphaned; leftover `// if (!widget.fit) {` comment.
3. `NomoLinkButton`: `enabled`, `width`, `height`, `margin`, `focusNode`, `onSecondaryPressed` accepted and ignored.
4. `CupertinoInput`: `clearButtonMode` + clear-button hit-test machinery, `prefixMode`/`suffixMode`, `textAlignVertical` — vestigial fork remains; commented-out style block.
5. `NomoInput.errorColor` theme field appears unused in build.

**Bugs / behavioral traps**
6. `ActionType.disabled` does **not** disable `onPressed` (primary:303-306, secondary:194-197); only `nonInteractive` does. Two competing disable mechanisms (`enabled` vs `type`).
7. Secondary & text buttons pass raw `padding` instead of `theme.padding` (secondary:187, text_button:109) → themed default padding silently ignored (primary does it correctly).
8. Base button hover animation runs while disabled; `onSecondaryTap` not gated by `enabled`.
9. `NomoLinkButton` missing `onTapCancel` → sticky pressed color.
10. Secondary vertical layout: `Expanded` inside `mainAxisSize.min` Column (secondary:147-162) → layout exception risk; also silently ignores `ActionType.loading` (no spinner).
11. `NomoInput` dispose order: internal `FocusNode.dispose()` before `removeListener` (nomo_input.dart:333-337); `didChangeDependencies` re-adds form listeners without dedup (302-330).
12. Form: field with `formKey` but no `validator` pins `isValid` false forever; no field unregistration on dispose; no submit flow; CLAUDE.md documents a `NomoFormValidator` API that does not exist.
13. `TextInputLayoutRenderbox`: no-op `updateRenderObject` + `ValueKey(children.hashCode)` recreation hack; incorrect intrinsic sizes / dry layout; children laid out twice per pass.
14. `NomoTextTranslator.updateShouldNotify == false` → locale/translator swaps don't rebuild texts.
15. `ParagraphLimitingTextInputFormatter` truncates at the last `\n`, potentially deleting user text beyond the offending newline.
16. `NomoInput.initialText` re-applied via `Future.microtask` in `didUpdateWidget` — hybrid controlled/uncontrolled semantics.

**Duplication / complexity hotspots**
17. `PrimaryNomoButton.effectiveChild`: 4 near-identical ~25-line switch arms (direction × textFirst), loading-spinner block copy-pasted 4×.
18. Hover color animation implemented 3 times (base border path, base content path, link button); tween-recreation duplicated in `didChangeDependencies` + `didUpdateWidget` in both stateful buttons.
19. `cupertino_text_input.dart`: 1535-line diverging fork of Flutter's CupertinoTextField — highest-risk maintenance surface in the whole kit.
20. Annotation taxonomy is inconsistent (`elevation`/`borderRadius` under `@NomoColorField`, a `Color` under `@NomoSizingField` in link button) — theme buckets are not trustworthy for a generator rewrite.
21. Pervasive typos baked into public API: `trailling`, `errorNotifer`, `_TextInputDependetAttachment`; assert message "ask Thomas to implement".
