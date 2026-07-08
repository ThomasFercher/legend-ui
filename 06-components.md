# 06 — Display, Overlay, Layout & Misc Components

Scope: all nomo_ui_kit components **except** buttons, text, input/form and the app shell (documented elsewhere). All paths relative to `/Users/thomas/src/legend-ui`.

## Theming mechanism (applies to every `@NomoComponentThemeData` widget below)

Each annotated widget gets a generated `*.theme_data.g.dart` part file containing `<Name>ColorData`, `<Name>SizingData`, `<Name>Constants` (+ `Nullable` variants), a merged `<Name>ThemeData`, an `InheritedWidget` `<Name>ThemeOverride`, and a file-local `getFromContext(context, widget)` function. Resolution order (see `lib/components/card/nomo_card.theme_data.g.dart:232-257`):

1. Global `NomoTheme` component colors/sizings (fallback: annotation defaults)
2. `<Name>ThemeOverride` inherited widget (nullable, partial)
3. Widget constructor parameters (non-null wins)

**Systemic quirk:** because widget params always win, any constructor parameter with a **non-null default** (e.g. `NomoCard.elevation = 1`, `NomoDialog.elevation = 2`) makes the corresponding theme value unreachable — you can never theme it globally. Also, the annotation categories are frequently wrong: `double`/`EdgeInsets`/`BorderRadius` fields annotated `@NomoColorField` (e.g. snackbar `elevation` at `lib/components/snackbar/nomo_snackbar.dart:31`, `Expandable.titlePadding` at `lib/components/expandable/expandable.dart:40-47`, `Loading.strokeWidth` at `lib/components/loading/loading.dart:12`, `NomoDropDownMenu.dropdownElevation` at `lib/components/dropdownmenu/dropdownmenu.dart:55`). These land in the wrong theme bucket (`componentColors` vs `componentSizes`) and get color-lerped incorrectly across theme transitions.

In the tables below, **Themed** = property participates in the generated theme (annotation shown).

---

# 1. Surfaces

## 1.1 NomoCard — `lib/components/card/nomo_card.dart`

**Purpose:** basic elevated surface. `Padding(margin) > ElevatedBox(shadow + BoxDecoration) > Padding(padding) > child` (`nomo_card.dart:50-69`). Shadow comes from `ElevatedBox`, *not* Material elevation.

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `child` | `Widget` | required | – | content |
| `elevation` | `double?` | `1` | `@NomoSizingField(1.0)` | shadow strength (spread `0.25*e`, blur `0.5*e`) |
| `offset` | `Offset?` | null | `@NomoSizingField(Offset.zero)` | shadow offset |
| `shadowColor` | `Color?` | null | `@NomoColorField(0x33000000)` | shadow color |
| `border` | `BoxBorder?` | null | `@NomoColorField(null)` | border |
| `borderRadius` | `BorderRadiusGeometry?` | null | `@NomoSizingField(BorderRadius.zero)` | corner radius |
| `backgroundColor` | `Color?` | null | `@NomoColorField(Colors.white)` | fill |
| `padding` | `EdgeInsetsGeometry?` | null | `@NomoSizingField(EdgeInsets.zero)` | inner padding |
| `margin` | `EdgeInsetsGeometry?` | null | `@NomoSizingField(EdgeInsets.zero)` | outer margin |

Quirks:
- `elevation = 1` constructor default ⇒ theme elevation dead (see systemic quirk above).
- **`lib/components/card/card_const.dart` is dead code** — `CardConst` is referenced nowhere; defaults live in the annotations instead, and they disagree (`CardConst.borderRadius` = 8, actual default = `BorderRadius.zero`; `CardConst.padding` = 8, actual = zero).

```dart
NomoCard(
  backgroundColor: context.colors.surface,
  borderRadius: BorderRadius.circular(12),
  elevation: 2,
  padding: const EdgeInsets.all(16),
  child: content,
)
```

## 1.2 NomoOutlineContainer — `lib/components/outline_container/nomo_outline_container.dart`

**Purpose:** plain `Container` with border + background (`:52-66`). No shadow.

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `child` | `Widget` | required | – | content |
| `foreground` | `Color?` | null | `@NomoColorField(Colors.black)` | **unused in build — dead theme property** |
| `background` | `Color?` | null | `@NomoColorField(Colors.white)` | fill |
| `shape` | `BoxShape?` | null | `@NomoColorField(BoxShape.rectangle)` | box shape (a `BoxShape` as a *color* field) |
| `padding` | `EdgeInsets?` | null | `@NomoSizingField(EdgeInsets.all(16))` | inner padding |
| `spacing` | `double?` | null | `@NomoSizingField(16.0)` | **unused in build — dead theme property** |
| `border` | `BoxBorder?` | null | `@NomoColorField(BorderSide.none border)` | border |
| `radius` | `double?` | null (→ 8) | no | corner radius, not themeable, `?? 8` fallback at `:59` |
| `width` / `height` | `double?` | null | no | fixed size |

Quirks: `foreground` and `spacing` are themed but never read in `build`; `radius` is a raw double instead of `BorderRadius` (inconsistent with every other component). Setting `shape: BoxShape.circle` with a non-null borderRadius would assert-crash in `BoxDecoration`.

```dart
NomoOutlineContainer(
  border: Border.all(color: context.colors.primary),
  radius: 12,
  child: Text('outlined'),
)
```

## 1.3 ElevatedBox — `lib/components/elevatedBox/elevated_box.dart` (not themeable, no annotation)

**Purpose:** `DecoratedBox` that injects a computed `BoxShadow` list into a given decoration (`:22-36`). Used internally by `NomoCard` and `NomoDialog`.

