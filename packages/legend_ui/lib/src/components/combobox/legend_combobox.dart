import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/dropdown/legend_dropdown.dart';
import 'package:legend_ui/src/primitives/legend_anchored_overlay.dart';
import 'package:legend_ui/src/primitives/legend_caret.dart';
import 'package:legend_ui/src/primitives/legend_field_core.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/theme/legend_widget_state.dart';
import 'package:legend_ui/src/tokens/legend_shadows.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'legend_combobox.theme.g.dart';

/// An entry of [LegendCombobox]. Mirrors [LegendDropdownItem] — one item
/// model per picker, never a parallel one.
class LegendComboboxItem<T> {
  const LegendComboboxItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Decides whether [item] matches the typed [query] — see
/// [LegendCombobox.filter].
typedef LegendComboboxFilter<T> =
    bool Function(LegendComboboxItem<T> item, String query);

/// A typeahead select: an editable field whose anchored option panel
/// filters as you type — the searchable sibling of [LegendDropdown]
/// (tap-to-pick, non-editable).
///
/// Composes [LegendFieldCore] (text editing/focus/cursor) +
/// [LegendAnchoredOverlay] (panel positioning + outside-tap dismissal) +
/// [LegendInteractive] (option input) + [LegendSurface] + [LegendCaret].
///
/// Legacy shipped no typeahead at all — its closed dropdowns over raw
/// `OverlayEntry`s were the only pickers (legacy-docs 06); this fills that
/// gap on the unified overlay engine (RFC-004 #19).
///
/// The panel opens on focus, tap, or typing; Up/Down move the highlighted
/// option (scrolling it into view), Enter commits it, Escape closes, and
/// selecting an option fills the field with its label. Losing focus
/// without a committed selection reverts the text to the selected value's
/// label (or clears it).
@LegendThemeable()
class LegendCombobox<T> extends StatefulWidget {
  /// The [menuBackground] color lifts into the `normal` member of the
  /// per-state theme field (RFC-002 R6).
  LegendCombobox({
    required this.items,
    required this.onChanged,
    super.key,
    this.value,
    this.filter,
    this.placeholder,
    this.emptyText = 'No matches',
    this.enabled = true,
    Color? menuBackground,
    this.menuBorderRadius,
    this.menuShadows,
    this.menuMaxHeight,
    this.itemPadding,
    this.textStyle,
  }) : menuBackground = menuBackground == null
           ? null
           : InteractiveColors(normal: menuBackground);

  final List<LegendComboboxItem<T>> items;
  final ValueChanged<T> onChanged;
  final T? value;

  /// Decides which items the typed query keeps in the panel; defaults to a
  /// case-insensitive substring match on the label.
  final LegendComboboxFilter<T>? filter;

  final String? placeholder;

  /// Shown inside the panel when the query filters every item out.
  final String emptyText;

  final bool enabled;

  /// Fill of the panel surface and its options, per interaction state —
  /// `normal` paints the whole panel, `hovered`/`pressed`/`focused`
  /// highlight the active option (pointer or keyboard).
  @Style<InteractiveColors>.resolve(_menuBackground)
  final InteractiveColors? menuBackground;

  /// Corner rounding of the panel and the field.
  @Style<BorderRadius>.resolve(_menuBorderRadius)
  final BorderRadius? menuBorderRadius;

  /// Drop shadow lifting the panel off the page.
  @Style<List<BoxShadow>>.resolve(ShadowRef.medium)
  final List<BoxShadow>? menuShadows;

  /// The panel scrolls past this height instead of overflowing the screen
  /// on long option lists.
  @Style<double>(320)
  final double? menuMaxHeight;

  /// Inner padding of each option (and the field).
  @Style<EdgeInsetsGeometry>.resolve(_itemPadding)
  final EdgeInsetsGeometry? itemPadding;

  /// Text style of the option labels and the entered text.
  @Style<TextStyle>.resolve(TextRef.b2)
  final TextStyle? textStyle;

  @override
  State<LegendCombobox<T>> createState() => _LegendComboboxState<T>();
}

class _LegendComboboxState<T> extends State<LegendCombobox<T>> {
  final _portal = OverlayPortalController();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// Stable per-value keys so the highlighted option can be scrolled into
  /// view via its own context.
  final _itemKeys = <T, GlobalKey>{};

  /// The typed query; null (fresh open, or after a commit) shows all items.
  String? _query;

  int _highlight = 0;

  LegendComboboxItem<T>? get _selected =>
      widget.items.where((item) => item.value == widget.value).firstOrNull;

  List<LegendComboboxItem<T>> get _filtered {
    final query = _query;
    if (query == null || query.isEmpty) return widget.items;
    final filter = widget.filter ?? _defaultFilter;
    return [
      for (final item in widget.items)
        if (filter(item, query)) item,
    ];
  }

  static bool _defaultFilter(LegendComboboxItem<dynamic> item, String query) =>
      item.label.toLowerCase().contains(query.toLowerCase());

