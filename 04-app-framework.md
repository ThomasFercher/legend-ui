# 04 — App Shell / Application Framework

Documentation of the app-shell layer of `nomo_ui_kit` (repo: `/Users/thomas/src/legend-ui`), covering the top-level application widget, metric/theme reactivity, the scaffold and its bars, the route body, and the in-app notification system. Written as input to a rewrite decision.

Source files covered:

| Area | File |
|---|---|
| App entry | `/Users/thomas/src/legend-ui/lib/app/nomo_app.dart` |
| Metric reactor | `/Users/thomas/src/legend-ui/lib/app/metric_reactor.dart` |
| Theme animator | `/Users/thomas/src/legend-ui/lib/app/animator.dart` |
| Notifications | `/Users/thomas/src/legend-ui/lib/app/notifications/app_notification.dart` |
| Barrel export | `/Users/thomas/src/legend-ui/lib/components/app/app.dart` |
| Scaffold | `/Users/thomas/src/legend-ui/lib/components/app/scaffold/nomo_scaffold.dart` (+ empty `nomo_scaffold_layout.dart`) |
| App bar | `/Users/thomas/src/legend-ui/lib/components/app/app_bar/nomo_app_bar.dart`, `layout/appbar_layout_delegate.dart`, `layout/appbar_layout_renderbox.dart` |
| Bottom bar | `/Users/thomas/src/legend-ui/lib/components/app/bottom_bar/nomo_bottom_bar.dart`, `nomo_horizontal_tile.dart` |
| Sider | `/Users/thomas/src/legend-ui/lib/components/app/sider/nomo_sider.dart` |
| Route body | `/Users/thomas/src/legend-ui/lib/components/app/routebody/nomo_route_body.dart` |
| Theme plumbing (referenced) | `/Users/thomas/src/legend-ui/lib/theme/theme_provider.dart`, `/Users/thomas/src/legend-ui/lib/theme/nomo_theme.dart` |

---

## 1. Big picture

The app shell is a thin custom framework layered on top of `WidgetsApp.router` (not `MaterialApp`), with its own theme system driven by code generation. The wiring order matters and is the core of the architecture:

```
NomoApp (StatefulWidget, owns ThemeNotifier)
└─ MultiWrapper (fold of wrapper lambdas, outermost first)
   ├─ ThemeProvider (InheritedWidget exposing ThemeNotifier)
   ├─ ScrollConfiguration (no scrollbars, all pointer devices drag)
   ├─ NomoTextTranslator (optional, if translator provided)
   ├─ ScaffoldMessenger (Material interop for snackbars)
   ├─ InAppNotification (overlay-based notification controller)
   └─ MetricReactor (window metrics → sizing theme; forces textScaler off)
      └─ ThemeAnimator (lerps NomoThemeData on theme change)
         └─ WidgetsApp.router (routerConfig, locales, optional appWrapper)
            └─ per-route: NomoScaffold(appBar / sider / bottomBar / child)
               └─ NomoRouteBody (scrolling content region per route)
```

Responsiveness is **not** done with `LayoutBuilder`s per component. Instead the window width is mapped to a *sizing theme* (an app-defined enum such as `SMALL/MEDIUM/LARGE`), and every component reads its sizes — including booleans like `showSider`/`showBottomBar` — from that theme. Switching a breakpoint therefore swaps the whole sizing theme atomically and animates it.

---

## 2. `NomoApp` — `lib/app/nomo_app.dart`

### Purpose
The application root widget. Replaces `MaterialApp`: owns the `ThemeNotifier`, sets up localization delegates, global scroll behavior, the notification system, metric reaction and theme animation, and hosts a `RouterConfig`-driven `WidgetsApp.router`.

### Constructor parameters

| Name | Type | Default | Meaning |
|---|---|---|---|
| `themeDelegate` | `NomoThemeDelegate<Object, Object>` | required | User-implemented delegate supplying color themes, sizing themes, typography, constants, and the `sizingThemeBuilder(width)` breakpoint function (`lib/theme/nomo_theme.dart:99-137`). |
| `routerConfig` | `RouterConfig<Object>` | required | Router (typically from the companion `nomo_router` package / route_gen). Passed straight to `WidgetsApp.router`. |
| `color` | `Color` | required | The `WidgetsApp.color` (OS task-switcher / primary color). |
| `supportedLocales` | `Iterable<Locale>` | required | Forwarded to `WidgetsApp`. |
| `localeResolutionCallback` | `Locale? Function(Locale?, Iterable<Locale>)?` | `null` | Forwarded to `WidgetsApp`. |
| `localizationDelegate` | `LocalizationsDelegate<dynamic>?` | `null` | Optional app-specific delegate, prepended to the Global Material/Cupertino/Widgets delegates (`nomo_app.dart:67-72`). |
| `currentLocale` | `Locale?` | `null` | Forwarded as `WidgetsApp.locale`. |
| `translator` | `String Function(String value)?` | `null` | If set, wraps the tree in `NomoTextTranslator`, so every `NomoText` is translated implicitly. |
| `appWrapper` | `Widget Function(BuildContext, Widget app)?` | `null` | Injected via `WidgetsApp.builder` (`nomo_app.dart:78-83`); runs *inside* the router so it can see `ThemeProvider` and the navigator. |

### Wiring details

