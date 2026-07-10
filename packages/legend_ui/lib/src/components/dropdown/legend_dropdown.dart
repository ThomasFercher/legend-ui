import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_anchored_overlay.dart';
import 'package:legend_ui/src/primitives/legend_caret.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_shadows.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'legend_dropdown.theme.g.dart';

/// An entry of [LegendDropdown]. One item model — legacy shipped two
/// dropdown implementations with two item models (legacy-docs 06).
class LegendDropdownItem<T> {
  const LegendDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// The one dropdown: an anchored menu over a field-like trigger.
///
/// Composes [LegendAnchoredOverlay] (menu positioning + dismissal) +
/// [LegendInteractive] (trigger and item input) + [LegendSurface] +
/// [LegendCaret].
///
/// Replaces legacy's two parallel dropdown implementations and their raw
/// `OverlayEntry` management (legacy-docs 06).
@LegendThemeable()
class LegendDropdown<T> extends StatefulWidget {
  /// The [menuBackground] color lifts into the `normal` member of the
  /// per-state theme field (RFC-002 R6).
  LegendDropdown({
    required this.items,
    required this.onChanged,
    super.key,
    this.value,
    this.placeholder,
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

  final List<LegendDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final T? value;
  final String? placeholder;
  final bool enabled;

  /// Fill of the menu surface and its items, per interaction state —
  /// `normal` paints the whole menu, `hovered`/`pressed`/`focused`
  /// highlight the item under the pointer.
  @Style<InteractiveColors>.resolve(_menuBackground)
  final InteractiveColors? menuBackground;

  /// Corner rounding of the menu and the trigger field.
  @Style<BorderRadius>.resolve(_menuBorderRadius)
  final BorderRadius? menuBorderRadius;

  /// Drop shadow lifting the menu off the page.
  @Style<List<BoxShadow>>.resolve(ShadowRef.medium)
  final List<BoxShadow>? menuShadows;

  /// The menu scrolls past this height instead of overflowing the screen
  /// on long item lists.
  @Style<double>(320)
  final double? menuMaxHeight;

  /// Inner padding of each menu item (and the trigger field).
  @Style<EdgeInsetsGeometry>.resolve(_itemPadding)
  final EdgeInsetsGeometry? itemPadding;

  /// Text style of the item labels and the selected value.
  @Style<TextStyle>.resolve(TextRef.b2)
  final TextStyle? textStyle;

  @override
  State<LegendDropdown<T>> createState() => _LegendDropdownState<T>();
}

class _LegendDropdownState<T> extends State<LegendDropdown<T>> {
  final _controller = OverlayPortalController();

  void _select(T value) {
    _controller.hide();
    setState(() {});
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final selected = widget.items
        .where((item) => item.value == widget.value)
        .firstOrNull;

    return LegendAnchoredOverlay(
      controller: _controller,
      offset: Offset(0, tokens.sizes.xs),
      onDismiss: () {
        _controller.hide();
        setState(() {});
      },
      overlay: (context) => _menu(theme, tokens),
      child: LegendInteractive(
        enabled: widget.enabled,
        semanticLabel: selected?.label ?? widget.placeholder,
        onTap: () {
          _controller.toggle();
          setState(() {});
        },
        builder: (context, states) {
          final foreground = states.disabled
              ? tokens.colors.onDisabled
              : tokens.colors.foreground1;
          return LegendSurface(
            color: states.disabled
                ? tokens.colors.disabled
                : tokens.colors.background1,
            borderRadius: theme.menuBorderRadius,
            border: Border.all(
              color: states.focused || _controller.isShowing
                  ? tokens.colors.primary
                  : tokens.colors.background3,
              width: tokens.sizes.borderWidth,
            ),
            padding: theme.itemPadding,
            duration: const Duration(milliseconds: 120),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: tokens.sizes.sm,
              children: [
                Text(
                  selected?.label ?? widget.placeholder ?? '',
                  style: theme.textStyle.copyWith(
                    color: selected == null
                        ? tokens.colors.foreground3
                        : foreground,
                  ),
                ),
                LegendCaret(color: foreground, open: _controller.isShowing),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _menu(LegendDropdownTheme theme, LegendTokens tokens) {
    return LegendSurface(
      color: theme.menuBackground.normal,
      borderRadius: theme.menuBorderRadius,
      shadows: theme.menuShadows,
      clip: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: theme.menuMaxHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in widget.items)
                LegendInteractive(
                  semanticLabel: item.label,
                  onTap: () => _select(item.value),
                  builder: (context, states) {
                    return LegendSurface(
                      color: theme.menuBackground.resolve(
                        states.effective,
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
