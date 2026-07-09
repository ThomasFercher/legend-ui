import 'package:example/sections/buttons_section.dart';
import 'package:example/sections/inputs_section.dart';
import 'package:example/sections/overlays_section.dart';
import 'package:example/sections/selection_section.dart';
import 'package:example/sections/typography_section.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

void main() => runApp(const GalleryApp());

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  var _dark = false;
  var _section = 0;

  static const _sections = [
    (
      LegendNavItem(label: 'Buttons', icon: Icons.smart_button),
      ButtonsSection(),
    ),
    (LegendNavItem(label: 'Inputs', icon: Icons.edit), InputsSection()),
    (
      LegendNavItem(label: 'Selection', icon: Icons.check_circle_outline),
      SelectionSection(),
    ),
    (LegendNavItem(label: 'Overlays', icon: Icons.layers), OverlaysSection()),
    (
      LegendNavItem(label: 'Typography', icon: Icons.text_fields),
      TypographySection(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = [for (final (item, _) in _sections) item];
    return LegendApp(
      title: 'Legend UI Kit Gallery',
      theme: LegendThemeData(
        tokens: _dark ? LegendTokens.dark : LegendTokens.light,
      ),
      home: Builder(
        builder: (context) => LegendScaffold(
          appBar: LegendAppBar(
            title: 'Legend UI Kit — ${items[_section].label}',
            actions: [
              const LegendText('Dark', variant: LegendTextVariant.b3),
              LegendSwitch(
                value: _dark,
                onChanged: (v) => setState(() => _dark = v),
              ),
            ],
          ),
          sider: LegendSider(
            items: items,
            selectedIndex: _section,
            onSelected: (i) => setState(() => _section = i),
          ),
          bottomBar: LegendBottomBar(
            items: items,
            selectedIndex: _section,
            onSelected: (i) => setState(() => _section = i),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _sections[_section].$2,
          ),
        ),
      ),
    );
  }
}

/// Shared section scaffolding: a titled group of demos.
class DemoGroup extends StatelessWidget {
  const DemoGroup({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return LegendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.sizes.md,
        children: [
          LegendText(title, variant: LegendTextVariant.h3),
          ...children,
        ],
      ),
    );
  }
}