| Param | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | content |
| `elevation` | `double` | `1` | shadow strength |
| `offset` | `Offset?` | `Offset.zero` | shadow offset |
| `shadowColor` | `Color?` | `0x33000000` | shadow color |
| `border` | `BoxBorder?` | null | merged into decoration |
| `decoration` | `BoxDecoration` | `BoxDecoration()` | base decoration (color, radius) |

Helper `getElevationShadow({elevation, shadowColor, offset})` (`:39-53`): single `BoxShadow`, `spreadRadius: 0.25 * elevation`, `blurRadius: 0.5 * elevation`, empty when `elevation <= 0`.

## 1.4 NomoElevation — `lib/components/nomo_elevation/nomo_elevation.dart`

**Purpose:** *animated* elevation via Flutter's `AnimatedPhysicalModel` (`:43-58`) — Material-style shadow, animates elevation changes.

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `child` | `Widget` | required | – | content |
| `shape` | `BoxShape` | `rectangle` | no | physical model shape |
| `clipBehavior` | `Clip` | `Clip.none` | no | clipping |
| `borderRadius` | `BorderRadiusGeometry?` | `BorderRadius.zero` | no | corners |
| `backgroundColor` | `Color?` | null | `@NomoColorField(Colors.white)` | surface color |
| `shadowColor` | `Color?` | null | `@NomoColorField(Colors.black26)` | shadow color |
| `elevation` | `double?` | null | `@NomoSizingField(1.0)` | Material elevation |
| `animationDuration` | `Duration?` | null | `@NomoConstant(200ms)` | anim duration |
| `animationCurve` | `Curve?` | null | `@NomoConstant(fastOutSlowIn)` | anim curve |

**Duplication:** `ElevatedBox` and `NomoElevation` solve the same problem with two different shadow models (hand-rolled BoxShadow vs Material `PhysicalModel`), producing visually different shadows for the same "elevation" number. Cards/dialogs use `ElevatedBox`; `NomoElevation` is the odd one out. Rewrite: pick one elevation system.

---

# 2. Overlays

## 2.1 NomoDialog — `lib/components/dialog/nomo_dialog.dart`

**Purpose:** dialog *content* widget (title row + content + action row) meant to be passed to Flutter's plain `showDialog` (see `example/lib/sections/dialog_section.dart:29-31`). The kit provides **no** `showNomoDialog` wrapper — show/dismiss/barrier/animation are entirely Flutter's route machinery; the close button just calls `Navigator.of(context).pop()` (`nomo_dialog.dart:115`).

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `content` | `Widget` | required | – | body |
| `title` | `String?` | null | no | title text (mutually exclusive with `titleWidget`, assert `:33-36`) |
| `titleWidget` | `Widget?` | null | no | custom title |
| `titleStyle` | `TextStyle?` | null | no | title text style |
| `leading` | `Widget?` | null | no | leading widget in title row |
| `showCloseButton` | `bool?` | `true` | no | show default circular close `PrimaryNomoButton` |
| `closeButton` | `Widget?` | null | no | custom close button |
| `actions` | `List<Widget>?` | null | no | bottom-right action row |
| `scrollabe` *(sic)* | `bool` | `false` | no | wraps content in `Expanded > SingleChildScrollView` (`:153-160`) |
| `centerTitle` | `bool` | `true` | no | title layout via `AppBarLayoutDelegate` vs plain `Row` (`:101-151`) |
| `maxWidth` | `double?` | null | `@NomoSizingField(null)` | max width cap |
| `elevation` | `double?` | `2` | `@NomoSizingField(1.0)` | ElevatedBox shadow — theme value unreachable (non-null ctor default) |
| `contentSpacing` | `Widget?` | null | `@NomoSizingField(SizedBox(height:12))` | spacing widget (a *Widget* as theme field!) |
| `backgroundColor` | `Color?` | null | `@NomoColorField(Colors.white)` | surface |
| `widthRatio` | `double?` | null | `@NomoSizingField(0.75)` | width = screen width × ratio (`:78`) |
| `margin` | `EdgeInsetsGeometry?` | null | `@NomoSizingField(EdgeInsets.zero)` | outer margin |
| `padding` | `EdgeInsetsGeometry?` | null | `@NomoSizingField(EdgeInsets.all(12))` | inner padding |
| `borderRadius` | `BorderRadiusGeometry?` | null | `@NomoSizingField(circular(12))` | corners |

Behavior: `Center > ConstrainedBox(maxWidth: theme.maxWidth ?? screenW*ratio, maxHeight: screenH*0.9) > Container(width) > ElevatedBox > Column` (`:81-174`). Reuses the app bar's `AppBarLayoutDelegate` for centered titles — a surprising coupling of dialog to app-shell layout code.

Quirks: public API typo `scrollabe`; `showCloseButton!` null-asserted (`:112`) though typed `bool?`; if content is tall and `scrollabe: false` the Column overflows; the two title layouts duplicate the close-button construction (`:113-124` vs `:140-149`, subtly different — the second omits `elevation: 0` and `foregroundColor`).

```dart
showDialog(
  context: context,
  builder: (context) => NomoDialog(
    title: 'Confirm',
    content: Text('Are you sure?'),
    actions: [PrimaryNomoButton(text: 'OK', onPressed: () => Navigator.pop(context))],
  ),
);
```

## 2.2 NomoModalSheet — `lib/components/modal_sheet/modal_sheet.dart`

**Dead code / never implemented.** The whole file is 10 lines; `build` returns `const Placeholder()` (`:8`). No theme file, no usages. Rewrite: either implement a real sheet or drop the file.

