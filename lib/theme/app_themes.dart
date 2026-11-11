/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/services/profile_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/theme/app_colors.dart';

ThemeMode themeMode = getThemeMode(themeModeSetting);
Brightness brightness = getBrightnessFromThemeMode(themeMode);

Brightness getBrightnessFromThemeMode(ThemeMode themeMode) {
  final themeBrightnessMapping = {
    ThemeMode.light: Brightness.light,
    ThemeMode.dark: Brightness.dark,
    ThemeMode.system:
        SchedulerBinding.instance.platformDispatcher.platformBrightness,
  };

  return themeBrightnessMapping[themeMode] ?? Brightness.dark;
}

ThemeMode getThemeMode(int themeModeIndex) {
  const themeModes = ThemeMode.values;
  if (themeModeIndex >= 0 && themeModeIndex < themeModes.length) {
    return themeModes[themeModeIndex];
  }
  return ThemeMode.dark;
}

ColorScheme getAppColorScheme(
  ColorScheme? lightColorScheme,
  ColorScheme? darkColorScheme,
) {
  final selectedScheme = (brightness == Brightness.light)
      ? lightColorScheme
      : darkColorScheme;

  if (useSystemColor.value && selectedScheme != null) {
    return selectedScheme;
  }

  final seeded = ColorScheme.fromSeed(
    seedColor: primaryColorSetting,
    brightness: brightness,
  );

  if (brightness == Brightness.dark) {
    return _skyfyDarkScheme(seeded, primaryColorSetting);
  }
  return seeded;
}

/// Dark purple Skyfy palette tinted with the accent picked by the user.
ColorScheme _skyfyDarkScheme(ColorScheme base, Color accent) {
  final onAccent = accent.computeLuminance() > 0.5
      ? const Color(0xFF1A1033)
      : Colors.white;
  final softAccent = Color.lerp(accent, Colors.white, 0.35) ?? accent;
  final lightAccent = Color.lerp(accent, Colors.white, 0.6) ?? accent;

  return base.copyWith(
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: Color.alphaBlend(
      accent.withValues(alpha: 0.22),
      SkyfyColors.surfaceHigh,
    ),
    onPrimaryContainer: lightAccent,
    secondary: softAccent,
    onSecondary: const Color(0xFF1A1033),
    secondaryContainer: Color.alphaBlend(
      accent.withValues(alpha: 0.16),
      SkyfyColors.surfaceHigh,
    ),
    onSecondaryContainer: lightAccent,
    surface: SkyfyColors.background,
    onSurface: SkyfyColors.text,
    onSurfaceVariant: SkyfyColors.textMuted,
    surfaceContainerLowest: SkyfyColors.background,
    surfaceContainerLow: SkyfyColors.surfaceLow,
    surfaceContainer: SkyfyColors.surface,
    surfaceContainerHigh: SkyfyColors.surfaceHigh,
    surfaceContainerHighest: SkyfyColors.surfaceHighest,
    outline: SkyfyColors.outline,
    outlineVariant: SkyfyColors.outlineSoft,
  );
}