- `_NomoAppState` creates the `ThemeNotifier(widget.themeDelegate)` once in `initState` (`nomo_app.dart:52-55`) and disposes it. **The delegate is captured at startup; replacing `themeDelegate` on a rebuilt `NomoApp` has no effect** — a quirk worth fixing in the rewrite.
- Module-level constants: `kThemeChangeDuration = 400ms`, `kThemeChangeCurve = Curves.easeInOut` (`nomo_app.dart:11-12`).
- Global `_scrollBehavior` (`nomo_app.dart:13-16`): scrollbars disabled everywhere, and `dragDevices: PointerDeviceKind.values` — i.e. mouse-drag scrolling is enabled globally (desktop/web affordance; scrollbars are opted back in per-widget, e.g. sider and route body).
- The `MultiWrapper` utility (`lib/utils/multi_wrapper.dart`) is a `fold` over `List<Widget Function(Widget)>`; note the fold order makes the *last* wrapper in the list the outermost widget. So the actual nesting is: `InAppNotification > ScaffoldMessenger > NomoTextTranslator > ScrollConfiguration > ThemeProvider > MetricReactor > ThemeAnimator > WidgetsApp.router`. The comment-free reliance on fold direction is subtle (see quirks §12).
- `ScaffoldMessenger` is included even though the kit claims Material independence — needed because `NomoScaffold` internally uses Material's `Scaffold` and the kit ships a snackbar helper.
- `debugShowCheckedModeBanner: false` hardcoded; no `title`/`onGenerateTitle` support — apps cannot set a window/tab title through `NomoApp`.

### Theme provider / notifier (context)

`ThemeNotifier` (`lib/theme/theme_provider.dart:6-65`) holds maps of color and sizing themes keyed by app-defined mode objects and rebuilds a `NomoThemeData` on `changeColorTheme` / `changeSizingTheme`. `changeSizingTheme` early-returns if the mode is unchanged (`:55`); `changeColorTheme` deliberately does not (commented out at `:43`). `ThemeProvider` is an `InheritedWidget` around the notifier; `updateShouldNotify` compares only the mode keys (`:109-112`).

Quirk: `sizingMode` is initialized to `_sizingThemes.keys.first` (`theme_provider.dart:27`) — i.e. map declaration order, not the actual window size; `MetricReactor` corrects it one frame later via `didChangeDependencies`.

---

## 3. `MetricReactor` — `lib/app/metric_reactor.dart`

### Purpose
Bridges window metrics to the sizing-theme system and provides the app-level `MediaQuery`. Sits *above* `WidgetsApp` so the sizing theme is correct before routes build.

### Parameters

| Name | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Subtree (ThemeAnimator + WidgetsApp). |
| `sizingThemeBuilder` | `Object Function(double)` | required | Maps window logical width → sizing mode key. Taken from the theme delegate. |

### Behavior

- Implements `WidgetsBindingObserver.didChangeMetrics` (`metric_reactor.dart:47-56`): on any window metric change it re-reads `MediaQueryData.fromView(view)`, calls `setState`, and pushes `sizingThemeBuilder(width)` into `ThemeProvider.changeSizingTheme`. Because `changeSizingTheme` no-ops when the mode is unchanged, resizes only rebuild the theme when a breakpoint is crossed.
- `didChangeDependencies` (`:33-38`) does the initial sizing-theme sync at first build.
- **Metrics propagated:** the *entire* `MediaQueryData` derived from the first `FlutterView`, with one deliberate override — `textScaler: TextScaler.noScaling` (`:60-62`). The kit globally disables OS font scaling (accessibility trade-off; see recent commit "Adjust Text to non resizable").
- Quirks:
  - Uses `platformDispatcher.views.first` — single-window assumption; also ignores `View.of(context)`, so multi-view/embedded scenarios break.
  - It builds its own `MediaQuery` rather than relying on `WidgetsApp`'s; but since it sits above `WidgetsApp`, `WidgetsApp` will still install its own `MediaQuery` below from the same view data — the outer one exists mainly so the sizing callback runs and text scaling is stripped.
  - `changeSizingTheme` is called during `didChangeMetrics` outside a frame guarantee and triggers `notifyListeners` → theme rebuild while also calling `setState`; two rebuild paths per resize.
  - Only *width* is fed to the builder; height-based or orientation-based sizing is impossible.

### Responsive breakpoints (example app)

The delegate in `example/lib/theme.dart:36-42` shows the canonical breakpoints:

```dart
SizingMode sizingThemeBuilder(double width) => switch (width) {
  < 600  => SizingMode.SMALL,
  < 1080 => SizingMode.MEDIUM,
  _      => SizingMode.LARGE,
};
```

Each `SizingMode`'s `NomoSizingThemeData` carries per-component sizing data, including `NomoScaffoldSizingData(showBottomBar, showSider)`. Typical configuration: SMALL → `showBottomBar: true, showSider: false`; LARGE → inverse. **This is the entire responsive mechanism for the shell**: nav chrome switching is data-driven through the sizing theme, not coded in the scaffold.

---

## 4. `ThemeAnimator` + `NomoThemeDataTween` — `lib/app/animator.dart`

### Purpose
Animates *every* theme change (color or sizing) by lerping whole `NomoThemeData` objects, and installs the resulting `NomoTheme` inherited widget plus the default text style.

### Parameters

| Name | Type | Default | Meaning |
|---|---|---|---|
| `notifier` | `ThemeNotifier` | required | Source of truth for the current theme. |
| `child` | `Widget` | required | The `WidgetsApp`. |

### Mechanics

