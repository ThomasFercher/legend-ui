import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/dropdown/legend_dropdown.theme.g.dart';
import 'package:legend_ui/src/primitives/legend_anchored_overlay.dart';
import 'package:legend_ui/src/primitives/legend_caret.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

/// An entry of [LegendDropdown]. One item model — legacy shipped two
/// dropdown implementations with two item models (legacy-docs 06).
class LegendDropdownItem<T> {
  const LegendDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// The one dropdown: an anchored menu over a field-like trigger,
/// built on [LegendAnchoredOverlay] + [LegendInteractive] + [LegendSurface].
@LegendThemeable()
class LegendDropdown<T> extends StatefulWidget {
  const LegendDropdown({
    required this.items,
    required this.onChanged,
    super.key,
    this.value,
    this.placeholder,
    this.enabled = true,
    this.menuBackground,
    this.menuBorderRadius,
    this.menuShadows,
    this.menuMaxHeight,
    this.itemPadding,
    this.textStyle,
  });

  final List<LegendDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final T? value;
  final String? placeholder;
  final bool enabled;

  @Themed(defaultsTo: 't.colors.surface')
  final Color? menuBackground;

  @Themed(defaultsTo: 't.sizes.borderRadiusMd')
  final BorderRadius? menuBorderRadius;

  @Themed(defaultsTo: 't.shadows.medium')
  final List<BoxShadow>? menuShadows;

  /// The menu scrolls past this height instead of overflowing the screen
  /// on long item lists.
  @Themed(defaultsTo: '320.0')
  final double? menuMaxHeight;

  @Themed(
    defaultsTo:
        'EdgeInsets.symmetric(horizontal: t.sizes.md, '
        'vertical: t.sizes.sm)',
  )
  final EdgeInsetsGeometry? itemPadding;

  @Themed(defaultsTo: 't.typography.b2')
  final TextStyle? textStyle;

  @override
  State<LegendDropdown<T>> createState() => _LegendDropdownState<T>();
}

class _LegendDropdownState<T> extends State<LegendDropdown<T>> {
  final _controller = OverlayPortalController();

  LegendDropdownTheme _theme(BuildContext context) => LegendDropdownTheme.of(
    context,
    LegendDropdownThemeNullable(
      menuBackground: widget.menuBackground,
      menuBorderRadius: widget.menuBorderRadius,
      menuShadows: widget.menuShadows,
      menuMaxHeight: widget.menuMaxHeight,
      itemPadding: widget.itemPadding,
      textStyle: widget.textStyle,
    ),
  );

  void _select(T value) {
    _controller.hide();
    setState(() {});
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
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
      color: theme.menuBackground,
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
                      color: states.hovered || states.focused
                          ? tokens.colors.background2
                          : theme.menuBackground,
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
