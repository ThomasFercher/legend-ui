import 'package:example/sections/buttons_section.dart';
import 'package:example/sections/inputs_section.dart';
import 'package:example/sections/overlays_section.dart';
import 'package:example/sections/selection_section.dart';
import 'package:example/sections/typography_section.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

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
    (NomoNavItem(label: 'Buttons', icon: Icons.smart_button), ButtonsSection()),
    (NomoNavItem(label: 'Inputs', icon: Icons.edit), InputsSection()),
    (
      NomoNavItem(label: 'Selection', icon: Icons.check_circle_outline),
      SelectionSection(),
    ),
    (NomoNavItem(label: 'Overlays', icon: Icons.layers), OverlaysSection()),
    (
      NomoNavItem(label: 'Typography', icon: Icons.text_fields),
      TypographySection(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = [for (final (item, _) in _sections) item];
    return NomoApp(
      title: 'Nomo UI Kit Gallery',
      theme: NomoThemeData(tokens: _dark ? NomoTokens.dark : NomoTokens.light),
      home: Builder(
        builder: (context) => NomoScaffold(
          appBar: NomoAppBar(
            title: 'Nomo UI Kit — ${items[_section].label}',
            actions: [
              const NomoText('Dark', variant: NomoTextVariant.b3),
              NomoSwitch(
                value: _dark,
                onChanged: (v) => setState(() => _dark = v),
              ),
            ],
          ),
          sider: NomoSider(
            items: items,
            selectedIndex: _section,
            onSelected: (i) => setState(() => _section = i),
          ),
          bottomBar: NomoBottomBar(
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
    final tokens = NomoTheme.of(context).tokens;
    return NomoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.sizes.md,
        children: [
          NomoText(title, variant: NomoTextVariant.h3),
          ...children,
        ],
      ),
    );
  }
}