- `NomoThemeDataTween extends Tween<NomoThemeData>` delegating to `NomoThemeData.lerp` (`animator.dart:7-17`) — the generated theme-data classes all implement `lerp`, so *all* themeable properties (colors, paddings, heights, and even booleans via `t < 0.5` step-lerp) interpolate.
- `ListenableBuilder` on the notifier wraps a `TweenAnimationBuilder` with `begin: lastTheme, end: notifier.theme`, `duration: kThemeChangeDuration (400ms)`, `curve: easeInOut` (`animator.dart:43-63`). Inside, it emits `NomoTheme(value: theme, colorMode, sizingMode)` and `NomoDefaultTextStyle(style: theme.typography.b1)`.
- `lastTheme` is only updated in `onEnd` (`:60`). **Quirk:** if a second theme change lands mid-animation, the new tween starts from the *stale* `lastTheme`, not from the currently displayed interpolated value — causing a visible jump. Rapid window resizing across a breakpoint plus a dark-mode toggle can look glitchy.
- Because the whole `NomoThemeData` is rebuilt 60×/s for 400ms and `NomoTheme` is an InheritedWidget the entire app depends on, every theme change re-builds effectively the whole tree per animation frame. This is a complexity/perf hotspot; a rewrite could animate at the paint layer or restrict animation to colors.
- Booleans such as `showSider` flip at `t = 0.5` mid-animation (see generated `lerp` in `nomo_scaffold.theme_data.g.dart:66-67`), so sider/bottom-bar switching happens abruptly halfway through the 400ms tween, while paddings/sizes glide.

---

## 5. `InAppNotification` system — `lib/app/notifications/app_notification.dart`

A vendored/adapted copy of the `in_app_notification` pub package (docs still reference `MaterialApp`). Provides overlay-based, swipe-dismissable foreground notifications.

### Public API

- `InAppNotification({required Widget child})` — mounted once by `NomoApp` above the router. Its `build` just installs `_VsyncProvider` (`:108-112`), which owns three `AnimationController`s (show, vertical-drag, horizontal-drag) and exposes them through the `_NotificationController` InheritedWidget.
- `static FutureOr<void> show({...})` (`app_notification.dart:55-93`):

| Param | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Notification body widget. |
| `context` | `BuildContext` | required | Used to find `_NotificationController` (via `getElementForInheritedWidgetOfExactType`, no dependency). |
| `top` | `double?` | `0.0` | Extra offset from the top of the screen. |
| `left` / `right` | `double?` | `null` | Horizontal anchoring. If `right` is set it wins; `left` offsets from the left edge. |
| `onTap` | `VoidCallback?` | `null` | Tap handler; tapping dismisses then invokes it. |
| `duration` | `Duration` | 10 s | Auto-dismiss timer; `Duration.zero` means sticky (`:227`). |
| `curve` / `dismissCurve` | `Curve` | `easeOutCubic` | Show/reverse curves. |
| `useRootNavigator` | `bool` | `false` | Which navigator's `Overlay` receives the entry. |
| `center` | `bool` | `false` | Horizontally center the notification (overrides left/right). |
| `notificationCreatedCallback` | `FutureOr Function()?` | `null` | Debug-mode test hook. |

- `static FutureOr<void> dismiss({required BuildContext context})` — animated programmatic dismissal (`:100-106`).

### Display pipeline

1. `create` (`:129-198`): first `await dismiss(...)` any currently-showing notification — **there is no queue; a new notification replaces the current one** (last-write-wins). It then resets drag distances and inserts an `OverlayEntry` into the chosen navigator's overlay. The entry builds a `Positioned` whose `bottom` is computed as `screenHeight − currentVerticalPosition − top`, i.e. the widget slides *down from above the top edge* as `showAnimation.value` grows from 0 → notification height.
2. Size discovery: the child is wrapped in `SizeListenableContainer` (`:361-401`), a `RenderProxyBox` that reports its laid-out size via a post-frame callback into a `Completer<Size>` (adding the top view padding). `show` awaits this completer (`:206`) before it knows the slide distance, then (re)creates `showAnimation` as a `Tween(0 → height)` and runs `showController.forward()`.
3. Auto-dismiss: a `Timer(duration, dismiss)` is armed after the show animation (`:228`); `onTapDown` cancels it (`:249-251`) so a press keeps the notification alive.
4. Gestures: vertical drags clamp between `−(height+top)` and `0` (`:253-258`); on release, fling up (velocity ≤ −1.0 scaled) or having dragged past 50% keeps/dismisses via `VerticalInteractAnimationController.stay()/dismiss()` (`:260-280`). Horizontal drags dismiss when |velocity| ≥ 1 screen/s or displacement ≥ 20% of screen width, animating off-screen in the drag direction (`:282-300`). The two `InteractAnimationController` subclasses (`:474-554`) are `AnimationController`s that carry a `dragDistance` and build one-shot tweens for stay/dismiss.
5. `dismiss` reverses the show controller, removes the overlay entry, and resets the size completer (`:231-240`).

### Quirks / issues

