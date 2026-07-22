import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/context_menu/legend_context_menu.dart';
import 'package:legend_ui/src/components/divider/legend_divider.dart';
import 'package:legend_ui/src/components/dropdown/legend_dropdown.dart';
import 'package:legend_ui/src/components/popover/legend_popover.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/theme/legend_widget_state.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_shadows.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'legend_menu.theme.g.dart';

/// One entry of a [LegendMenu] — an action ([LegendMenuItem]) or a
/// separator between groups of them ([LegendMenuDivider]).
sealed class LegendMenuEntry {
  const LegendMenuEntry();
}

/// One action in a [LegendMenu].
///
/// The kit is icon-agnostic (DESIGN.md §4), so [icon] is any widget —
/// typically an `Icon` from the app's own icon set.
class LegendMenuItem extends LegendMenuEntry {
  const LegendMenuItem({
    required this.label,
    required this.onSelected,
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  /// The action's visible (and announced) name.
  final String label;

  /// Runs after the menu has closed itself on selection.
  final VoidCallback onSelected;

  /// Optional leading widget before the [label].
  final Widget? icon;

  /// Renders the [label] in [LegendMenu.destructiveColor] to mark an
  /// irreversible action (delete, disconnect, revoke).
  final bool destructive;

  /// False renders the item muted and inert: no tap, no highlight, and
  /// keyboard navigation skips it.
  final bool enabled;
}

/// A separator line between groups of [LegendMenuItem]s, drawn with
/// [LegendDivider].
class LegendMenuDivider extends LegendMenuEntry {
  const LegendMenuDivider();
}

/// A button-anchored action menu: activating [trigger] opens a floating
/// list of actions that closes on selection, on an outside tap, and on
/// Escape.
///
/// Composes [LegendPopover] in manual mode (the anchored themed panel and
/// its dismissal) with [LegendInteractive] for the trigger and each item
/// row, and [LegendDivider] for separators.
///
/// Fills the RFC-004 catalog gap "[LegendContextMenu] is right-click only
/// — no button-anchored action Menu"; distinct from [LegendDropdown],
/// which selects a value instead of running actions.
///
/// Keyboard: while open, focus sits on the panel — ArrowDown/ArrowUp move
/// the highlight (wrapping, skipping disabled items), Enter/Space
/// activates the highlighted item, and Escape closes and returns focus to
/// the trigger. Items announce plain button semantics.
@LegendThemeable()
class LegendMenu extends StatefulWidget {
  const LegendMenu({
    required this.trigger,
    required this.items,
    super.key,
    this.controller,
    this.placement = LegendPopoverPlacement.bottom,
    this.offset = Offset.zero,
    this.enabled = true,
    this.semanticLabel,
    this.background,
    this.borderRadius,
    this.shadows,
    this.itemPadding,
    this.itemColors,
    this.textStyle,
    this.destructiveColor,
  });

  /// What opens the menu — wrapped in a [LegendInteractive], so it taps,
  /// hovers, focuses, and keyboard-activates as a semantic button. Pass
  /// plain content (a card, an icon, a label), not a widget that is
  /// already a button itself.
  final Widget trigger;

  /// The menu's entries, top to bottom — [LegendMenuItem] actions
  /// interleaved with [LegendMenuDivider] separators.
  final List<LegendMenuEntry> items;

  /// Opens and closes the menu imperatively and exposes `isOpen`. Null
  /// lets the menu own a private controller.
  final LegendPopoverController? controller;

  /// Which side of the trigger the menu attaches to.
  final LegendPopoverPlacement placement;

  /// Extra translation applied after placement — the knob for a gap
  /// between trigger and menu.
  final Offset offset;

  /// When false the trigger is inert and an open menu stays closable
  /// through the [controller] only.
  final bool enabled;

  /// Announced for the trigger button.
  final String? semanticLabel;

  /// Fill of the floating menu panel.
  @Style<Color>.resolve(ColorRef.surface)
  final Color? background;

  /// Corner rounding of the menu panel.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Drop shadow lifting the menu off the page.
  @Style<List<BoxShadow>>.resolve(ShadowRef.medium)
  final List<BoxShadow>? shadows;

  /// Inner padding of each item row.
  @Style<EdgeInsetsGeometry>.resolve(_itemPadding)
  final EdgeInsetsGeometry? itemPadding;

  /// Fill of an item row per interaction state — `normal` stays
  /// transparent so [background] shows through; `hovered` also paints the
  /// keyboard highlight.
  @Style<InteractiveColors>.resolve(_itemColors)
  final InteractiveColors? itemColors;

  /// Text style of the item labels.
  @Style<TextStyle>.resolve(TextRef.b2)
  final TextStyle? textStyle;

  /// Label color of [LegendMenuItem.destructive] items.
  @Style<Color>.resolve(ColorRef.error)
  final Color? destructiveColor;

  @override
  State<LegendMenu> createState() => _LegendMenuState();
}

class _LegendMenuState extends State<LegendMenu> {
  /// Created lazily when the caller passes no controller; only an owned
  /// controller is disposed here.
  LegendPopoverController? _internal;

  LegendPopoverController get _controller =>
      widget.controller ?? (_internal ??= LegendPopoverController());

  final FocusNode _triggerFocus = FocusNode(debugLabel: 'LegendMenu.trigger');

  /// Index into [LegendMenu.items] of the keyboard-highlighted item; null
  /// until the first ArrowDown/ArrowUp (or hover) after opening.
  int? _highlighted;

  @override
  void didUpdateWidget(LegendMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) _controller.hide();
  }

  @override
  void dispose() {
    _internal?.dispose();
    _triggerFocus.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isOpen) {
      _controller.hide();
      return;
    }
    if (!widget.items.any((e) => e is LegendMenuItem)) return;
    // Every open starts unhighlighted; the first arrow key (or hover)
    // picks an item.
    setState(() => _highlighted = null);
    _controller.show();
  }

