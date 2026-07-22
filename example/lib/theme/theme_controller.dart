import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

/// Base theme presets offered by the playground.
enum ThemePreset { light, dark, emerald, violet }

/// Corner-radius scale applied on top of the preset.
enum RadiusChoice { sharp, standard, round }

/// Spacing-scale density applied on top of the preset.
enum DensityChoice { compact, standard, comfortable }

/// The playground's theme state — a plain consumer-side controller that
/// builds a [LegendThemeData] exactly the way any real app would: start
/// from token presets, `copyWith` adjustments, and register sparse
/// component overrides in the open `components` map.
class ThemeController extends ChangeNotifier {
  ThemePreset preset = ThemePreset.light;
  Color? primary;
  Color? secondary;
  RadiusChoice radius = RadiusChoice.standard;
  DensityChoice density = DensityChoice.standard;

  /// Level-3 override for [PrimaryLegendButton], edited in the playground.
  Color? buttonBackground;

  /// Level-3 override for the shared [LegendButtonCore] surface.
  double? buttonRadius;

  /// Level-3 override for [LegendBody]'s centered reading-column width.
  double? bodyMaxContentWidth;

  /// Level-3 override for [LegendVerticalMenu]'s selected-item color.
  Color? menuSelectedColor;

  /// Level-3 override for [LegendPopover]'s panel corner radius.
  double? popoverRadius;

  /// Level-3 override for [LegendChip]'s selected fill.
  Color? chipSelectedBackground;

  /// Level-3 override for [LegendTabs]' active-indicator color.
  Color? tabsIndicator;

  /// Level-3 override for [LegendBanner]'s info-severity strip fill.
  Color? bannerBackground;

  /// Level-3 override for [LegendTooltip]'s hover show delay.
  Duration? tooltipShowDelay;

  /// Level-3 override for [LegendListItem]'s selected-row fill.
  Color? listSelectedBackground;

  /// Level-3 override for [LegendBadge]'s fill.
  Color? badgeBackground;

  /// Level-3 override for [LegendProgress]'s completed-fill color.
  Color? progressFill;

  /// Level-3 override for [LegendCheckbox]'s checked box fill.
  Color? checkboxFill;

  /// Level-3 override for [LegendRadio]'s selected circle fill.
  Color? radioFill;

  /// Level-3 override for [LegendAvatar]'s corner radius.
  double? avatarRadius;

  /// Level-3 override for [LegendMarkdown]'s link color.
  Color? markdownLinkColor;

  /// Level-3 override for [LegendSegmented]'s selected-segment thumb color.
  Color? segmentedThumb;

  /// Level-3 override for [LegendEmpty]'s inherited icon color.
  Color? emptyIconColor;

  /// Level-3 override for [LegendDrawer]'s side-drawer width.
  double? drawerWidth;

  /// Level-3 override for [LegendCombobox]'s option-highlight color.
  Color? comboboxHighlight;

  bool get dark => preset == ThemePreset.dark;

  void setPreset(ThemePreset value) {
    preset = value;
    // A preset is a fresh starting point — custom brand colors reset.
    primary = null;
    secondary = null;
    notifyListeners();
  }

  void setDark({required bool value}) =>
      setPreset(value ? ThemePreset.dark : ThemePreset.light);

  void setPrimary(Color? value) {
    primary = value;
    notifyListeners();
  }

  void setSecondary(Color? value) {
    secondary = value;
    notifyListeners();
  }

  void setRadius(RadiusChoice value) {
    radius = value;
    notifyListeners();
  }

  void setDensity(DensityChoice value) {
    density = value;
    notifyListeners();
  }

  void setButtonBackground(Color? value) {
    buttonBackground = value;
    notifyListeners();
  }

  void setButtonRadius(double? value) {
    buttonRadius = value;
    notifyListeners();
  }

  void setBodyMaxContentWidth(double? value) {
    bodyMaxContentWidth = value;
    notifyListeners();
  }

  void setMenuSelectedColor(Color? value) {
    menuSelectedColor = value;
    notifyListeners();
  }

  void setPopoverRadius(double? value) {
    popoverRadius = value;
    notifyListeners();
  }

  void setChipSelectedBackground(Color? value) {
    chipSelectedBackground = value;
    notifyListeners();
  }

  void setTabsIndicator(Color? value) {
    tabsIndicator = value;
    notifyListeners();
  }

  void setBannerBackground(Color? value) {
    bannerBackground = value;
    notifyListeners();
  }