- Positioning math is inverted (uses `bottom:` with screen-height arithmetic) — hard to read; the whole file is ~550 lines for a single toast.
- Only **one** notification at a time; no queueing, no stacking, no priorities.
- `_NotificationController.of` uses `getElementForInheritedWidgetOfExactType(...)!` then `assert(controller != null)` — the `!` makes the assert unreachable; missing ancestor throws a null-check error instead of the friendly message (`:122-124`, `:72`).
- `state.screenSize` is set inside the overlay builder (side effect during build).
- `_ambiguate<T>` shim (`:357`) is dead legacy from pre-Flutter-3 nullability of `SchedulerBinding.instance`.
- Test-only hook `notificationCreatedCallback` gated on `kDebugMode` leaks into the public API.
- The kit's actual `NomoNotification` widget (styling) lives elsewhere; this file is pure mechanics.

---

## 6. `NomoScaffold` — `lib/components/app/scaffold/nomo_scaffold.dart`

### Purpose
Per-route shell: composes app bar, sider (left rail), bottom bar, drawers, FAB and body. Internally **wraps Material's `Scaffold`** (`nomo_scaffold.dart:208-229`) rather than doing custom layout. The sibling file `nomo_scaffold_layout.dart` is **empty — dead file** (presumably a removed custom layout; the name suggests there was once a render-object-based scaffold).

### Constructor parameters

| Name | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Route body content. |
| `appBar` | `NomoAppBar?` | `null` | Converted via `appBar.asPreferedSizeWidget(context)` and passed to Material `Scaffold.appBar` (`:223`). |
| `nestedAppBar` | `Widget?` | `null` | A second bar rendered *inside* the body column, to the right of the sider (`:184`) — for bars that should not span above the sider. |
| `bottomBar` | `Widget?` | `null` | Passed to `Scaffold.bottomNavigationBar`, but only when `theme.showBottomBar` is true (`:206`). |
| `sider` | `Widget?` | `null` | Left rail; rendered in the body `Row` when `theme.showSider` (`:180`). |
| `bottomSheet` | `Widget?` | `null` | Forwarded to `Scaffold.bottomSheet`. |
| `drawer` / `endDrawer` | `Widget?` | `null` | Forwarded to Material `Scaffold`. |
| `drawerVisibleNotifier` / `endDrawerVisibleNotifier` | `ValueNotifier<bool>?` | `null` | Programmatic drawer control: listener opens via `scaffoldState.openDrawer()` and closes via `Navigator.pop` (`:145-171`). |
| `floatingActionButton` | `Widget?` | `null` | Forwarded. |
| `floatingActionButtonLocation` | `FloatingActionButtonLocation?` | `null` | Forwarded. |
| `backgroundImage` | `DecorationImage?` | `null` | Painted behind the body inside the SafeArea container (`:214-218`). |
| `borderRadius` | `BorderRadiusGeometry?` | `null` | If set, the whole Scaffold is wrapped in `ClipRRect` (`:230-238`) — used for modal-style embedded scaffolds. |
| `padding` | `EdgeInsetsGeometry?` (themeable) | theme (`EdgeInsets.zero`) | Padding around the body child. |
| `backgroundColor` | `Color?` (themeable) | theme (`Colors.white`) | Body/scaffold background. |
| `showBottomBar` | `bool?` (themeable, **sizing** field) | theme (`false`) | Whether the bottom bar renders. |
| `showSider` | `bool?` (themeable, **sizing** field) | theme (`true`) | Whether the sider renders. |

### Themeable properties (from `nomo_scaffold.theme_data.g.dart`)
Colors: `backgroundColor`. Sizing: `padding`, `showBottomBar`, `showSider`. Resolution order (generated `getFromContext`, `nomo_scaffold.theme_data.g.dart:174-195`): global `NomoTheme` component data → `NomoScaffoldThemeOverride` inherited override → widget-level constructor value. This 3-layer pattern is identical for every component below.

### Layout algorithm (`build`, `nomo_scaffold.dart:174-239`)

1. Body = `Row(crossAxisAlignment: stretch)`: `[sider?, Expanded(Column([nestedAppBar?, Expanded(padded child)]))]`.
2. The body child is wrapped in a `LayoutBuilder` that overrides `MediaQuery.size` with `constraints.biggest` (`:188-196`). This makes `context.width`/`context.height` extensions inside a route report the *content-area* size (excluding sider/app bar), which the rest of the kit relies on for responsive checks. **Quirk:** it replaces only `size`, leaving paddings/insets from the window — a semantically odd hybrid MediaQuery.
3. The body sits in `ColoredBox(context.colors.surface) > SafeArea > Container(backgroundImage/backgroundColor)` (`:211-222`), so the safe-area reveal color is the surface color while the content background is themeable.
4. Everything else (app bar height handling, drawers, FAB, bottom bar placement, insets) is delegated to Material `Scaffold`.

### Responsive behavior
`showSider` and `showBottomBar` are *sizing-theme* fields: apps set them per `SizingMode`, so crossing a width breakpoint (via `MetricReactor`) flips which nav chrome exists. No animation between the two states other than the theme tween (booleans flip at t=0.5).

### Static access
`NomoScaffold.of(context)` / `maybeOf` return the **Material** `ScaffoldState` via a `GlobalKey` (`:93-109`) — used to open drawers etc. Leaks the Material dependency into user code.

### Other notes
- `copyWith` (`:68-91`) only supports overriding `appBar` and `borderRadius`; it silently drops `child`? No — it passes `child: child`; but it also drops `drawerVisibleNotifier`/`endDrawerVisibleNotifier` (not copied) — a real bug if `copyWith` is used on a scaffold with notifiers (it is used by the router/modal machinery).
- `didUpdateWidget` handles notifier swaps correctly; closing uses `Navigator.pop(context)` which assumes the drawer route is topmost — fragile if a dialog opened above the drawer.

