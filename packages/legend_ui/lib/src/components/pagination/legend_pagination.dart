import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_caret.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_pagination.theme.g.dart';

/// A row of page-number buttons with previous/next chevrons — a controlled
/// component: [page] names the current page, [onChanged] reports the page
/// to move to, the state lives with the caller (the same idiom as
/// `LegendTabs`).
///
/// Composes [LegendInteractive] (per-button activation, hover/press/focus)
/// + [LegendSurface] (button fills) + [LegendCaret] (the chevron glyphs).
///
/// Long ranges collapse through the standard window (1 … 4 5 6 … 20):
/// the first and last page stay reachable, [maxVisible] slots around the
/// current page, ellipses marking the gaps. The chevrons disable at the
/// ends; the current page announces selected semantics and activating it
/// is a no-op (an exclusive control never deselects). Keyboard users move
/// between buttons with standard focus traversal and activate with
/// Enter/Space.
@LegendThemeable()
class LegendPagination extends StatelessWidget {
  /// The [fill] and [selectedFill] colors lift into the `normal` member of
  /// the per-state theme fields (RFC-002 R6).
  LegendPagination({
    required this.page,
    required this.pageCount,
    required this.onChanged,
    super.key,
    this.maxVisible = 7,
    this.semanticLabel,
    this.previousLabel = 'Previous page',
    this.nextLabel = 'Next page',
    Color? fill,
    Color? selectedFill,
    this.itemStyle,
    this.selectedStyle,
    this.chevronColor,
    this.borderRadius,
    this.itemPadding,
    this.spacing,
  }) : fill = fill == null ? null : InteractiveColors(normal: fill),
       selectedFill = selectedFill == null
           ? null
           : InteractiveColors(normal: selectedFill),
       assert(pageCount >= 1, 'pageCount must be at least 1.'),
       assert(
         page >= 1 && page <= pageCount,
         'page must be within 1..pageCount.',
       ),
       assert(
         maxVisible >= 5,
         'maxVisible must be at least 5 (first page, ellipsis, current '
         'page, ellipsis, last page).',
       );

  /// The current page, 1-based.
  final int page;

  /// Total number of pages.
  final int pageCount;

  /// Called with the page to move to. Activating the current page reports
  /// nothing.
  final ValueChanged<int> onChanged;

  /// Most number slots shown (ellipses included) before the range
  /// collapses into the standard window.
  final int maxVisible;

  /// What this control pages through (e.g. 'Transaction pages') —
  /// announced on the row itself; each button is labeled by its number.
  final String? semanticLabel;

  /// Semantic label of the previous-page chevron.
  final String previousLabel;

  /// Semantic label of the next-page chevron.
  final String nextLabel;

  /// Fill of unselected buttons per interaction state — an unset `normal`
  /// keeps them transparent; `hovered`/`pressed`/`focused` tint the button
  /// under the pointer (and the keyboard focus).
  @Style<InteractiveColors>.resolve(_fill)
  final InteractiveColors? fill;

  /// Fill of the current-page button per interaction state.
  @Style<InteractiveColors>.resolve(_selectedFill)
  final InteractiveColors? selectedFill;

  /// Text style of unselected page numbers.
  @Style<TextStyle>.resolve(_itemStyle)
  final TextStyle? itemStyle;

  /// Text style of the current page's number.
  @Style<TextStyle>.resolve(_selectedStyle)
  final TextStyle? selectedStyle;

  /// Color of the previous/next chevron glyphs.
  @Style<Color>.resolve(ColorRef.foreground2, lerp: true)
  final Color? chevronColor;

  /// Corner rounding of each button.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Inner padding of each button, around its number or chevron.
  @Style<EdgeInsetsGeometry>.resolve(_itemPadding)
  final EdgeInsetsGeometry? itemPadding;

  /// Gap between adjacent buttons.
  @Style<double>.resolve(SizeRef.xs)
  final double? spacing;

  /// The focus ring: a border that stays transparent at rest so focusing
  /// never shifts layout (focus draws as a ring, not a fill shift —
  /// RFC-002 R6).
  Border _focusRing(LegendInteractionStates states, LegendTokens tokens) {
    return Border.all(
      color: states.focused && !states.disabled
          ? tokens.colors.primary
          : const Color(0x00000000),
      width: tokens.sizes.borderWidth,
    );
  }