  void setTooltipShowDelay(Duration? value) {
    tooltipShowDelay = value;
    notifyListeners();
  }

  void setListSelectedBackground(Color? value) {
    listSelectedBackground = value;
    notifyListeners();
  }

  void setBadgeBackground(Color? value) {
    badgeBackground = value;
    notifyListeners();
  }

  void setProgressFill(Color? value) {
    progressFill = value;
    notifyListeners();
  }

  void setCheckboxFill(Color? value) {
    checkboxFill = value;
    notifyListeners();
  }

  void setRadioFill(Color? value) {
    radioFill = value;
    notifyListeners();
  }

  void setAvatarRadius(double? value) {
    avatarRadius = value;
    notifyListeners();
  }

  void setMarkdownLinkColor(Color? value) {
    markdownLinkColor = value;
    notifyListeners();
  }

  void setSegmentedThumb(Color? value) {
    segmentedThumb = value;
    notifyListeners();
  }

  void setEmptyIconColor(Color? value) {
    emptyIconColor = value;
    notifyListeners();
  }

  void setDrawerWidth(double? value) {
    drawerWidth = value;
    notifyListeners();
  }

  void setComboboxHighlight(Color? value) {
    comboboxHighlight = value;
    notifyListeners();
  }

  void reset() {
    preset = ThemePreset.light;
    primary = null;
    secondary = null;
    radius = RadiusChoice.standard;
    density = DensityChoice.standard;
    buttonBackground = null;
    buttonRadius = null;
    bodyMaxContentWidth = null;
    menuSelectedColor = null;
    popoverRadius = null;
    chipSelectedBackground = null;
    tabsIndicator = null;
    bannerBackground = null;
    tooltipShowDelay = null;
    listSelectedBackground = null;
    badgeBackground = null;
    progressFill = null;
    checkboxFill = null;
    radioFill = null;
    avatarRadius = null;
    markdownLinkColor = null;
    segmentedThumb = null;
    emptyIconColor = null;
    drawerWidth = null;
    comboboxHighlight = null;
    notifyListeners();
  }

  LegendTokens get _base => switch (preset) {
    ThemePreset.light => LegendTokens.light,
    ThemePreset.dark => LegendTokens.dark,
    ThemePreset.emerald => LegendTokens.light.copyWith(
      colors: LegendTokens.light.colors.copyWith(
        primary: const Color(0xFF059669),
        primaryContainer: const Color(0xFFD1FAE5),
        secondary: const Color(0xFF0D9488),
      ),
    ),
    ThemePreset.violet => LegendTokens.dark.copyWith(
      colors: LegendTokens.dark.colors.copyWith(
        primary: const Color(0xFF8B5CF6),
        primaryContainer: const Color(0xFF3B0764),
        secondary: const Color(0xFFEC4899),
      ),
    ),
  };