---

## 7. `NomoAppBar` — `lib/components/app/app_bar/nomo_app_bar.dart`

### Purpose
Custom app bar with a slot-based (leading / title / trailing) custom-render-object layout, elevation, optional `bottom` widget, and sliver support.

### Constructor parameters

| Name | Type | Default | Meaning |
|---|---|---|---|
| `title` | `Widget?` | `null` | Center slot (`AppBarItem.title`). |
| `leading` | `Widget?` | `null` | Left slot (`AppBarItem.backButton`). |
| `trailling` | `Widget?` | `null` | Right slot (`AppBarItem.actions`). *(sic — misspelled throughout the kit.)* |
| `bottom` | `PreferredSizeWidget?` | `null` | Extra row below the toolbar (e.g. tab bar); its preferred height is added to the bar height (`:44-46`, `:92-96`). |
| `spacing` | `double?` (themeable) | theme (`16.0`) | Horizontal padding of the toolbar contents. |
| `topInset` | `double?` (themeable) | theme (`0.0`) | Extra top margin (used by modals to inset the bar). |
| `borderRadius` | `BorderRadiusGeometry?` (themeable) | theme (`null`) | Passed to `NomoElevation`. |
| `height` | `double?` (themeable) | theme (`kToolbarHeight` = 56) | Toolbar height (excl. status bar & bottom). |
| `backgroundColor` | `Color?` (themeable) | theme (`Colors.red` — placeholder default!) | Bar background via `NomoElevation`. |
| `elevation` | `double?` (themeable) | theme (`2.0`) | Shadow via `NomoElevation`. |

Themeable properties: colors `borderRadius`, `backgroundColor`; sizing `spacing`, `topInset`, `height`, `elevation` (per `nomo_app_bar.theme_data.g.dart`).

### Build structure (`:54-106`)
`NomoDefaultTextStyle(h1 bold) > NomoElevation > Column[ SizedBox(statusBarPadding), Container(topInset margin) > Material(transparent) > Padding(horizontal spacing) > Column[ SizedBox(height) > AppBarLayoutDelegate(slots), bottom? ] ]`. Status-bar padding is taken from `MediaQuery.padding.top` (`:57`), so the bar paints under the status bar.