  Widget _number(int number, LegendPaginationTheme theme, LegendTokens tokens) {
    final selected = number == page;
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        child: LegendInteractive(
          onTap: () {
            // Exclusive: the current page never re-reports.
            if (!selected) onChanged(number);
          },
          builder: (context, states) {
            var style = selected ? theme.selectedStyle : theme.itemStyle;
            if (!selected && (states.hovered || states.pressed)) {
              style = style.copyWith(color: tokens.colors.foreground1);
            }
            return LegendSurface(
              color: (selected ? theme.selectedFill : theme.fill).resolve(
                states.effective,
                tokens.states,
              ),
              border: _focusRing(states, tokens),
              borderRadius: theme.borderRadius,
              padding: theme.itemPadding,
              duration: const Duration(milliseconds: 120),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: tokens.sizes.md),
                child: Center(child: Text('$number', style: style)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _chevron(
    LegendPaginationTheme theme,
    LegendTokens tokens, {
    required int target,
    required String label,
    required int quarterTurns,
  }) {
    return LegendInteractive(
      enabled: target >= 1 && target <= pageCount,
      onTap: () => onChanged(target),
      semanticLabel: label,
      builder: (context, states) => LegendSurface(
        color: theme.fill.resolve(states.effective, tokens.states),
        border: _focusRing(states, tokens),
        borderRadius: theme.borderRadius,
        padding: theme.itemPadding,
        duration: const Duration(milliseconds: 120),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: tokens.sizes.md),
          child: Center(
            child: RotatedBox(
              quarterTurns: quarterTurns,
              child: LegendCaret(
                color: states.disabled
                    ? tokens.colors.onDisabled
                    : theme.chevronColor,
                open: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ellipsis(LegendPaginationTheme theme, LegendTokens tokens) {
    return ExcludeSemantics(
      child: Padding(
        padding: theme.itemPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: tokens.sizes.md),
          child: Center(child: Text('…', style: theme.itemStyle)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    // The chevrons point along the reading direction: previous backward,
    // next forward.
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      // Equal-height buttons: the chevron cells stretch to the number
      // cells' text height instead of shrink-wrapping their glyph.
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.spacing,
          children: [
            _chevron(
              theme,
              tokens,
              target: page - 1,
              label: previousLabel,
              quarterTurns: rtl ? 3 : 1,
            ),
            for (final slot in _window(page, pageCount, maxVisible))
              if (slot == null)
                _ellipsis(theme, tokens)
              else
                _number(slot, theme, tokens),
            _chevron(
              theme,
              tokens,
              target: page + 1,
              label: nextLabel,
              quarterTurns: rtl ? 1 : 3,
            ),
          ],
        ),
      ),
    );
  }
}

/// The visible number slots, null marking an ellipsis gap — the standard
/// windowing shape: all pages while they fit, otherwise the first page,
/// a window around the current page, and the last page (1 … 4 5 6 … 20),
/// always exactly [maxVisible] slots.
List<int?> _window(int page, int pageCount, int maxVisible) {
  if (pageCount <= maxVisible) {
    return [for (var p = 1; p <= pageCount; p++) p];
  }
  // Near the start the leading run absorbs the window: 1 2 3 4 5 … 20.
  if (page <= maxVisible - 3) {
    return [for (var p = 1; p <= maxVisible - 2; p++) p, null, pageCount];
  }
  // Near the end the trailing run does: 1 … 16 17 18 19 20.
  if (page >= pageCount - (maxVisible - 4)) {
    return [
      1,
      null,
      for (var p = pageCount - (maxVisible - 3); p <= pageCount; p++) p,
    ];
  }
  // The middle: both gaps, the window centered on the current page.
  final start = page - (maxVisible - 5) ~/ 2;
  return [
    1,
    null,
    for (var p = start; p < start + maxVisible - 4; p++) p,
    null,
    pageCount,
  ];
}

InteractiveColors _fill(LegendTokens t) => InteractiveColors(
  hovered: t.colors.background2,
  pressed: t.colors.background2,
  focused: t.colors.background2,
);

InteractiveColors _selectedFill(LegendTokens t) =>
    InteractiveColors(normal: t.colors.primary);

TextStyle _itemStyle(LegendTokens t) =>
    t.typography.b3.copyWith(color: t.colors.foreground2);

TextStyle _selectedStyle(LegendTokens t) => t.typography.b3.copyWith(
  color: t.colors.onPrimary,
  fontWeight: FontWeight.w600,
);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

EdgeInsetsGeometry _itemPadding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.sm, vertical: t.sizes.xs);