  /// The [LegendThemeData] the whole app runs on. `AnimatedLegendTheme`
  /// inside `LegendApp` animates every change made here.
  LegendThemeData get data {
    var tokens = _base;

    if (primary != null || secondary != null) {
      tokens = tokens.copyWith(
        colors: tokens.colors.copyWith(primary: primary, secondary: secondary),
      );
    }

    final (radiusSm, radiusMd, radiusLg) = switch (radius) {
      RadiusChoice.sharp => (2.0, 4.0, 8.0),
      RadiusChoice.standard => (4.0, 8.0, 16.0),
      RadiusChoice.round => (8.0, 16.0, 28.0),
    };
    final scale = switch (density) {
      DensityChoice.compact => 0.8,
      DensityChoice.standard => 1.0,
      DensityChoice.comfortable => 1.25,
    };
    final s = tokens.sizes;
    tokens = tokens.copyWith(
      sizes: s.copyWith(
        radiusSm: radiusSm,
        radiusMd: radiusMd,
        radiusLg: radiusLg,
        xs: s.xs * scale,
        sm: s.sm * scale,
        md: s.md * scale,
        lg: s.lg * scale,
        xl: s.xl * scale,
        xxl: s.xxl * scale,
      ),
    );

    return LegendThemeData(
      tokens: tokens,
      components: {
        // The open Type-keyed registry (level 3): sparse overrides only —
        // unset properties keep resolving through the lower levels.
        if (buttonBackground != null)
          // Keyed by the widget type — the natural key form (RFC-002 R3).
          PrimaryLegendButton: PrimaryLegendButtonThemeNullable(
            background: buttonBackground == null
                ? null
                : InteractiveColors(normal: buttonBackground),
          ),
        // The shared button surface (RFC-002 R7.2): one core-level entry
        // restyles the radius of every variant that doesn't opt out.
        if (buttonRadius != null)
          LegendButtonCore: LegendButtonCoreThemeNullable(
            borderRadius: BorderRadius.circular(buttonRadius!),
          ),
        // LegendBody's centered reading-column width (RFC-003).
        if (bodyMaxContentWidth != null)
          LegendBody: LegendBodyThemeNullable(
            maxContentWidth: bodyMaxContentWidth,
          ),
        // LegendVerticalMenu's selected-item color.
        if (menuSelectedColor != null)
          LegendVerticalMenu: LegendVerticalMenuThemeNullable(
            selectedColor: menuSelectedColor,
          ),
        // LegendPopover's floating-panel corner radius.
        if (popoverRadius != null)
          LegendPopover: LegendPopoverThemeNullable(
            borderRadius: BorderRadius.circular(popoverRadius!),
          ),
        // LegendChip's selected fill — a sparse InteractiveColors: only
        // `normal` is set, the other states keep resolving downward.
        if (chipSelectedBackground != null)
          LegendChip: LegendChipThemeNullable(
            selectedBackground: InteractiveColors(
              normal: chipSelectedBackground,
            ),
          ),
        // LegendTabs' active-indicator color.
        if (tabsIndicator != null)
          LegendTabs: LegendTabsThemeNullable(indicator: tabsIndicator),
        // LegendBanner's info-severity strip fill.
        if (bannerBackground != null)
          LegendBanner: LegendBannerThemeNullable(
            infoBackground: bannerBackground,
          ),
        // LegendTooltip's hover show delay.
        if (tooltipShowDelay != null)
          LegendTooltip: LegendTooltipThemeNullable(
            showDelay: tooltipShowDelay,
          ),
        // LegendListItem's selected-row fill.
        if (listSelectedBackground != null)
          LegendListItem: LegendListItemThemeNullable(
            selectedBackground: listSelectedBackground,
          ),
        // LegendBadge's fill.
        if (badgeBackground != null)
          LegendBadge: LegendBadgeThemeNullable(background: badgeBackground),
        // LegendProgress's completed-fill color.
        if (progressFill != null)
          LegendProgress: LegendProgressThemeNullable(fill: progressFill),
        // LegendCheckbox's checked box fill — a sparse InteractiveColors:
        // hover/press/disabled keep deriving from the lower levels.
        if (checkboxFill != null)
          LegendCheckbox: LegendCheckboxThemeNullable(
            box: InteractiveColors(normal: checkboxFill),
          ),
        // LegendRadio's selected circle fill — a sparse InteractiveColors:
        // hover/press/disabled keep deriving from the lower levels.
        if (radioFill != null)
          LegendRadio: LegendRadioThemeNullable(
            fill: InteractiveColors(normal: radioFill),
          ),
        // LegendAvatar's shape — circle by default, squircle/square here.
        if (avatarRadius != null)
          LegendAvatar: LegendAvatarThemeNullable(
            borderRadius: BorderRadius.circular(avatarRadius!),
          ),
        // LegendMarkdown's link color (text and underline together).
        if (markdownLinkColor != null)
          LegendMarkdown: LegendMarkdownThemeNullable(
            linkColor: markdownLinkColor,
          ),
        // LegendSegmented's selected-segment thumb (the sparse per-state
        // bundle: unset states keep deriving through the overlays).
        if (segmentedThumb != null)
          LegendSegmented: LegendSegmentedThemeNullable(
            thumb: InteractiveColors(normal: segmentedThumb),
          ),
        // LegendEmpty's zero-state glyph color (inherited via IconTheme).
        if (emptyIconColor != null)
          LegendEmpty: LegendEmptyThemeNullable(iconColor: emptyIconColor),
        // LegendDrawer's side-drawer width.
        if (drawerWidth != null)
          LegendDrawer: LegendDrawerThemeNullable(width: drawerWidth),
        // LegendCombobox's option highlight — a sparse InteractiveColors:
        // only `hovered` is set (the pointer/keyboard highlight), the
        // panel fill keeps resolving downward.
        if (comboboxHighlight != null)
          LegendCombobox: LegendComboboxThemeNullable(
            menuBackground: InteractiveColors(hovered: comboboxHighlight),
          ),
      },
    );
  }
}