  /// Closing on Escape or selection returns focus to the trigger; an
  /// outside tap does not — the pointer user is already elsewhere.
  void _close({required bool refocusTrigger}) {
    _controller.hide();
    if (refocusTrigger) _triggerFocus.requestFocus();
  }

  void _select(LegendMenuItem item) {
    _close(refocusTrigger: true);
    item.onSelected();
  }

  /// Moves the highlight by [delta] across enabled items, wrapping at
  /// both ends; the first move enters the list from the matching end.
  void _move(int delta) {
    final indexes = [
      for (final (index, entry) in widget.items.indexed)
        if (entry is LegendMenuItem && entry.enabled) index,
    ];
    if (indexes.isEmpty) return;
    final current = _highlighted == null ? -1 : indexes.indexOf(_highlighted!);
    final next = current == -1
        ? (delta > 0 ? 0 : indexes.length - 1)
        // Dart's % is Euclidean, so -1 wraps to the last index.
        : (current + delta) % indexes.length;
    setState(() => _highlighted = indexes[next]);
  }

  void _activateHighlighted() {
    final index = _highlighted;
    if (index == null || index >= widget.items.length) return;
    final entry = widget.items[index];
    if (entry is LegendMenuItem && entry.enabled) _select(entry);
  }

  KeyEventResult _handlePanelKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      _activateHighlighted();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _close(refocusTrigger: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _item(
    int index,
    LegendMenuItem item,
    LegendMenuTheme theme,
    LegendTokens tokens,
  ) {
    return LegendInteractive(
      enabled: item.enabled,
      semanticLabel: item.label,
      onTap: () => _select(item),
      // Hover adopts the highlight so a later arrow key continues from
      // the pointer's item instead of jumping back to the top.
      onHoverChange: (hovering) {
        if (hovering) setState(() => _highlighted = index);
      },
      builder: (context, states) {
        final state = states.effective;
        // The keyboard highlight paints as hover: focus stays on the
        // panel, so the row itself is never focused.
        final effective = state is LegendStateNormal && index == _highlighted
            ? const LegendStateHovered()
            : state;
        final foreground = !item.enabled
            ? tokens.colors.onDisabled
            : item.destructive
            ? theme.destructiveColor
            : tokens.colors.foreground1;
        return LegendSurface(
          color: theme.itemColors.resolve(effective, tokens.states),
          padding: theme.itemPadding,
          duration: const Duration(milliseconds: 120),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.sizes.sm,
            children: [
              ?item.icon,
              Text(
                item.label,
                style: theme.textStyle.copyWith(color: foreground),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _panel(LegendMenuTheme theme, LegendTokens tokens) {
    // IntrinsicWidth sizes the menu to its widest item, so the stretched
    // rows share it without ballooning to the overlay's width.
    return Focus(
      autofocus: true,
      onKeyEvent: _handlePanelKey,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, entry) in widget.items.indexed)
              switch (entry) {
                LegendMenuDivider() => LegendDivider(spacing: tokens.sizes.xs),
                final LegendMenuItem item => _item(index, item, theme, tokens),
              },
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;

    return LegendPopover(
      controller: _controller,
      trigger: LegendPopoverTrigger.manual,
      placement: widget.placement,
      offset: widget.offset,
      // The panel's own Focus below takes over: it adds arrow-key
      // navigation on top of the Escape dismissal.
      autofocus: false,
      background: theme.background,
      borderRadius: theme.borderRadius,
      shadows: theme.shadows,
      // Rows carry their own padding; the panel adds none.
      padding: EdgeInsets.zero,
      overlay: (context) => _panel(theme, tokens),
      child: LegendInteractive(
        enabled: widget.enabled,
        semanticLabel: widget.semanticLabel,
        focusNode: _triggerFocus,
        onTap: _toggle,
        builder: (context, states) => widget.trigger,
      ),
    );
  }
}

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

EdgeInsetsGeometry _itemPadding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);

InteractiveColors _itemColors(LegendTokens t) => InteractiveColors(
  normal: const Color(0x00000000),
  hovered: t.colors.background2,
  pressed: t.colors.background2,
  focused: t.colors.background2,
);
