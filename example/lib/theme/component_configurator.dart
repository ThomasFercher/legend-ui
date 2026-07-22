import 'package:example/docs/doc_page.dart';
import 'package:example/docs/manifest_registry.dart';
import 'package:example/theme/entry_editor.dart';
import 'package:example/theme/theme_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

/// The manifest-driven component configurator (RFC-002 R9): for the picked
/// component it renders EVERY entry of its generated docs manifest —
/// dot-path name, extracted doc, default expression, current override and
/// a type-appropriate editor — and writes sparse overrides through
/// [ThemeController.setMember] into the level-3 components map.
///
/// There is no per-variable code here: a new `@Style` field appears on
/// manifest regeneration with zero playground changes.
class ComponentConfigurator extends StatelessWidget {
  const ComponentConfigurator({
    required this.controller,
    required this.selected,
    super.key,
  });

  final ThemeController controller;

  /// The picked component (a [playgroundComponents] entry).
  final PlaygroundComponent selected;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    final mono = tokens.typography.b3.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Courier'],
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final overrides = controller.memberOverrides[selected.type] ?? const {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.sizes.md,
          children: [
            // The live instance the edits restyle, on the page background
            // so surfaces read as they would in an app.
            LegendSurface(
              color: tokens.colors.background1,
              borderRadius: tokens.sizes.borderRadiusMd,
              padding: EdgeInsets.all(tokens.sizes.md),
              child: SizedBox(
                width: double.infinity,
                child: Builder(builder: selected.preview),
              ),
            ),
            if (selected.note != null)
              LegendText(
                selected.note!,
                variant: LegendTextVariant.b3,
                color: tokens.colors.foreground2,
              ),
            const LegendDivider(),
            for (final entry in selected.entries)
              if (isStyleGroupBase(selected.entries, entry))
                _GroupHeader(entry: entry, mono: mono)
              else
                _EntryBlock(
                  entry: entry,
                  mono: mono,
                  // Members repeat their group's doc — show it once, on
                  // the header.
                  showDoc: !entry.name.contains('.'),
                  value: controller.memberValue(selected.type, entry.name),
                  onChanged: (value) =>
                      controller.setMember(selected.type, entry.name, value),
                ),
            if (overrides.isNotEmpty) ...[
              LegendTextButton(
                text: 'Clear ${selected.name} overrides',
                onPressed: () => controller.clearMembers(selected.type),
              ),
              const LegendText(
                'What the override emits',
                variant: LegendTextVariant.h3,
              ),
              const LegendText(
                'The edits above register this sparse entry in your '
                'LegendThemeData.components map (level 3):',
                variant: LegendTextVariant.b3,
              ),
              CodeBlock(
                'LegendThemeData(\n'
                '  tokens: tokens,\n'
                '  components: {\n'
                '    ${selected.name}: ${overrideSource(selected, overrides).replaceAll('\n', '\n    ')},\n'
                '  },\n'
                ')',
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A dot-path group's header row: name, style-class type, and the shared
/// doc its member editors indent under.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.entry, required this.mono});

  final LegendDocEntry entry;
  final TextStyle mono;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.xs,
      children: [
        LegendText.rich(
          TextSpan(
            children: [
              TextSpan(
                text: entry.name,
                style: mono.copyWith(color: tokens.colors.foreground1),
              ),
              TextSpan(
                text: '  ${entry.type}',
                style: mono.copyWith(color: tokens.colors.foreground3),
              ),
            ],
          ),
        ),
        LegendText(
          entry.doc.replaceAll('\n', ' '),
          variant: LegendTextVariant.b3,
          color: tokens.colors.foreground2,
        ),
      ],
    );
  }
}

/// One editable manifest entry: doc text, default expression, and the
/// type-dispatched [EntryEditor].
class _EntryBlock extends StatelessWidget {
  const _EntryBlock({
    required this.entry,
    required this.mono,
    required this.showDoc,
    required this.value,
    required this.onChanged,
  });

  final LegendDocEntry entry;
  final TextStyle mono;
  final bool showDoc;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return Padding(
      padding: EdgeInsets.only(
        left: entry.name.contains('.') ? tokens.sizes.md : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.sizes.xs,
        children: [
          if (showDoc) ...[
            LegendText(
              entry.doc.replaceAll('\n', ' '),
              variant: LegendTextVariant.b3,
              color: tokens.colors.foreground2,
            ),
            Text(
              'default: ${entry.defaultDescription}',
              style: mono.copyWith(color: tokens.colors.foreground3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          EntryEditor(entry: entry, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
