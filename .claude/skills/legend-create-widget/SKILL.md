---
name: legend-create-widget
description: Create a custom themed Legend UI widget end-to-end — legend_gen create scaffold, @Style annotation forms, custom style value classes, the four wiring forms, registry entry, playground rung. Invoke when adding, porting, or making a widget themeable.
---

# Creating a themed Legend UI widget

Reference widget: `packages/legend_ui/lib/src/components/divider/legend_divider.dart`. Tested consumer proofs: `packages/legend_ui/test/consumer/wiring_forms.dart` and `balance_card.dart` (they use only the public barrel — if your widget needs kit-internal imports, the design is wrong).

## 1. Scaffold

```bash
cd packages/legend_ui        # or any package that dev-depends on legend_gen
dart run legend_gen create LegendBadge                 # → lib/src/components/badge/legend_badge.dart
dart run legend_gen create LegendBadge --dir lib/widgets
```

Emits an annotated `StatelessWidget` stub with example `@Style` fields and the `part` directive, then immediately generates its `.theme.g.dart` and `.docs.g.dart`. Refuses to overwrite (exit 73).

## 2. The decorator contract

- `@LegendThemeable()` on the class; the file carries `part '<file>.theme.g.dart';`.
- Every `@Style` field is **nullable** and its constructor param **defaults to null** (generator-enforced; a non-null default was the legacy bug that made theme values unreachable).
- The generic argument is required and must match the field's declared (non-null) type.
- Every `@Style` field gets a one-line `///` intent comment — it is the docs-CMS content (`legend_gen docs`).

The default forms:

```dart
/// Fill behind the label.
@Style<Color>(Color(0xFF2563EB))                 // const value: used when no theme level provides anything
@Style<Color>.value(Color(0xFF2563EB), lerp: true)  // same, when you need flags (Dart forbids named params beside an optional positional)
@Style<Color>.resolve(ColorRef.background3)      // one-hop token default: a Ref catalog member
@Style<EdgeInsetsGeometry>.resolve(_padding)     // composite default: a private top-level tear-off in the widget's file
@Style<Color>(null)                              // genuinely optional: the resolved theme field stays nullable
```

```dart
// Composite tear-offs are private top-level functions (the generated part
// is `part of` the library, so private symbols resolve):
EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.all(t.sizes.md);
```

- **Ref catalogs** (generated from the token classes): `ColorRef` (`.primary`, `.surface`, `.background3`, `.foreground1`, …), `SizeRef` (`.xs`–`.xxl`, `.radiusSm/Md/Lg`, `.borderWidth`, `.iconSm/Md/Lg`), `TextRef` (`.h1`–`.h3`, `.b1`–`.b3`), `ShadowRef` (`.none/.low/.medium/.high`), `StateRef` (`.hoverAmount/.pressAmount/.disabledOpacity`), `TokenRef` (`.colors/.sizes/.typography/.shadows/.states`).
- `lerp: true` — `XTheme.lerp` interpolates the field (opt-in; most fields step, because theme switches lerp tokens once instead).
- `listen: false` — the field resolves fresh every build but never *causes* a rebuild by itself (for painters/controllers; RFC-002 R12.2).

## 3. Custom `@Style()` value classes

Define one when a themed property is a **bundle of members that must each be individually overridable at every resolution level** (per-state colors, multi-part accents). Kit's predefined case: `InteractiveColors`. Consumer proof: `BalanceAccent` in `test/consumer/balance_card.dart`:

```dart
part 'balance_card.style.g.dart';

@Style()                       // class form: bare, no default, no flags
class BalanceAccent with _$BalanceAccent {
  const BalanceAccent({this.amount, this.caption});

  /// Color of the amount text.
  final Color? amount;

  /// Color of the caption line under the amount.
  final Color? caption;

  /// Member-wise lerp (generated).
  static BalanceAccent? lerp(BalanceAccent? a, BalanceAccent? b, double t) =>
      _$BalanceAccentLerp(a, b, t);
}
```

Generator-enforced contract: every instance field `final`, explicitly typed, **nullable**; const unnamed constructor takes every field named; the class applies `with _$ClassName` and redirects the one-line `static lerp`; the file carries `part '<file>.style.g.dart';`. Generated: member-wise sparse `merge` + value `==`/`hashCode` (mixin) and member-wise `_$ClassNameLerp`.

A widget field typed with a style class gets **member-wise** theme treatment: the docs manifest lists dot-paths (`accent.amount`) and every member is overridable at every level. Behavior (selection, derivation — see `InteractiveColorsPick.pick` / `InteractiveColorsResolve.resolve`) is hand-written beside the class; the generator owns only the mechanical members.

## 4. Generate

```bash
cd packages/legend_ui
dart run legend_gen themes lib test/consumer   # *.style.g.dart + *.theme.g.dart
dart run legend_gen docs lib test/consumer     # *.docs.g.dart manifests
```

Generated files are committed; CI verifies freshness with `--check` (exit 65 when stale). Leave `--watch` running while iterating.

## 5. Pick a wiring form (RFC-002 R13)

1. **Hook — the stateless default.** Plain `StatelessWidget`:

   ```dart
   Widget build(BuildContext context) {
     final theme = _theme(context);   // all four levels + R12 per-field aspects
     ...
   }
   ```

2. **Auto State getter — the stateful default.** A `State<X>` declared in the same file gets a generated extension; its build just reads `theme` (zero visible wiring):

   ```dart
   class _BadgeState extends State<LegendBadge> {
     @override
     Widget build(BuildContext context) => ColoredBox(color: theme.fill);
   }
   ```

3. **Explicit mixin (stateful).** `with _$LegendBadgeThemeState` makes `theme` a real, overridable inherited member; the mixin wins over the auto-extension. Use when the State lives in another file or you want to override `theme`.

4. **Opt-in base (stateless only).** `class LegendBadge extends _$LegendBadgeBase` swaps to the two-argument `build(BuildContext context, LegendBadgeTheme theme)`; themed fields carry `@override` (they implement the base's abstract getters). Living example: `LegendDivider`. There is no stateful two-argument variant.

Also generated: per-field accessors `_<field>(context)` — the full four-level chain registering **only that field's** rebuild aspect, for widgets consuming a single property. When a top-level tear-off shares the name, call receiver-qualified: `this._color(context)`.

## 6. App-level registration (level 3)

```dart
LegendThemeData(
  tokens: LegendTokens.light,
  components: {
    // Key by the WIDGET type (RFC-002 R3). Sparse: unset members keep
    // resolving through the lower levels.
    LegendBadge: const LegendBadgeThemeNullable(background: Color(0xFF001F54)),
  },
)
```

Keying by the Nullable type (`LegendBadgeThemeNullable: …`) still works as the legacy fallback; the widget-type entry wins when both exist. Subtree override (level 2): `LegendBadgeThemeOverride(data: LegendBadgeThemeNullable(...), child: ...)`.

## 7. Ship checklist

- Doc comments in the standard order: one-sentence summary; which primitive(s) it composes; the legacy bug/fork it replaces (if any); one-line intent per `@Style` field.
- Export from `packages/legend_ui/lib/legend_ui.dart` (the only barrel).
- **Playground rung**: a live instance in `example/lib/docs/pages/playground_page.dart` AND at least one knob wired through `ThemeController` in `example/lib/theme/theme_panel.dart` (its most characteristic themed property). No rung = incomplete component.
- Widget tests with the feature; when closing a legacy bug (legacy-docs `01-overview.md` §4.2), add a regression test and name the bug in the commit message.
- Run the full quality gate (see the `legend-gate` skill).