## 2.3 NomoSnackBar — `lib/components/snackbar/nomo_snackbar.dart`

**Purpose:** styled content + factory for a Material `SnackBar`. It is a `StatelessWidget` whose `build` renders the row (leading icon + text, fixed height container, `:82-108`) and a separate `buildSnackBar(context)` method (`:57-80`) that wraps it in a Material `SnackBar` — the caller must show it via `ScaffoldMessenger.of(context).showSnackBar(...)`. Dismissal/animation are Material's.

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `leading` | `Widget` | required | – | leading icon (IconTheme size 28, foreground color) |
| `content` | `Widget` | required | – | text content (b3 typography, foreground color) |
| `behavior` | `SnackBarBehavior` | `floating` | no | Material behavior |
| `width` | `double?` | null | no | fixed width (when set, margin is dropped, `:60-68`) |
| `indentBySider` | `bool` | `false` | no | adds sider width to left margin (couples snackbar to app-shell `siderSizing`, `:62-66`) |
| `height` | `double?` | null | `@NomoSizingField(64.0)` | fixed content height |
| `margin` | `EdgeInsets?` | null | `@NomoSizingField(EdgeInsets.all(16))` | floating margin |
| `spacing` | `double?` | null | `@NomoSizingField(12.0)` | leading↔content gap |
| `backgroundColor` | `Color?` | null | `@NomoColorField(Colors.white)` | surface |
| `foregroundColor` | `Color?` | null | `@NomoColorField(Colors.black)` | icon/text color |
| `elevation` | `double?` | null | `@NomoColorField(0.0)` ← wrong bucket | Material elevation |
| `borderRadius` | `BorderRadius?` | null | `@NomoConstant(circular(8))` | shape |
| `border` | `BorderSide?` | null | `@NomoColorField(BorderSide.none)` | shape side |

Quirk: no `show` helper in the kit; nothing in the example app actually shows one. Fixed 64px height clips multi-line content.

```dart
ScaffoldMessenger.of(context).showSnackBar(
  NomoSnackBar(
    leading: const Icon(Icons.check),
    content: const Text('Saved'),
  ).buildSnackBar(context),
);
```

## 2.4 NomoNotification + InAppNotification — `lib/components/notification/nomo_notification.dart`, `lib/app/notifications/app_notification.dart`

**NomoNotification** is only the visual card (title/subtitle/leading/close inside a `NomoCard`, `nomo_notification.dart:57-115`).

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `title` | `String` | required | no (style via `titleStyle`) | title, maxLines 1, default `b3` |
| `subtitle` | `String` | required | no | subtitle, maxLines 1, `fit: true`, default `b1` |
| `leading` | `Widget` | required | – | icon/avatar |
| `expand` | `bool` | `false` | no | wrap text column in `Expanded` |
| `titleStyle`/`subtitleStyle` | `TextStyle?` | null | no | text styles |
| `showCloseButton` | `bool` | `true` | no | close button → `InAppNotification.dismiss(context)` (`:107`) |
| `backgroundColor` | `Color?` | null | `@NomoColorField(null)` | card fill |
| `foregroundColor` | `Color?` | null | `@NomoColorField(null)` | wraps texts in `NomoTextTheme` when non-null (`:90-94`) |
| `padding` | `EdgeInsetsGeometry?` | null | `@NomoSizingField(EdgeInsets.all(16))` | card padding |
| `borderRadius` | `BorderRadius?` | null | `@NomoSizingField(circular(16))` | card corners |
| `spacing` | `double?` | null | `@NomoSizingField(16.0)` | leading↔text gap |
| `maxWidth` | `double?` | null | `@NomoSizingField(double.infinity)` | width cap |

Quirk: `4.hSpacing` between title and subtitle inside a **Column** (`:81`) — should be `vSpacing`; the gap is horizontal, i.e. no vertical spacing at all.

**InAppNotification** (`lib/app/notifications/app_notification.dart`) is a vendored copy of the `in_app_notification` pub package (~550 lines). Mechanics:
- App must be wrapped: `InAppNotification(child: MaterialApp(...))`; internal `_VsyncProvider` owns three `AnimationController`s (`:418-455`).
- `InAppNotification.show(child:, context:, top:, left:, right:, duration: 10s, curve:, center:, useRootNavigator:)` (`:55-93`): gets `_NotificationController` InheritedWidget, inserts an `OverlayEntry` on the **navigator overlay** (`:197`), measures the child with a custom `SizeListenableRenderObject` (`:376-401`), then slides it in from the top over 350 ms; a `Timer` auto-dismisses after `duration` (`:228`).
- Gestures: tap fires `onTap` + dismiss; vertical drag up dismisses (velocity/percentage thresholds, `:260-280`); horizontal swipe dismisses past 20% width or high velocity (`:288-300`).
- `InAppNotification.dismiss(context:)` reverses and removes the entry (`:100-106`).

Complexity hotspot: three coordinated animation controllers, manual position math in the overlay builder (`:149-193`), completer-based size measurement. In a rewrite, prefer a maintained package or a simpler overlay abstraction shared with the context menu / dropdown (currently three separate hand-rolled overlay systems).

```dart
InAppNotification.show(
  context: context,
  child: NomoNotification(title: 'Hi', subtitle: 'Something happened', leading: Icon(Icons.info)),
  duration: const Duration(seconds: 4),
);
```

## 2.5 NomoContextMenu + createContextMenuOverlay — `lib/components/context_menu/context_menu.dart`

**Purpose:** popover with an arrow pointing at the anchor widget.

