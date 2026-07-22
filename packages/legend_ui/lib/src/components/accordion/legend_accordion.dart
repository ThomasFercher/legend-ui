import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/divider/legend_divider.dart';
import 'package:legend_ui/src/components/expandable/legend_expandable.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_accordion.theme.g.dart';

/// One section of a [LegendAccordion]: a header line (a plain [title] or a
/// fully custom [header] widget) over the [child] it reveals.
class LegendAccordionItem {
  const LegendAccordionItem({required this.child, this.title, this.header})
    : assert(
        title != null || header != null,
        'Provide a title or a custom header.',
      );

  /// Header text; with a custom [header] set it is only announced as the
  /// section's semantic label.
  final String? title;

  /// Custom header content, laid out before the caret.
  final Widget? header;

  /// The content revealed while the section is expanded.
  final Widget child;
}

/// A group of disclosure sections where expanding one collapses the others
/// — or any number stays open with [allowMultiple].
///
/// Composes one [LegendExpandable] per section (header activation, caret
/// rotation, expanded/collapsed semantics, animated size), a
/// [LegendDivider] between consecutive sections, and [LegendSurface] for
/// the rounded, clipped group container; the accordion itself only
/// coordinates which sections are open, pushing its themed fields onto the
/// sections through a subtree [LegendExpandableThemeOverride].
///
/// Works in two modes:
/// - **Uncontrolled** (default): the widget owns the open set, starting at
///   [initiallyExpanded]. [onChanged] still reports every change.
/// - **Controlled**: pass [expandedIndices]; the widget renders exactly
///   that set and header taps only call [onChanged] — the owner decides.
@LegendThemeable()
class LegendAccordion extends StatefulWidget {
  /// The [background] color lifts into the `normal` member of the
  /// per-state theme field (RFC-002 R6).
  LegendAccordion({
    required this.items,
    super.key,
    this.allowMultiple = false,
    this.initiallyExpanded = const {},
    this.expandedIndices,
    this.onChanged,
    this.headerPadding,
    this.headerStyle,
    Color? background,
    this.dividerColor,
    this.caretColor,
    this.duration,
    this.borderRadius,
  }) : background = background == null
           ? null
           : InteractiveColors(normal: background),
       assert(items.isNotEmpty, 'items must not be empty.'),
       assert(
         allowMultiple || initiallyExpanded.length <= 1,
         'Single-open mode: initiallyExpanded holds at most one index.',
       ),
       assert(
         allowMultiple ||
             expandedIndices == null ||
             expandedIndices.length <= 1,
         'Single-open mode: expandedIndices holds at most one index.',
       );

  /// The sections, top to bottom.
  final List<LegendAccordionItem> items;

  /// Whether several sections may be open at once; when false (the
  /// default), expanding a section collapses every other one.
  final bool allowMultiple;

  /// Indices of the sections open at first build in uncontrolled mode.
  final Set<int> initiallyExpanded;

  /// Controlled open set; null means uncontrolled.
  final Set<int>? expandedIndices;

  /// Called with the requested open set whenever a header is activated.
  final ValueChanged<Set<int>>? onChanged;

  /// Inner padding of every section's header row.
  @Style<EdgeInsetsGeometry>.resolve(_headerPadding)
  final EdgeInsetsGeometry? headerPadding;

  /// Style of every section's [LegendAccordionItem.title] text.
  @Style<TextStyle>.resolve(_headerStyle)
  final TextStyle? headerStyle;

  /// Fill of the sections, per interaction state — `normal` paints the
  /// whole group, `hovered`/`pressed`/`focused` tint the header under the
  /// pointer.
  @Style<InteractiveColors>.resolve(_background)
  final InteractiveColors? background;

  /// Color of the rules between consecutive sections.
  @Style<Color>.resolve(ColorRef.background3)
  final Color? dividerColor;

  /// Color of the rotating caret in every section header.
  @Style<Color>.resolve(ColorRef.foreground2)
  final Color? caretColor;

  /// How long each section's expand/collapse (and caret) animation takes.
  @Style<Duration>(Duration(milliseconds: 200))
  final Duration? duration;

  /// Corner rounding of the group's outer surface.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  @override
  State<LegendAccordion> createState() => _LegendAccordionState();
}

class _LegendAccordionState extends State<LegendAccordion> {
  late Set<int> _expanded = {...widget.initiallyExpanded};

  Set<int> get _open => widget.expandedIndices ?? _expanded;

  void _toggle(int index) {
    final open = _open;
    final Set<int> next;
    if (open.contains(index)) {
      next = {...open}..remove(index);
    } else if (widget.allowMultiple) {
      next = {...open, index};
    } else {
      next = {index};
    }
    if (widget.expandedIndices == null) setState(() => _expanded = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final open = _open;

    return LegendExpandableThemeOverride(
      // The group restyles its sections through the subtree level (level 2)
      // of the sections' own resolution — sections stay square inside the
      // clipped group surface, which owns the rounding.
      data: LegendExpandableThemeNullable(
        headerPadding: theme.headerPadding,
        titleStyle: theme.headerStyle,
        backgroundColor: theme.background,
        caretColor: theme.caretColor,
        borderRadius: BorderRadius.zero,
      ),
      child: LegendSurface(
        borderRadius: theme.borderRadius,
        clip: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, item) in widget.items.indexed) ...[
              if (index > 0)
                LegendDivider(color: theme.dividerColor, spacing: 0),
              LegendExpandable(
                title: item.title,
                header: item.header,
                expanded: open.contains(index),
                onToggle: (_) => _toggle(index),
                duration: theme.duration,
                child: item.child,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

EdgeInsetsGeometry _headerPadding(LegendTokens t) => EdgeInsets.all(t.sizes.md);

TextStyle _headerStyle(LegendTokens t) =>
    t.typography.b2.copyWith(color: t.colors.foreground1);

InteractiveColors _background(LegendTokens t) => InteractiveColors(
  normal: t.colors.surface,
  hovered: t.colors.background2,
  pressed: t.colors.background2,
  focused: t.colors.background2,
);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;