### Integration modes
- `asPreferedSizeWidget(context)` (`:41-52`): wraps itself in `PreferredSize` with height = theme height + status-bar padding + bottom height; used by `NomoScaffold` for the Material `Scaffold.appBar` slot.
- `toSliverBar(context)` (`:134-144`): wraps in a pinned `SliverPersistentHeader` with fixed min=max extent via `NomoSliverAppBarDelegate` (`:146-175`, `shouldRebuild => false` — a stale-theme quirk: theme changes won't rebuild the pinned bar).
- `copyWith` (`:108-132`) is used by the route-body/modal machinery to inject close buttons and radii. Note `copyWith(leading: ...)` cannot *clear* a field (null means "keep"), which is why `NomoRouteBody.copyWith` passes `SizedBox.shrink()` to hide the back button.

### Custom layout: `AppBarLayoutDelegate` + `AppBarLayoutRenderBox`

`AppBarLayoutDelegate` (`layout/appbar_layout_delegate.dart:10-41`) is a `SlottedMultiChildRenderObjectWidget<AppBarItem, RenderBox>` over the slot map. Quirks: `key: ValueKey(children.hashCode)` in the constructor (`:14`) forces render-object *recreation* whenever the slot map identity changes — defeats update-in-place, and indeed `updateRenderObject` (`:34-40`) is a no-op cast that never updates `items`.

`AppBarLayoutRenderBox.performLayout` (`layout/appbar_layout_renderbox.dart:28-132`) — measurement/positioning in prose:

1. Start with the incoming constraints; content size is provisionally `maxWidth × maxHeight`.
2. **Back button (leading)** is laid out first against the full constraints (min-height relaxed to 0), positioned at `x = 0`, vertically centered in `maxHeight`. Its width is subtracted from the remaining max width.
3. **Actions (trailing)** are laid out against the remaining constraints and positioned flush right (`x = maxWidth − actionsWidth`), vertically centered. Width again subtracted.
4. **Title** gets symmetric constraints: `maxWidth − 2 × max(leadingWidth, actionsWidth)` (`:82-89`) so it is centered on the *bar*, not on the leftover space; it is positioned at `x = (titleMaxWidth − titleWidth)/2 + biggestIndent`, i.e. truly centered as long as it fits between the wider of the two side slots mirrored on both sides.
5. **Unbounded-height fallback** (`:107-129`): if `maxHeight` was infinite, the bar sizes itself to the tallest child and re-centers all three children for that height.
6. `size = contentSize` — note the bar always takes the full `maxWidth` (and full `maxHeight` when bounded), regardless of children.

Painting (`:138-165`) paints a fully transparent rect (dead code — `Color(0x00FFFFFF)`), paints children at their offsets, and draws the debug overflow indicator. Hit-testing (`:171-187`) forwards with paint offsets, first-hit-wins, **no self hit** — empty regions of the bar are click-through.

Intrinsics (`:194-227`) *sum* the children's intrinsic widths **and heights** — summing heights is wrong for a horizontal layout (should be max) — and `computeDryLayout` (`:230-238`) sums both axes with unconstrained child constraints; both are incorrect-but-unused-in-practice code paths. No `TextDirection` support: leading is always physical-left (no RTL).

---

## 8. `NomoBottomBar` — `lib/components/app/bottom_bar/nomo_bottom_bar.dart`

### Purpose
Bottom navigation bar rendering 1–5 `NomoMenuItem`s (asserted at `:41-44`) as animated tiles in a `Row`.

### Constructor parameters

| Name | Type | Default | Meaning |
|---|---|---|---|
| `items` | `List<NomoMenuItem<T>>` | required | Menu entries (icon / image / text variants). |
| `selected` | `T?` | required | Key of the selected item (compared via `item.key == selected`). |
| `onTap` | `void Function(NomoMenuItem<T>)?` | `null` | Tap callback (navigation is up to the app). |
| `title` | `Widget?` | `null` | **Dead parameter** — declared (`:23`, `:46`) but never used in `build`. |
| `style` | `TextStyle?` | `null` | Label text style, forwarded to tiles. |
| `itemWidth` | `double?` | `null` | Fixed width per tile. |
| `widthFactor` | `double?` | `null` | `Center.widthFactor` inside the tile. |
| `itemDecorator` | `Widget Function(item, child)?` | `null` | Wraps each tile (e.g. badges/tooltips). |
| `mainAxisAlignment` | `MainAxisAlignment?` | `spaceEvenly` (inline fallback, not themed) | Row alignment. |
| `crossAxisAlignment` | `CrossAxisAlignment?` | `stretch` (inline fallback) | Row cross alignment. |
| `border` | `BoxBorder?` | `null` | Outer border via `NomoDecoration`. Not themeable. |
| `childDirection` | `Axis?` | `null` → `Axis.vertical` in tile | **Recent (commit 770b6de):** direction of icon vs. label inside each tile — `vertical` = icon above label (classic), `horizontal` = icon beside label. |
| `expandChildren` | `bool` | `false` | **Recent (commit bccec60):** wraps each (decorated) tile in `Expanded` so tiles share width equally (`:132`). |
| `height` | `double?` (themeable) | theme (`56.0`) | Bar height. |
| `spacing` | `double?` (themeable) | theme (`0.0`) | Gap between tiles (`Row.spacing`). |
| `iconSize` | `double?` (themeable) | theme (`28.0`) | Icon/image size. |
| `padding` | `EdgeInsetsGeometry?` (themeable) | theme (`EdgeInsets.all(4)`) | Bar inner padding. |
| `elevation` | `double?` (themeable) | theme (`16.0`) | Shadow via `NomoDecoration`. |
| `itemPadding` | `EdgeInsetsGeometry?` (themeable) | theme (`EdgeInsets.symmetric(horizontal: 8)`) | Per-tile padding. |
| `foreground` | `Color?` (themeable) | theme (`Colors.black`) | Unselected icon/label color. |
| `background` | `Color?` (themeable) | theme (`Colors.white`) | **Recent (commit 3ed8ff7):** bar background color. |
| `selectedForeground` | `Color?` (themeable) | theme (`Colors.red`) | Selected icon/label color. |
| `itemBackground` | `Color?` (themeable) | theme (`transparent`) | Unselected tile background. |
| `selectedBackground` | `Color?` (themeable) | theme (`transparent`) | Selected tile background. |
| `itemBorderRadius` | `BorderRadius?` (themeable) | theme (`circular(8)`) | Tile radius (Material + InkWell). |
| `borderRadius` | `BorderRadius?` (themeable) | theme (`BorderRadius.zero`) | Bar radius. |

### Build (`:101-137`)
`Container(height, NomoDecoration(background/elevation/borderRadius/border), padding) > Row(...)`. Each item builds a `NomoHorizontalListTile`, optionally decorated, optionally `Expanded`. Quirk: the per-item widget is built via an immediately-invoked closure `() { ... }.call()` inside the collection-for (`:119-133`) — works, but is an unusual idiom.

### `NomoHorizontalListTile` — `nomo_horizontal_tile.dart`

Stateful tile with two `AnimationController`s (200ms, `kDuration` from `nomo_vertical_menu.dart:11`) driving `ColorTween`s foreground (unselected→selected color) and background. Parameters: `item`, `theme` (the parent's resolved `NomoBottomBarThemeData` — passed by value, *not* re-resolved), `style`, `widthFactor`, `itemWidth`, `direction`, `onTap`, `selected`.

Behavior details:
- **Animations are kicked off inside `build`** (`:93-99`): `if (selected) forward else reverse` — side effects in build; works but re-triggers on every rebuild.
- Hover (desktop/web): `MouseRegion` forwards the *foreground* controller only on hover (`:101-109`), so hovering previews the selected color without background.
- Icon resolution via switch on item subtype (`:119-142`): `NomoMenuIconItem` → `Icon`; `NomoMenuImageItem` with `imagePath.contains('svg')` → `SvgPicture.asset` (the kit's only use of `flutter_svg` here — contradicts "zero runtime dependencies"); other images → `Image.asset` tinted by foreground; `NomoMenuTextItem` → no icon.
- Content: `Material(background) > InkWell(primary-tinted splash/hover/focus/highlight) > Container(itemWidth, itemPadding) > Center(widthFactor) > Flex(direction ?? vertical)[icon, 10.spacing, Row[leading?, NomoText(title, maxLines: 1), trailling?]]` (`:143-189`).
- Quirks: the fixed `10.spacing` between icon and label is not themeable and applies even when there is no icon; `leading!`/`trailling!` use `foreground!` null-assert (crashes if foreground tween is mid-flight null — practically fine since tween ends are non-null); `didUpdateWidget` rebuilds tweens but doesn't snap controller values when theme colors changed mid-selection.

Responsive behavior: the bar itself has none — visibility is governed by `NomoScaffold`'s `showBottomBar` sizing flag.

---

## 9. `NomoSider` — `lib/components/app/sider/nomo_sider.dart`

### Purpose
Left navigation rail/sidebar: full-height, fixed-width, animated-width container with optional header/footer and a scrollable middle.

### Constructor parameters

| Name | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Scrollable menu content (typically `NomoVerticalMenu`). |
| `header` | `Widget?` | `null` | Pinned above the scroll region. |
| `footer` | `Widget?` | `null` | Pinned below the scroll region. |
| `backgroundColor` | `Color?` (themeable) | theme (`primaryColor`) | Fill color. |
| `padding` | `EdgeInsetsGeometry?` (themeable) | theme (`EdgeInsets.all(16)`) | Inner padding. |
| `scrollPadding` | `double?` (themeable) | theme (`4.0`) | **Dead themeable field** — resolved into the theme but never referenced in `build`. |
| `width` | `double?` (themeable) | theme (`80`) | Rail width; because it's a sizing field it can differ per breakpoint, and the `AnimatedContainer` (140ms, `fastOutSlowIn`, `:47-49`) animates width changes (collapsed ↔ expanded rail via theme switch). |
| `border` | `Border?` (themeable) | theme (`Border(right: black12)`) | Edge border. |

### Build (`:43-74`)
`AnimatedContainer(width, height: context.height, color+border, padding) > Column[header?, Expanded(Scrollbar(thickness 8) > SingleChildScrollView(child)), footer?]`.

Quirks:
- A **new `ScrollController` is created on every build** (`:46`) and never disposed — a leak and breaks scroll-position persistence.
- `height: context.height` inside a `Row(crossAxisAlignment: stretch)` is redundant and couples to the MediaQuery override in the scaffold.
- Visibility switching (breakpoints) is again handled entirely by `NomoScaffold.showSider`; the sider only animates its *width* between sizing themes.

Themeable properties: colors `backgroundColor`, `border`; sizing `padding`, `scrollPadding`, `width`.

---

## 10. `NomoRouteBody` — `lib/components/app/routebody/nomo_route_body.dart`

### Purpose
The standard per-route content container: handles scrolling (plain child / list children / slivers), max-content-width centering, per-route app bar (inline or sliver), footers (in-flow, fill-remaining, floating), scrollbar, and background. It is the piece the modal/router layer manipulates via `copyWith`.

### Constructor parameters

| Name | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget?` | `null` | Single-child mode. Exactly one of the six content params must be non-null (assert `:76-84`). |
| `builder` | `WidgetBuilder?` | `null` | Deferred single-child mode. |
| `children` | `List<Widget>?` | `null` | Lazy list mode (`SliverList.builder`). |
| `childrenBuilder` | `List<Widget> Function(BuildContext)?` | `null` | Deferred list mode. |
| `slivers` | `List<Widget>?` | `null` | Raw sliver mode. |
| `sliverBuilder` | `List<Widget> Function(BuildContext)?` | `null` | Deferred sliver mode. |
| `appBar` | `NomoAppBar?` | `null` | Route-level bar: pinned sliver header in children/sliver-list mode (`:255-256` — only in `_ChildrenBody`!), plain column child in child mode (`:358`). **Quirk:** `_SliverBody` ignores `appBar` entirely. |
| `scrollController` | `ScrollController?` | `null` | External controller; otherwise **a new one is created each build and not disposed** (`:143`). Exposed to descendants via `DefaultScrollController` InheritedWidget (`:398-421`). |
| `useScrollBar` | `bool` | `false` | Wraps in `Scrollbar` with themed thickness/radius. |
| `footer` | `Widget?` | `null` | Bottom widget. With `expands` it becomes a `SliverFillRemaining` bottom-aligned footer (`FillRemainingFooter`, `:429-459`); otherwise flows after content. |
| `floatingFooter` | `Widget?` | `null` | Stacked above the scroll view (caller must position it). |
| `scrollable` | `bool` | `false` | Child mode only: wrap child in `Expanded > SingleChildScrollView`. |
| `expands` | `bool` | `true` | Child mode: wrap in `Expanded`; children mode: `shrinkWrap: !expands` and enables fill-remaining footer. |
| `borderRadius` | `BorderRadiusGeometry?` | `null` | Radius on the background container (modal styling). |
| `padding` | `EdgeInsets?` (themeable) | theme (`EdgeInsets.all(8)`) | Content padding; in children mode it is split — half the horizontal padding on each side as `SliverPadding`, half the vertical as top/bottom spacer slivers (`:241`, `:259-283`). |
| `scrollBarThickness` | `double?` (themeable) | theme (`8.0`) | Scrollbar. |
| `scrollBarRadius` | `Radius?` (themeable) | theme (`circular(4)`) | Scrollbar. |
| `maxContentWidth` | `double?` (themeable, `lerp: false`) | theme (`null`) | Centered max width (web/desktop reading width). |
| `backgroundColor` | `Color?` (themeable) | theme (`null`) | Solid background. |
| `background` | `Widget?` (themeable — a *widget* in the color theme!) | theme (`null`) | Arbitrary background widget stacked behind content; takes precedence over `backgroundColor` (`:195-218`). |

### Content-mode dispatch (`:145-182`)
A `switch` on `this` with `when` guards picks `_ChildBody` / `_SliverBody` / `_ChildrenBody`, with `Builder` indirection for the three builder variants. All three bodies share the pattern `Center > ConstrainedBox(maxContentWidth) > Stack[scrollView-or-column, floatingFooter?]`.

- `_ChildrenBody` (`:228-292`): `CustomScrollView` with optional pinned sliver app bar, `SliverList.builder` over the children, and the three-way footer arrangement (fill-remaining / in-flow / trailing spacer).
- `_SliverBody` (`:294-331`): raw slivers + optional fill-remaining footer (padding hardcoded `0.0`).
- `_ChildBody` (`:333-396`): `Column[appBar?, MultiWrapper(scrollable→Expanded+SingleChildScrollView | expands→Expanded)(Padding(child)), footer?]`.

### `copyWith` (`:86-138`)
Purpose-built for the modal/router layer: injects a `CloseButton` as `trailling`, optionally hides the back button (`SizedBox.shrink()` because `NomoAppBar.copyWith` can't null a field), applies top border radii to the bar, `topInset`, and modal bar height. Quirk: the parameter list is a grab-bag (`showAppBarBackButton`, `addTopInset`, `modalAppBarHeight`) revealing tight coupling between route body and the external `nomo_router` package.

### Helpers in the same file
`DefaultScrollController` (InheritedWidget for the active controller), `SliverUtil.toBox` extension, `FillRemainingFooter`, `DisableImplicitScrolling` physics (appears unused in this file — grep before deleting), `BorderRadiusToEdgeInsets` extension.

---

## 11. Recently added features (git log)

| Commit | Feature | Where |
|---|---|---|
| `bccec60` "Add Expand Children option & other" | `NomoBottomBar.expandChildren` (default `false`): wraps each tile (after `itemDecorator`) in `Expanded` for equal-width tiles (`nomo_bottom_bar.dart:56-60`, `:132`). "& other" in the same commit includes minor tweaks elsewhere. | bottom bar |
| `3ed8ff7` "Add Background Color to BottomBar" | `background` promoted to a `@NomoColorField(Colors.white)` themeable property applied via `NomoDecoration.color` (`:83-84`, `:108`). | bottom bar |
| `770b6de` "Add Direction for Child Layout in BottomBar" | `childDirection: Axis?` on the bar, forwarded as `direction` to the tile's `Flex` (`nomo_bottom_bar.dart:56`, `nomo_horizontal_tile.dart:158-159`); default vertical. | bottom bar / tile |
| `30aba3e` "Adjust Text to non resizable" | Related to global `TextScaler.noScaling` behavior (MetricReactor) / NomoText sizing. | app level |

These late additions are additive flags on already parameter-heavy constructors — symptomatic of the pattern that makes the components hard to evolve.

---

## 12. Quirks, dead code, complexity hotspots (rewrite checklist)

**Dead code / vestiges**
- `nomo_scaffold_layout.dart` is an empty file.
- `NomoBottomBar.title` parameter is never used.
- `NomoSider.scrollPadding` themeable field is resolved but never read.
- `AppBarLayoutRenderBox`: transparent background paint, incorrect and unused intrinsic/dry-layout implementations, `items` field never updated.
- `_ambiguate` shim and `MaterialApp` docs in the vendored notification file.
- `DisableImplicitScrolling` physics class defined but unused in the route body file.

**Bugs / fragile behavior**
- `ThemeAnimator` restarts tweens from stale `lastTheme` when interrupted mid-animation.
- `NomoScaffold.copyWith` drops drawer visibility notifiers.
- Un-disposed per-build `ScrollController`s in `NomoSider` and `NomoRouteBody`.
- `NomoRouteBody(slivers:)` silently ignores `appBar`.
- `NomoSliverAppBarDelegate.shouldRebuild => false` freezes theme changes on pinned bars.
- `AppBarLayoutDelegate`'s hash-based `ValueKey` recreates the render object instead of updating it; no RTL support; empty bar area is not hit-testable.
- Drawer close via `Navigator.pop` assumes the drawer is the top route.
- `NomoApp` ignores changes to `themeDelegate` after first build; `MetricReactor` assumes a single `FlutterView` and only reacts to width.
- Notification `of()` null-assert defeats its own assert message; single-notification, no queue.

**Complexity hotspots**
1. **Theme system + animation**: whole-app `NomoThemeData` lerp at 60fps on every color *and* breakpoint change, generated 6-class-per-component theme files, 3-layer resolution (`getFromContext`) duplicated per component, and responsiveness (bool sizing fields) entangled with theming.
2. **`NomoRouteBody`**: six mutually exclusive content modes, three body implementations, three footer strategies, split-padding math, plus a router-coupled `copyWith` — the single most over-loaded widget in the shell.
3. **In-app notification file**: ~550 lines of hand-rolled overlay/drag/animation mechanics (vendored package) with inverted positioning math for what is functionally a single toast.

**Half-hearted Material independence**: the shell claims to replace Material but depends on `Scaffold`, `ScaffoldMessenger`, `Material`, `InkWell`, `CloseButton`, `FloatingActionButtonLocation`, and Material localizations. A rewrite should decide: embrace Material as substrate, or actually own the scaffold layout (the deleted `nomo_scaffold_layout.dart` suggests owning it was tried and abandoned).