`createContextMenuOverlay({context, child (PreferredSizeWidget), backgroundColor, opaque=false, spacing=16, arrowSize=12, duration=200ms, onOutsideTap})` (`:6-91`):
- Reads the anchor's `RenderBox` global offset (`:16-24`), flips above/below on top overflow (`:28-32`), pins 20 px from the right edge on right overflow (`:34-38`).
- Returns an `OverlayEntry` (caller must `Overlay.of(context).insert(entry)` and later `entry.remove()` — typically inside `onOutsideTap: (entry) => entry.remove()`); a full-screen `GestureDetector` catches outside taps (`:51-56`).
- Menu and a `TrianglePainter` arrow (`:196-235`) fade in via `FadeIn`. **No dismiss animation** — removal is instant.

`NomoContextMenu` (not theme-generated; all styling by constructor):

| Param | Type | Default | Meaning |
|---|---|---|---|
| `actions` | `List<Widget>` | required | top row of square action buttons |
| `backgroundColor` | `Color` | required | card fill (must match the arrow color passed to the overlay fn) |
| `children` | `List<Widget>` | `[]` | list rows under a divider |
| `itemHeight` | `double` | `48` | action row height |
| `childHeight` | `double` | `48` | each child row height |
| `actionWidth` | `double` | `48` | per-action width (only used for width math) |
| `actionSpacing` / `childrenSpacing` | `double` | `8` | gaps |
| `width` | `double` | `200` | min width |
| `padding` | `EdgeInsets` | `all(12)` | inner padding |
| `borderRadius` | `BorderRadiusGeometry` | `circular(12)` | corners |

Quirks: `preferredSize` height includes a magic `+ 33` fudge constant (`:191`) for the divider; sizing relies on the caller-supplied heights being accurate (no intrinsic measurement). Positioning uses raw `Positioned` from a one-shot `localToGlobal` — does not track the anchor if it scrolls/moves (unlike the dropdown, which uses `CompositedTransformFollower`).

```dart
final entry = createContextMenuOverlay(
  context: anchorContext,
  backgroundColor: context.colors.surface,
  onOutsideTap: (e) => e.remove(),
  child: NomoContextMenu(
    backgroundColor: context.colors.surface,
    actions: [IconButton(icon: Icon(Icons.copy), onPressed: () {})],
    children: [Text('Rename'), Text('Delete')],
  ),
);
Overlay.of(anchorContext).insert(entry);
```

---

# 3. Menus & Selection

## 3.1 NomoDropDownMenu<T> — `lib/components/dropdownmenu/dropdownmenu.dart` (+ `drop_down_item.dart`)

**Purpose:** fully custom dropdown (field + overlay list). Items are a sealed hierarchy in `drop_down_item.dart`: `NomoDropDownItemString<T>(value, title)` and `NomoDropdownItemWidget<T>(value, widget)` (note inconsistent casing `DropDown` vs `Dropdown` between the two subclasses).

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `items` | `List<NomoDropdownItem<T>>` | required | – | options |
| `onChanged` | `void Function(T?)?` | null | no | selection callback |
| `initialValue` | `T?` | null | no | initial selection (fallback: `items.first.value`, `:102`) |
| `valueNotifer` *(sic)* | `ValueNotifier<T?>?` | null | no | external state |
| `focusNode` | `FocusNode?` | null | no | external focus; **focus == open** |
| `icon` | `IconData` | `keyboard_arrow_down` | no | trailing icon |
| `disableRotation` | `bool` | `false` | no | disable 180° icon spin |
| `overflow` | `TextOverflow?` | `ellipsis` | no | field text overflow |
| `width` / `height` | `double?` | null | no | field size; width also used for overlay |
| `textStyle` | `TextStyle?` | null | no | item/field text style |
| `offset` | `Offset?` | null | no | follower offset (default `(0, h+5)`, `:255`) |
| `itemHeight` | `double` | `48` | no | overlay row height |
| `iconColor` | `Color?` | null | `@NomoColorField(0xFF272626)` | icon color |
| `dropdownElevation` | `double?` | null | `@NomoColorField(1.0)` ← wrong bucket | overlay Material elevation |
| `dropdownColor` | `Color?` | null | `@NomoColorField(Colors.white)` | overlay fill |
| `minFontSize` | `double?` | null | `@NomoSizingField(10.0)` | field text auto-fit floor |
| `itemPadding` | `EdgeInsetsGeometry?` | null | `@NomoSizingField(EdgeInsets.zero)` | overlay row padding |
| `padding` | `EdgeInsetsGeometry?` | null | `@NomoSizingField(h12,v8)` | field padding |
| `dropdownBorder` | `ShapeBorder?` | null | `@NomoColorField(null)` | overlay shape |
| `backgroundColor` | `Color?` | null | `@NomoColorField(Colors.white)` | field fill |
| `borderRadius` | `BorderRadius?` | null | `@NomoSizingField(null)` | field corners |
| `border` | `BorderSide?` | null | `@NomoColorField(BorderSide.none)` | field border; expanded ⇒ recolored primary/2px (`:172-178`) |

Overlay mechanics (`:233-326`): opening = `FocusNode.requestFocus()`; the focus listener (`:125-140`) inserts a manually-built `OverlayEntry` and toggles icon rotation; unfocus removes it. The entry is a full-screen translucent `GestureDetector` (outside tap ⇒ unfocus ⇒ remove) with the list positioned **both** by a `Positioned(left/top from localToGlobal)` *and* a `CompositedTransformFollower(offset: size.height+5)` (`:250-256`) — belt-and-braces double positioning; the follower offset is applied on top of an already below-the-field `Positioned`, only working out because `Stack` + follower override each other. Max height = space to screen bottom − 15, or hard 100 if negative (`:266-275`). No open/close animation except the icon rotation.

