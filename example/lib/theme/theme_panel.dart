import 'package:example/theme/color_field.dart';
import 'package:example/theme/theme_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

/// The live theme configurator. Everything it does goes through the public
/// theming API — token `copyWith` plus the open `components` registry — so
/// it doubles as executable documentation of the consumer workflow.
class ThemePanel extends StatelessWidget {
  const ThemePanel({required this.controller, super.key});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.sizes.md,
        children: [
          const LegendText('Theme', variant: LegendTextVariant.h3),

          const LegendText('Preset', variant: LegendTextVariant.b3),
          Wrap(
            spacing: tokens.sizes.xs,
            runSpacing: tokens.sizes.xs,
            children: [
              for (final preset in ThemePreset.values)
                _Chip(
                  label: switch (preset) {
                    ThemePreset.light => 'Light',
                    ThemePreset.dark => 'Dark',
                    ThemePreset.emerald => 'Emerald',
                    ThemePreset.violet => 'Violet',
                  },
                  selected: controller.preset == preset,
                  onTap: () => controller.setPreset(preset),
                ),
            ],
          ),

          ColorField(
            label: 'Primary color',
            value: controller.primary,
            onChanged: controller.setPrimary,
          ),
          ColorField(
            label: 'Secondary color',
            value: controller.secondary,
            onChanged: controller.setSecondary,
          ),

          const LegendText('Corner radius', variant: LegendTextVariant.b3),
          LegendDropdown<RadiusChoice>(
            value: controller.radius,
            items: const [
              LegendDropdownItem(value: RadiusChoice.sharp, label: 'Sharp'),
              LegendDropdownItem(
                value: RadiusChoice.standard,
                label: 'Standard',
              ),
              LegendDropdownItem(value: RadiusChoice.round, label: 'Round'),
            ],
            onChanged: controller.setRadius,
          ),

          const LegendText('Density', variant: LegendTextVariant.b3),
          LegendDropdown<DensityChoice>(
            value: controller.density,
            items: const [
              LegendDropdownItem(
                value: DensityChoice.compact,
                label: 'Compact',
              ),
              LegendDropdownItem(
                value: DensityChoice.standard,
                label: 'Standard',
              ),
              LegendDropdownItem(
                value: DensityChoice.comfortable,
                label: 'Comfortable',
              ),
            ],
            onChanged: controller.setDensity,
          ),

          const LegendDivider(),
          const LegendText('Component override', variant: LegendTextVariant.h3),
          const LegendText(
            'Registers sparse overrides in the components map (level 3): '
            'a PrimaryLegendButtonThemeNullable for the background and a '
            'LegendButtonCoreThemeNullable for the shared button surface '
            '(RFC-002 R7.2) — exactly how an app reskins components '
            'without touching the others.',
            variant: LegendTextVariant.b3,
          ),
          ColorField(
            label: 'Primary button background',
            value: controller.buttonBackground,
            onChanged: controller.setButtonBackground,
          ),
          const LegendText(
            'Button radius (shared LegendButtonCore surface)',
            variant: LegendTextVariant.b3,
          ),
          LegendDropdown<double>(
            value: controller.buttonRadius,
            placeholder: 'Theme default',
            items: const [
              LegendDropdownItem(value: 0, label: 'Square (0)'),
              LegendDropdownItem(value: 8, label: 'Rounded (8)'),
              LegendDropdownItem(value: 24, label: 'Pill (24)'),
            ],
            onChanged: controller.setButtonRadius,
          ),

          const LegendText(
            'Body reading-column width (LegendBody.maxContentWidth)',
            variant: LegendTextVariant.b3,
          ),
          LegendDropdown<double>(
            value: controller.bodyMaxContentWidth,
            placeholder: 'Unconstrained',
            items: const [
              LegendDropdownItem(value: 480, label: 'Narrow (480)'),
              LegendDropdownItem(value: 720, label: 'Reading (720)'),
              LegendDropdownItem(value: 1040, label: 'Wide (1040)'),
            ],
            onChanged: controller.setBodyMaxContentWidth,
          ),

          ColorField(
            label: 'Vertical-menu selected color',
            value: controller.menuSelectedColor,
            onChanged: controller.setMenuSelectedColor,
          ),

          ColorField(
            label: 'Tabs indicator color',
            value: controller.tabsIndicator,
            onChanged: controller.setTabsIndicator,
          ),
          ColorField(
            label: 'Banner info background (LegendBanner.infoBackground)',
            value: controller.bannerBackground,
            onChanged: controller.setBannerBackground,
          ),

          ColorField(
            label: 'Checkbox fill (LegendCheckbox.box)',
            value: controller.checkboxFill,
            onChanged: controller.setCheckboxFill,
          ),
          ColorField(
            label: 'Radio fill (LegendRadio.fill)',
            value: controller.radioFill,
            onChanged: controller.setRadioFill,
          ),

          const LegendText(
            'Popover panel radius (LegendPopover.borderRadius)',
            variant: LegendTextVariant.b3,
          ),
          LegendDropdown<double>(
            value: controller.popoverRadius,
            placeholder: 'Theme default',
            items: const [
              LegendDropdownItem(value: 0, label: 'Square (0)'),
              LegendDropdownItem(value: 12, label: 'Rounded (12)'),
              LegendDropdownItem(value: 24, label: 'Soft (24)'),
            ],
            onChanged: controller.setPopoverRadius,
          ),

          const LegendText(
            'Tooltip show delay (LegendTooltip.showDelay)',
            variant: LegendTextVariant.b3,
          ),
          LegendDropdown<Duration>(
            value: controller.tooltipShowDelay,
            // Distinct from the radius knobs' placeholder — gallery tests
            // (and users) tell the dropdowns apart by text.
            placeholder: 'Theme default (500 ms)',
            items: const [
              LegendDropdownItem(value: Duration.zero, label: 'Instant (0 ms)'),
              LegendDropdownItem(
                value: Duration(milliseconds: 500),
                label: 'Standard (500 ms)',
              ),
              LegendDropdownItem(
                value: Duration(milliseconds: 1200),
                label: 'Patient (1200 ms)',
              ),
            ],
            onChanged: controller.setTooltipShowDelay,
          ),

          ColorField(
            label: 'Chip selected fill',
            value: controller.chipSelectedBackground,
            onChanged: controller.setChipSelectedBackground,
          ),
          ColorField(
            label: 'List-item selected background',
            value: controller.listSelectedBackground,
            onChanged: controller.setListSelectedBackground,
          ),
          ColorField(
            label: 'Badge background',
            value: controller.badgeBackground,
            onChanged: controller.setBadgeBackground,
          ),
          ColorField(
            label: 'Progress fill color',
            value: controller.progressFill,
            onChanged: controller.setProgressFill,
          ),

          const LegendText(
            'Avatar shape (LegendAvatar.borderRadius)',
            variant: LegendTextVariant.b3,
          ),
          LegendDropdown<double>(
            value: controller.avatarRadius,
            placeholder: 'Circle (default)',
            items: const [
              LegendDropdownItem(value: 8, label: 'Squircle (8)'),
              LegendDropdownItem(value: 0, label: 'Square (0)'),
            ],
            onChanged: controller.setAvatarRadius,
          ),

          ColorField(
            label: 'Segmented thumb color',
            value: controller.segmentedThumb,
            onChanged: controller.setSegmentedThumb,
          ),
          ColorField(
            label: 'Menu destructive color (LegendMenu.destructiveColor)',
            value: controller.menuDestructiveColor,
            onChanged: controller.setMenuDestructiveColor,
          ),

          ColorField(
            label: 'Accordion section background (LegendAccordion.background)',
            value: controller.accordionBackground,
            onChanged: controller.setAccordionBackground,
          ),

          ColorField(
            label: 'Combobox option highlight (LegendCombobox.menuBackground)',
            value: controller.comboboxHighlight,
            onChanged: controller.setComboboxHighlight,
          ),
          ColorField(
            label:
                'Number-field stepper color '
                '(LegendNumberField.stepperForeground)',
            value: controller.numberStepperColor,
            onChanged: controller.setNumberStepperColor,
          ),
          ColorField(
            label:
                'PIN-field active-cell border '
                '(LegendPinField.focusedBorderColor)',
            value: controller.pinActiveBorder,
            onChanged: controller.setPinActiveBorder,
          ),

          ColorField(
            label: 'Stat positive-delta color (LegendStat.positiveColor)',
            value: controller.statPositiveColor,
            onChanged: controller.setStatPositiveColor,
          ),

          ColorField(
            label: 'Slider active-track color',
            value: controller.sliderActiveTrack,
            onChanged: controller.setSliderActiveTrack,
          ),

          ColorField(
            label: 'Empty-state icon color (LegendEmpty.iconColor)',
            value: controller.emptyIconColor,
            onChanged: controller.setEmptyIconColor,
          ),

          const LegendText(
            'Side-drawer width (LegendDrawer.width)',
            variant: LegendTextVariant.b3,
          ),
          LegendDropdown<double>(
            value: controller.drawerWidth,
            placeholder: 'Standard (320)',
            items: const [
              LegendDropdownItem(value: 280, label: 'Narrow (280)'),
              LegendDropdownItem(value: 360, label: 'Wide (360)'),
              LegendDropdownItem(value: 440, label: 'Extra wide (440)'),
            ],
            onChanged: controller.setDrawerWidth,
          ),

          ColorField(
            label: 'Markdown link color (LegendMarkdown.linkColor)',
            value: controller.markdownLinkColor,
            onChanged: controller.setMarkdownLinkColor,
          ),

          const LegendDivider(),
          SecondaryLegendButton(
            text: 'Reset everything',
            onPressed: controller.reset,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return LegendInteractive(
      semanticLabel: label,
      toggled: selected,
      onTap: onTap,
      builder: (context, states) => LegendSurface(
        color: selected
            ? tokens.colors.primary
            : states.hovered
            ? tokens.colors.background2
            : tokens.colors.background1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? tokens.colors.primary : tokens.colors.background3,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.sizes.sm,
          vertical: tokens.sizes.xs,
        ),
        duration: const Duration(milliseconds: 120),
        child: Text(
          label,
          style: tokens.typography.b3.copyWith(
            color: selected
                ? tokens.colors.onPrimary
                : tokens.colors.foreground1,
          ),
        ),
      ),
    );
  }
}