  @override
  void initState() {
    super.initState();
    _controller.text = _selected?.label ?? '';
    _focusNode.addListener(_onFocusChange);
    // Repaints the placeholder when programmatic edits empty the text.
    _controller.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(LegendCombobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An external value change re-syncs the text; after a commit the text
    // already equals the label, so the caret position survives.
    if (widget.value != oldWidget.value) {
      final label = _selected?.label ?? '';
      if (_controller.text != label) {
        _controller.text = label;
        _controller.selection = TextSelection.collapsed(offset: label.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _openPanel();
    } else {
      // Blur without a committed selection reverts to the selected label.
      _controller.text = _selected?.label ?? '';
      _closePanel();
    }
    setState(() {});
  }

  void _openPanel() {
    if (!widget.enabled || _portal.isShowing) return;
    _query = null;
    final selectedIndex = widget.items.indexWhere(
      (item) => item.value == widget.value,
    );
    _highlight = selectedIndex < 0 ? 0 : selectedIndex;
    _portal.show();
    setState(() {});
    _revealHighlight();
  }

  void _closePanel() {
    if (!_portal.isShowing) return;
    _portal.hide();
    setState(() {});
  }

  void _onTextChanged(String text) {
    _query = text;
    _highlight = 0;
    if (!_portal.isShowing && widget.enabled) _portal.show();
    setState(() {});
  }

  void _select(LegendComboboxItem<T> item) {
    _portal.hide();
    _query = null;
    _controller.text = item.label;
    _controller.selection = TextSelection.collapsed(offset: item.label.length);
    setState(() {});
    widget.onChanged(item.value);
  }

  void _moveHighlight(int delta) {
    final filtered = _filtered;
    if (filtered.isEmpty) return;
    setState(
      () => _highlight = (_highlight + delta).clamp(0, filtered.length - 1),
    );
    _revealHighlight();
  }

  void _revealHighlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filtered = _filtered;
      if (_highlight >= filtered.length) return;
      final context = _itemKeys[filtered[_highlight].value]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, alignment: 0.5);
      }
    });
  }

  void _commitHighlight() {
    final filtered = _filtered;
    if (_highlight < filtered.length) _select(filtered[_highlight]);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (!_portal.isShowing) {
      if (key == LogicalKeyboardKey.arrowDown && widget.enabled) {
        _openPanel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _commitHighlight();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _closePanel();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final open = _portal.isShowing;
    final foreground = widget.enabled
        ? tokens.colors.foreground1
        : tokens.colors.onDisabled;

    return LegendAnchoredOverlay(
      controller: _portal,
      offset: Offset(0, tokens.sizes.xs),
      onDismiss: _closePanel,
      overlay: (context) => _menu(theme, tokens),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled
              ? () {
                  _focusNode.requestFocus();
                  _openPanel();
                }
              : null,
          child: LegendSurface(
            color: widget.enabled
                ? tokens.colors.background1
                : tokens.colors.disabled,
            borderRadius: theme.menuBorderRadius,
            border: Border.all(
              color: _focusNode.hasFocus || open
                  ? tokens.colors.primary
                  : tokens.colors.background3,
              width: tokens.sizes.borderWidth,
            ),
            padding: theme.itemPadding,
            duration: const Duration(milliseconds: 120),
            child: Row(
              spacing: tokens.sizes.sm,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      if (_controller.text.isEmpty &&
                          widget.placeholder != null)
                        ExcludeSemantics(
                          child: Text(
                            widget.placeholder!,
                            style: theme.textStyle.copyWith(
                              color: tokens.colors.foreground3,
                            ),
                          ),
                        ),
                      LegendFieldCore(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: theme.textStyle.copyWith(color: foreground),
                        cursorColor: tokens.colors.primary,
                        backgroundCursorColor: tokens.colors.background3,
                        selectionColor: tokens.colors.primary.withValues(
                          alpha: 0.3,
                        ),
                        readOnly: !widget.enabled,
                        onChanged: _onTextChanged,
                        onSubmitted: (_) {
                          if (_portal.isShowing) _commitHighlight();
                        },
                      ),
                    ],
                  ),
                ),
                LegendCaret(color: foreground, open: open),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(LegendComboboxTheme theme, LegendTokens tokens) {
    final filtered = _filtered;
    return LegendSurface(
      color: theme.menuBackground.normal,
      borderRadius: theme.menuBorderRadius,
      shadows: theme.menuShadows,
      clip: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: theme.menuMaxHeight),
        child: filtered.isEmpty
            ? Padding(
                padding: theme.itemPadding,
                child: Text(
                  widget.emptyText,
                  style: theme.textStyle.copyWith(
                    color: tokens.colors.foreground3,
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (index, item) in filtered.indexed)
                      // MergeSemantics folds the selected flag into the
                      // option's own labeled node, so assistive tech
                      // announces one option with its selected state.
                      MergeSemantics(
                        key: _itemKeys.putIfAbsent(item.value, GlobalKey.new),
                        child: Semantics(
                          selected: item.value == widget.value,
                          child: LegendInteractive(
                            semanticLabel: item.label,
                            onTap: () => _select(item),
                            onHoverChange: (hovering) {
                              if (hovering) {
                                setState(() => _highlight = index);
                              }
                            },
                            builder: (context, states) {
                              // The keyboard highlight paints as hover so
                              // the two input modes share one visual.
                              final state = index == _highlight
                                  ? const LegendStateHovered()
                                  : states.effective;
                              return LegendSurface(
                                color: theme.menuBackground.resolve(
                                  state,
                                  tokens.states,
                                ),
                                padding: theme.itemPadding,
                                child: Text(
                                  item.label,
                                  style: theme.textStyle.copyWith(
                                    color: item.value == widget.value
                                        ? tokens.colors.primary
                                        : tokens.colors.foreground1,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

InteractiveColors _menuBackground(LegendTokens t) => InteractiveColors(
  normal: t.colors.surface,
  hovered: t.colors.background2,
  pressed: t.colors.background2,
  focused: t.colors.background2,
);

BorderRadius _menuBorderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

EdgeInsetsGeometry _itemPadding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);