Quirks/bugs: dispose order bug — `_valueNotifier.dispose()` is called *before* `removeListener` (`:108-112`); `selectedItem` uses `firstWhere` and **throws** if the current value isn't in `items` (`:153-156`); public API typo `valueNotifer`; `setState` during `onFocusChanged` plus manual entry management is fragile (no `mounted` checks).

```dart
NomoDropDownMenu<int>(
  items: const [
    NomoDropDownItemString(value: 1, title: 'One'),
    NomoDropDownItemString(value: 2, title: 'Two'),
  ],
  initialValue: 1,
  onChanged: (v) => print(v),
)
```

## 3.2 NomoDropDownButton<T> — `lib/components/dropdown_button/nomo_dropdown_button.dart`

**Purpose:** thin wrapper around **Material's** `DropdownButton` (`:70-101`), with its own item class `DropDownItem<T>(value, displayName)` (`:8-17`).

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `options` | `List<DropDownItem<T>>` | required (non-empty assert) | – | options |
| `onChanged` | `void Function(T?)` | required | no | callback |
| `inital` *(sic)* | `T?` | null | no | initial value |
| `isExpanded` | `bool` | `false` | no | **declared but never passed to `DropdownButton` — dead param** |
| `fitText` | `bool` | `false` | no | **dead param — never read** |
| `width` | `double?` | null | no | per-item SizedBox width |
| `icon` | `IconData` | `arrow_drop_down` | no | trailing icon (overridden by `child` if set) |
| `child` | `Widget?` | null | no | custom icon widget |
| `valueNotifier` | `ValueNotifier<T?>?` | null | no | external state |
| `padding` | `EdgeInsetsGeometry?` | null | no | button padding |
| `dropdownColor` | `Color?` | null | `@NomoColorField(Colors.white)` | menu fill (only themed prop) |

**Duplication:** this overlaps almost entirely with `NomoDropDownMenu` (3.1) — two dropdowns, two incompatible item models (`NomoDropdownItem` sealed hierarchy vs plain `DropDownItem`), one custom overlay vs one Material-based, different naming for the same concepts (`initialValue`/`inital`, `valueNotifer`/`valueNotifier`). Prime consolidation target for the rewrite.

## 3.3 NomoVerticalMenu<T> — `lib/components/vertical_menu/nomo_vertical_menu.dart`

