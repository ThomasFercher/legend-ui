import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/dropdown/nomo_dropdown.theme.g.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_anchored_overlay.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_caret.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_interactive.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';
import 'package:nomo_ui_kit/src/tokens/nomo_tokens.dart';

/// An entry of [NomoDropdown]. One item model — legacy shipped two
/// dropdown implementations with two item models (legacy-docs 06).
class NomoDropdownItem<T> {
  const NomoDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// The one dropdown: an anchored menu over a field-like trigger,
/// built on [NomoAnchoredOverlay] + [NomoInteractive] + [NomoSurface].
@NomoThemeable()
class NomoDropdown<T> extends StatefulWidget {
  const NomoDropdown({
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

  final List<NomoDropdownItem<T>> items;
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
  State<NomoDropdown<T>> createState() => _NomoDropdownState<T>();
}

class _NomoDropdownState<T> extends State<NomoDropdown<T>> {
  final _controller = OverlayPortalController();

  NomoDropdownTheme _theme(BuildContext context) => NomoDropdownTheme.of(
    context,
    NomoDropdownThemeNullable(
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
    final tokens = NomoTheme.of(context).tokens;
    final selected = widget.items
        .where((item) => item.value == widget.value)
        .firstOrNull;

    return NomoAnchoredOverlay(
      controller: _controller,
      offset: Offset(0, tokens.sizes.xs),
      onDismiss: () {
        _controller.hide();
        setState(() {});
      },
      overlay: (context) => _menu(theme, tokens),
      child: NomoInteractive(
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
          return NomoSurface(
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
                NomoCaret(color: foreground, open: _controller.isShowing),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _menu(NomoDropdownTheme theme, NomoTokens tokens) {
    return NomoSurface(
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
                NomoInteractive(
                  semanticLabel: item.label,
                  onTap: () => _select(item.value),
                  builder: (context, states) {
                    return NomoSurface(
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