ThemeData getAppTheme(ColorScheme colorScheme) {
  final base = colorScheme.brightness == Brightness.light
      ? ThemeData.light()
      : ThemeData.dark();

  final isLight = colorScheme.brightness == Brightness.light;
  final isPureBlack =
      colorScheme.brightness == Brightness.dark && usePureBlackColor.value;

  // Pure black theme colors
  const pureBlack = Color(0xFF000000);
  const pureBlackElevated = Color(0xFF0A0A0A);
  const pureBlackContainer = Color(0xFF121212);
  const pureBlackContainerHigh = Color(0xFF1A1A1A);

  final fullBackgroundOn = fullBackground.value;

  final solidBgColor = isLight
      ? colorScheme.surface
      : (isPureBlack ? pureBlack : null);

  // With "Full Background" the app paints the picture behind every page, so
  // the pages themselves must be see-through.
  final bgColor = fullBackgroundOn ? Colors.transparent : solidBgColor;

  final cardBgColor = isLight
      ? colorScheme.surfaceContainerLow
      : (isPureBlack ? pureBlackElevated : null);

  // modified color scheme for pure black theme
  final effectiveColorScheme = isPureBlack
      ? colorScheme.copyWith(
          surface: pureBlack,
          surfaceContainerLowest: pureBlack,
          surfaceContainerLow: pureBlackElevated,
          surfaceContainer: pureBlackContainer,
          surfaceContainerHigh: pureBlackContainerHigh,
          surfaceContainerHighest: pureBlackContainerHigh,
        )
      : colorScheme;

  return ThemeData(
    fontFamily: 'Inter',
    scaffoldBackgroundColor: bgColor,
    colorScheme: effectiveColorScheme,
    cardColor: cardBgColor,
    cardTheme: base.cardTheme.copyWith(
      elevation: 0,
      color: cardBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: bgColor,
      foregroundColor: effectiveColorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        color: effectiveColorScheme.onSurface,
        letterSpacing: -0.3,
      ),
      toolbarHeight: 64,
      iconTheme: IconThemeData(
        color: effectiveColorScheme.onSurface,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: effectiveColorScheme.onSurface,
        size: 24,
      ),
    ),
    listTileTheme: base.listTileTheme.copyWith(
      textColor: effectiveColorScheme.onSurface,
      iconColor: effectiveColorScheme.primary,
    ),
    sliderTheme: base.sliderTheme.copyWith(
      year2023: false,
      trackHeight: 12,
      thumbSize: WidgetStateProperty.all(const Size(6, 30)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(64, 48),
        foregroundColor: effectiveColorScheme.primary,
        side: BorderSide(color: effectiveColorScheme.primary, width: 1.2),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: BorderSide(color: effectiveColorScheme.outlineVariant),
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: isLight
          ? colorScheme.surfaceContainerLow
          : (isPureBlack ? pureBlackElevated : null),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      isDense: true,
      fillColor: isLight
          ? colorScheme.surfaceContainerHighest
          : (isPureBlack
                ? pureBlackContainerHigh
                : colorScheme.surfaceContainer),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: effectiveColorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: effectiveColorScheme.primary.withValues(alpha: 0.8),
          width: 1.2,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(18, 14, 20, 14),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: isLight
          ? colorScheme.surfaceContainerLow
          : (isPureBlack ? pureBlackContainer : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: effectiveColorScheme.primary,
            size: 24,
          );
        }
        return IconThemeData(
          color: effectiveColorScheme.onSurfaceVariant,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontFamily: 'Inter',
            color: effectiveColorScheme.primary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(
          fontFamily: 'Inter',
          color: effectiveColorScheme.onSurfaceVariant,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        );
      }),
    ),
    navigationRailTheme: base.navigationRailTheme.copyWith(
      backgroundColor: bgColor,
      elevation: 0,
      indicatorColor: effectiveColorScheme.primaryContainer,
      selectedIconTheme: IconThemeData(
        color: effectiveColorScheme.primary,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: effectiveColorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        fontFamily: 'Inter',
        color: effectiveColorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontFamily: 'Inter',
        color: effectiveColorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: isLight
          ? colorScheme.surfaceContainerLow
          : (isPureBlack ? pureBlackContainer : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: base.dividerTheme.copyWith(
      color: effectiveColorScheme.outlineVariant,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: effectiveColorScheme.secondaryContainer,
      closeIconColor: effectiveColorScheme.onSecondaryContainer,
      contentTextStyle: TextStyle(
        fontFamily: 'Inter',
        color: effectiveColorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: effectiveColorScheme.outlineVariant,
          width: 0.2,
        ),
      ),
      elevation: 0,
      actionTextColor: effectiveColorScheme.secondary,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );
}