**Purpose:** sidebar navigation list over the shared `NomoMenuItem<T>` model (`lib/entities/menu_item.dart`: sealed — `NomoMenuTextItem`, `NomoMenuIconItem`, `NomoMenuImageItem` (png/svg via `flutter_svg` — the kit's only runtime dep usage), `NomoMenuWidgetItem`; items can carry `children` for one level of nesting).

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `items` | `List<NomoMenuItem<T>>` | required | – | entries |
| `selected` | `T?` | required | no | selected key |
| `onTap` | `void Function(NomoMenuItem<T>)?` | null | no | tap callback (leaf items and sub-items; **not** fired for parent items with children — they toggle instead, `:230`) |
| `style` | `TextStyle?` | null | no | title style |
| `title` | `Widget?` | null | no | **dead param — never used in build** |
| `itemDecorator` | `Widget Function(item, child)?` | null | no | wrap each row |
| `seperatorBulder` *(sic)* | `Widget Function(int)?` | null | no | custom separator (fallback: `itemSpacing` gap, `:152-155`) |
| `collapsed` | `bool?` | null | no | icon-only mode |
| `border` / `selectedBorder` | `BorderSide?` | null | `@NomoColorField(BorderSide.none)` | tile borders (animated between) |
| `foreground` / `iconForeground` | `Color?` | null | `@NomoColorField(Colors.black)` | text / icon colors |
| `background` | `Color?` | null | `@NomoColorField(Colors.white)` | tile fill |
| `selectedBackground` / `selectedForeground` | `Color?` | null | `@NomoColorField(Colors.red)` | selected colors (red defaults!) |
| `borderRadius` | `BorderRadius?` | null | `@NomoColorField(circular(16))` | tile corners |
| `padding` | `EdgeInsetsGeometry?` | null | `@NomoSizingField(h8)` | tile padding |
| `itemSpacing` | `double?` | null | `@NomoSizingField(8.0)` | gap between tiles |
| `spacing` | `double?` | null | `@NomoSizingField(8.0)` | icon↔text gap |
| `height` | `double?` | null | `@NomoSizingField(56.0)` | tile height |
| `iconSize` | `double?` | null | `@NomoSizingField(28.0)` | icon size |
| `splashColor`/`hoverColor`/`highlightColor`/`focusColor` | `Color?` | null | `@NomoColorField(null)` | ink effects (default transparent in the tile) |
| `subMenuIconSpacing` | `double?` | null | `@NomoSizingField(8)` | sub-item gap (misleading name) |
| `expandIcon` | `IconData?` | null | `@NomoColorField(null)` | parent chevron (fallback `Icons.arrow_downward`, `:237`) |

Behavior: `ListView.separated(shrinkWrap, NeverScrollable)` (`:115`); items with children render through private `ItemWrapper` (`:161-320`) which owns a 140 ms height-factor animation, an `AnimatedRotation` chevron, a hardcoded vertical `NomoDivider` (color `0xFFE5E5EA` hardcoded, `:269`) and a nested inner `ListView.separated`. Submenu height is computed *manually* from `children.length * theme.height + ...` (`:256-259`) — breaks if a sub-tile ever differs in height.

## 3.4 NomoVerticalListTile<T> — `lib/components/vertical_menu/nomo_vertical_tile.dart`

**Purpose:** single menu row; also used by the app-shell sider. Takes the parent menu's theme object (`menuTheme`) *plus* has its own generated theme (`verticalListTile`) just for three `TextStyle` constants (`:15-22`) — a two-theme hybrid.

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `item` | `NomoMenuItem<T>` | required | – | data |
| `menuTheme` | `NomoVerticalMenuThemeData` | required | – | all colors/sizes come from here |
| `collapsed` | `bool` | `false` | no | icon-only |
| `onTap` | `VoidCallback?` | null | no | tap |
| `selected` | `bool` | `false` | no | selection state |
| `titleStyle`/`subtitleStyle`/`traillingStyle` *(sic)* | `TextStyle?` | null | `@NomoConstant(TextStyle())` | text styles |
| `splashColor`/`hoverColor`/`highlightColor`/`focusColor` | `Color?` | null | no | ink overrides (default `Colors.transparent`, `:230-233`) |
| `iconForeground` | `Color?` | null | no | **accepted but never read — dead param** (icon color comes from an animation, `:199`) |
| `trailling` *(sic)* | `Widget?` | null | no | trailing override |

Behavior/quirks: two `AnimationController`s tween fg/bg/border between normal and selected (`:68-106`); **controllers are driven inside `build`** (`forward()/reverse()` at `:166-172`) and again from `MouseRegion` hover (`:177-184`), so hover and selection fight over the same foreground controller; `Scrollable.ensureVisible` fires in `didChangeDependencies` for the selected tile (`:109-123`); tween re-created in `didUpdateWidget` without re-checking hover state. Leading widget is wrapped in `NomoDefaultTextStyle(style: theme.traillingStyle)` (`:247` — trailing style applied to *leading*, copy-paste bug). Complexity hotspot with subtle animation state bugs; a rewrite should make this a simple `ImplicitlyAnimated` tile.

## 3.5 NomoSwitch — `lib/components/switch/nomo_switch.dart` (+ `cupertino_switch.dart`)

**Purpose:** iOS-style toggle. Thin themed wrapper (`nomo_switch.dart:36-50`) around a **forked copy of Flutter's `CupertinoSwitch`** (`cupertino_switch.dart`, ~1,400 lines) that adds `width`, `height`, `thumbSize` params.

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `value` | `bool` | required | – | state |
| `onValueChanged` | `void Function(bool)?` | required (nullable) | – | callback; null = disabled |
| `activeForeground` | `Color?` | null | `@NomoColorField(Colors.white)` | thumb (on) |
| `foreground` | `Color?` | null | `@NomoColorField(Colors.black54)` | thumb (off) |
| `activeBackground` | `Color?` | null | `@NomoColorField(primaryColor)` | track (on) |
| `background` | `Color?` | null | `@NomoColorField(Colors.black12)` | track (off) |

Geometry hardcoded: `width: 48, height: 24, thumbSize: 18` (`:42-44`) — not themeable.

Fork quirks (vs upstream Flutter):
- **Bug:** disabled rendering uses `Opacity(opacity: onChanged == null ? 42 : 1)` (`cupertino_switch.dart:719`) — upstream uses `0.5`; `42` violates `Opacity`'s 0..1 assert ⇒ **debug-mode crash when the switch is disabled**.
- Track outline rect hardcoded `96×96` (`:1248-1253`), ignoring actual size.
- Drag delta divisor hardcoded `/ 42` (`:569`).
- Carries the entire upstream painter (thumb icons, on/off accessibility labels, thumb images) — huge maintenance burden for one sizing tweak. Rewrite: use stock `CupertinoSwitch` (which now supports sizing via themes) or a ~100-line custom toggle.

---

# 4. Feedback / Loading

## 4.1 Loading — `lib/components/loading/loading.dart`

**Purpose:** circular spinner; optional color-pulsing variant.

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `color` | `Color?` | null | `@NomoColorField(primaryColor)` | spinner color |
| `strokeWidth` | `double?` | null | `@NomoColorField(4.0)` ← wrong bucket | stroke |
| `size` | `double?` | null | no | width/height of wrapper + progress constraints |
| `padding` | `EdgeInsetsGeometry?` | null | no | wrapper padding |
| `endColor` | `Color?` | null | no | if set, uses `LoadingColorAnimation` (color ping-pong tween, `:39-45`, `:79-112`) |
| `period` | `Duration?` | null (→1 s) | no | pulse period |

Quirk: with `padding` + `size` set, the padding eats into the fixed-size box; the plain branch uses `CircularProgressIndicator(constraints:)` while the animated branch duplicates the same widget with a `valueColor` animation — small duplicated pair.

## 4.2 FadeIn — `lib/components/loading/fade_in.dart`

**Purpose:** opacity entrance animation; vendored from `animate_do` (header comment `:3`). Not themeable.

| Param | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | content |
| `duration` | `Duration` | 400 ms | fade time |
| `delay` | `Duration` | zero | start delay |
| `controller` | `void Function(AnimationController)?` | null | exposes internal controller |
| `manualTrigger` | `bool` | `false` | require manual start (throws in *constructor* if no controller, `:30-34`) |
| `animate` | `bool` | `true` | toggling false animates back |

Quirks: non-const constructor with validation throw; **side effects in `build`** (`controller?.forward()` at `:84`, `animateBack` at `:89`); `Offstage` when value == 0. Used internally by context menu and vertical tile.

## 4.3 Shimmer / ShimmerLoading / LoadingContainer — `lib/components/loading/shimmer/`

Three-layer skeleton system (the classic Flutter-docs shimmer recipe):

- **`Shimmer`** (`shimmer.dart`) — themed (`@NomoColorField<LinearGradient>` default gray gradient, `:13-21`). Ancestor that owns an unbounded repeating controller (−0.5→1.5, default period 1 s, `:46-47`) and exposes `Shimmer.of(context)` (via `findAncestorStateOfType`, `:23-25`), `gradient` (with `SlidingGradientTransform`), `isSized`, `size`, `getDescendantOffset`. Params: `child`, `gradient`, `duration`.
- **`ShimmerLoading`** (`loading_shimmer.dart`) — per-widget mask. Params: `isLoading` (required), `child`. Listens to the ancestor's ticker and repaints a `ShaderMask(BlendMode.srcATop)` positioned via descendant offset (`:74-87`); silently passes through if no ancestor; try/catch around offset computation (`:66-72`).
- **`LoadingContainer`** (`loading_container.dart`) — convenience gray box: params `isLoading=true`, `child`, `padding`, `height`, `width`, `background=Colors.white`, `borderRadius=circular(8)`. Not themeable (hardcoded white default).

Quirk: `ShimmerState.didChangeDependencies` caches the themed gradient once (`shimmer.dart:57-60`) — theme changes after first build won't fully re-resolve until dependencies change. Every `ShimmerLoading` calls `setState` on every animation tick — O(n) rebuilds per frame for n skeletons.

```dart
Shimmer(
  child: Column(children: [
    LoadingContainer(height: 24, width: 200),
    LoadingContainer(height: 100, isLoading: stillLoading, child: content),
  ]),
)
```

---

# 5. Layout

## 5.1 DynamicRow — `lib/components/layout/dynamic_row/dynamic_row.dart`

**Purpose:** wrapping row (a hand-rolled `Wrap`) implemented as a `MultiChildRenderObjectWidget` + custom `RenderBox` (`CustomRenderBox`, `:55-217`). Not themeable.

| Param | Type | Default | Meaning |
|---|---|---|---|
| `children` | `List<Widget>` | – | items |
| `vSpacing` | `double` | `8` | gap between rows |
| `hSpacing` | `double` | `8` | gap within a row |
| `mainAxisSize` | `MainAxisSize` | `max` | max ⇒ take full width |
| `mainAxisAlignment` | `MainAxisAlignment` | `start` | **only `start` and `center` implemented** (`:158-170`); end/spaceBetween etc. silently behave as start |

Layout algorithm (`performLayout`, `:95-205`): (1) layout all children with `minWidth: 0`; (2) greedy row packing on `maxWidth` overflow; (3) center rows if requested; (4) cross-axis-center each child within its row — using `rowBoxes.entries.singleWhere(...contains(child))` per child, i.e. **O(n²)** (`:178-183`); `crossAxisAlignment` is a hardcoded mutable field, never exposed (`:69`).

Quirks: `didUnmountRenderObject` calls `markNeedsLayout()` on the dead render object (`:40-42`, pointless); no baseline/intrinsic overrides; note the CLAUDE.md example advertises a `breakWidth`/`wrapAlignment` API that **does not exist** — docs drift. Rewrite candidate: replace with `Wrap(spacing:, runSpacing:)` unless the full-width + centered-rows semantics are truly needed.

```dart
DynamicRow(
  hSpacing: 12,
  vSpacing: 12,
  mainAxisAlignment: MainAxisAlignment.center,
  children: chips,
)
```

## 5.2 NomoDivider — `lib/components/divider/nomo_divider.dart`

**Purpose:** horizontal or vertical rule, optional centered `middle` widget.

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `axis` | `Axis` | `horizontal` | no | direction |
| `color` | `Color?` | null | `@NomoColorField(Colors.black38)` | line color |
| `crossAxisSize` | `double?` | null | `@NomoSizingField(1.0)` | thickness |
| `crossAxisSpacing` | `double?` | null | `@NomoSizingField(8.0)` | margin along cross axis |
| `middle` | `Widget?` | null | no | widget between two expanded line halves (4 px gaps, `:47-55`) |
| `borderRadius` | `BorderRadius?` | null | no | **vertical axis only** — horizontal branch ignores it (`:40-44` vs `:61-68`) |

Quirk: `middle` on horizontal requires a bounded-width parent (uses `Expanded` in a `Row`); vertical `middle` likewise requires bounded height.

---

# 6. Misc

## 6.1 NomoInfoItem — `lib/components/info_item/nomo_info_item.dart`

**Purpose:** key–value row (`title` left, `value` right, `spaceBetween`, `:34-49`).

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `title` | `String` | required | – | label |
| `value` | `String` | required | – | value |
| `titleStyle` | `TextStyle?` | null | `@NomoConstant(TextStyle())` | label style |
| `valueStyle` | `TextStyle?` | null | `@NomoConstant(TextStyle())` | value style |
| `padding` | `EdgeInsets?` | null | `@NomoSizingField(EdgeInsets.zero)` | row padding |

No overflow handling — long title+value overflow the row. Value cannot be a widget (String only).

## 6.2 Expandable — `lib/components/expandable/expandable.dart`

**Purpose:** expansion tile (title row + animated children), custom replacement for `ExpansionTile`.

| Param | Type | Default | Themed | Meaning |
|---|---|---|---|---|
| `title` | `Widget` | required | – | header (Expanded) |
| `children` | `List<Widget>` | required | – | body |
| `expandIcon` | `IconData` | `arrow_forward_ios_rounded` | no | chevron |
| `duration` / `curve` | `Duration`/`Curve` | 300 ms / easeInOut | no | animation |
| `margin`/`padding`/`decoration` | – | null | no | outer container |
| `splashRadius` | `double?` | null | no | **dead param — never read** |
| `onTap` | `VoidCallback?` | null | no | extra tap handler |
| `expandOnTap` | `bool` | `true` | no | header tap toggles |
| `showExpandButton` | `bool` | `true` | no | show chevron button |
| `expansionNotifier` | `ValueNotifier<bool>?` | null | no | external state (overrides `initiallyExpanded`) |
| `onLongPress` | `VoidCallback?` | null | no | long-press |
| `onExpansionChanged` | `void Function(bool)?` | null | no | change callback |
| `initiallyExpanded` | `bool` | `false` | no | initial state |
| `iconSize` | `double?` | null | `@NomoSizingField(28.0)` | chevron size |
| `titlePadding` | `EdgeInsetsGeometry?` | null | `@NomoColorField(h8,v4)` ← wrong bucket | header padding |
| `childrenPadding` | `EdgeInsetsGeometry?` | null | `@NomoColorField(v4)` ← wrong bucket | body padding |
| `borderRadius` | `BorderRadius?` | null | `@NomoColorField(circular(12))` ← wrong bucket | ink radius |
| `highlightColor`/`focusColor`/`splashColor`/`hoverColor`/`iconColor` | `Color?` | null | `@NomoColorField(null)` | ink/icon colors |

Behavior: one `AnimationController`; chevron rotates π/2 → 1.5π (`:111-116`), body revealed via `ClipRect > Align(heightFactor)` (`:222-237`). Chevron is a full `PrimaryNomoButton` (`:200-216`) — a *button component* inside a disclosure tile.

Quirks: theme resolved in both `didUpdateWidget` **and** `didChangeDependencies` (`:127-137`) into a mutable `theme` field; `hideChildren = value && controller.isDismissed` (`:173`) — an odd condition (expanded but dismissed) that mostly never triggers, meaning collapsed children stay in the tree (only clipped, not offstage); duplicated toggle paths (header InkWell vs chevron button write the notifier separately, `:160-163` vs `:201-203`).

## 6.3 NoData — `lib/components/data/nodata/no_data.dart`

**Purpose:** empty-state placeholder (icon + text). Not themeable, no generated theme.

| Param | Type | Default | Meaning |
|---|---|---|---|
| `text` | `String` | `'no_data'` | message — untranslated raw key as default |
| `icon` | `IconData` | `sentiment_very_dissatisfied` | icon (colored `context.colors.primary`) |
| `iconSize` | `double` | `42` | icon size |
| `height` | `double` | `100` | fixed container height |

Not referenced by the example app; borderline dead code.

---

# Rewrite notes — duplication, dead code, hotspots

**Duplicated logic**
1. **ElevatedBox vs NomoElevation** — two elevation/shadow systems (custom BoxShadow math vs `AnimatedPhysicalModel`); same concept, different visuals.
2. **NomoDropDownMenu vs NomoDropDownButton** — two dropdowns with incompatible item models and naming; one custom overlay, one Material wrapper.
3. **Three hand-rolled overlay systems** (dropdown menu `:233`, context menu `:6`, InAppNotification `:129`) each with their own positioning, outside-tap and lifecycle handling; none share code, none use a common anchored-popover abstraction.
4. **NomoDialog** builds its close button twice with diverging styles (`nomo_dialog.dart:113-124` vs `:140-149`).
5. **Vendored third-party code**: `FadeIn` (animate_do), `InAppNotification` (in_app_notification), `CupertinoSwitch` (Flutter SDK fork) — ~2,000 lines of copied upstream code to maintain.

**Dead code / dead params**
- `NomoModalSheet` = `Placeholder()`; `CardConst` unused; `NoData` unused.
- Dead params: `NomoOutlineContainer.foreground/spacing`, `NomoDropDownButton.isExpanded/fitText`, `NomoVerticalMenu.title`, `NomoVerticalListTile.iconForeground`, `Expandable.splashRadius`.

**Bugs found while documenting**
- `CupertinoSwitch` fork: `Opacity(opacity: 42)` for disabled state (`cupertino_switch.dart:719`) — asserts in debug; hardcoded 96×96 outline rect (`:1248`).
- `NomoNotification`: `4.hSpacing` inside a Column (`nomo_notification.dart:81`) — missing vertical gap.
- `NomoVerticalListTile`: trailing text style applied to the *leading* widget (`nomo_vertical_tile.dart:247`); animations driven from `build` + hover/selection controller conflict.
- `NomoDropDownMenu`: notifier disposed before `removeListener` (`dropdownmenu.dart:108-112`); `firstWhere` throws on unknown value (`:153-156`).
- `NomoDivider.borderRadius` silently ignored for horizontal axis.

**API hygiene** — public typos to fix in rewrite: `scrollabe`, `valueNotifer`, `inital`, `trailling`, `traillingStyle`, `seperatorBulder`. Wrong-bucket theme annotations (sizes as `@NomoColorField`) throughout. Constructor defaults that shadow theme values (card/dialog `elevation`).

**Complexity hotspots** — `NomoVerticalListTile` (4 tweens, 2 controllers, build-time side effects), `InAppNotification` (3 controllers + gesture math), `DynamicRow` (custom RenderBox, O(n²) pass, partial API), `CupertinoSwitch` fork (1,400 lines), `NomoDropDownMenu` overlay (double positioning).

**Docs drift** — CLAUDE.md advertises `DynamicRow(breakWidth:, wrapAlignment:)`, `NomoInput(formKey:)`-style APIs and a `Shimmer(child: Container(...))` usage that don't match the actual signatures here.
