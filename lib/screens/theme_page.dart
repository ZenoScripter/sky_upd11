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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/main.dart' show Musify;
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/profile_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/theme/app_colors.dart';
import 'package:musify/theme/app_themes.dart';
import 'package:musify/utilities/playlist_image_picker.dart';
import 'package:musify/utilities/skyfy_text.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/skyfy_backdrop.dart';
import 'package:musify/widgets/skyfy_widgets.dart';

/// "Tema": display mode, accent color and decorative background.
class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  static const int _accentChoices = 6;

  void _selectMode(ThemeMode mode) {
    addOrUpdateData<int>('settings', 'themeIndex', mode.index);
    Musify.updateAppState(context, newThemeMode: mode);
    setState(() {});
  }

  void _selectAccent(Color color) {
    addOrUpdateData<int>('settings', 'accentColor', color.toARGB32());
    Musify.updateAppState(
      context,
      newAccentColor: color,
      useSystemColor: false,
    );
    setState(() {});
  }

  Future<void> _pickCustomBackdrop() async {
    final picked = await pickImage();
    if (picked == null || !mounted) return;
    await setCustomBackdrop(picked);
    await setBackdropStyle(SkyfyBackdrop.customIndex);
  }

  Future<void> _selectOrPickCustom() async {
    if (customBackdrop.value == null) {
      await _pickCustomBackdrop();
    } else {
      await setBackdropStyle(SkyfyBackdrop.customIndex);
    }
  }

  Future<void> _removeCustomBackdrop() async {
    await setCustomBackdrop(null);
    if (backdropStyle.value == SkyfyBackdrop.customIndex) {
      await setBackdropStyle(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(tt('Tema', 'Theme'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkyfySectionLabel(tt('Mode Tampilan', 'Display Mode')),
            Row(
              children: [
                _ModeCard(
                  icon: FluentIcons.weather_sunny_24_regular,
                  label: tt('Terang', 'Light'),
                  selected: themeMode == ThemeMode.light,
                  onTap: () => _selectMode(ThemeMode.light),
                ),
                const SizedBox(width: 10),
                _ModeCard(
                  icon: FluentIcons.weather_moon_24_regular,
                  label: tt('Gelap', 'Dark'),
                  selected: themeMode == ThemeMode.dark,
                  onTap: () => _selectMode(ThemeMode.dark),
                ),
                const SizedBox(width: 10),
                _ModeCard(
                  icon: FluentIcons.phone_24_regular,
                  label: tt('Sistem', 'System'),
                  selected: themeMode == ThemeMode.system,
                  onTap: () => _selectMode(ThemeMode.system),
                ),
              ],
            ),
            SkyfySectionLabel(tt('Warna Aksen', 'Accent Color')),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: availableColors.take(_accentChoices).map((color) {
                final selected =
                    !useSystemColor.value &&
                    primaryColorSetting.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => _selectAccent(color),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? colorScheme.onSurface
                            : Colors.transparent,
                        width: 2.4,
                      ),
                    ),
                    child: selected
                        ? Icon(
                            FluentIcons.checkmark_20_filled,
                            size: 22,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            SkyfySectionLabel(tt('Latar Belakang', 'Background')),
            ValueListenableBuilder<bool>(
              valueListenable: fullBackground,
              builder: (context, full, _) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full Background',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tt(
                                'Latar belakang memenuhi seluruh halaman aplikasi.',
                                'The background fills every page of the app.',
                              ),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: full,
                        onChanged: (value) async {
                          await setFullBackground(value);
                          if (!mounted) return;
                          await Musify.updateAppState(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            ValueListenableBuilder<int>(
              valueListenable: backdropStyle,
              builder: (context, selectedIndex, _) {
                return SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: SkyfyBackdrop.stylesCount + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      if (i == SkyfyBackdrop.stylesCount) {
                        return _buildCustomTile(
                          context,
                          selectedIndex == SkyfyBackdrop.customIndex,
                        );
                      }
                      final selected = i == selectedIndex;
                      return GestureDetector(
                        onTap: () => setBackdropStyle(i),
                        child: Container(
                          width: 104,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SkyfyBackdrop(height: 150, styleIndex: i),
                                if (selected)
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        FluentIcons.checkmark_20_filled,
                                        size: 16,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              tt(
                'Pilih "Kustom" untuk memakai gambarmu sendiri. Tahan untuk menghapus.',
                'Pick "Custom" to use your own picture. Long-press to remove it.',
              ),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const MiniPlayerBottomSpace(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTile(BuildContext context, bool selected) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<String?>(
      valueListenable: customBackdrop,
      builder: (context, image, _) {
        final hasImage = image != null;
        return GestureDetector(
          onTap: _selectOrPickCustom,
          onLongPress: hasImage ? _removeCustomBackdrop : null,
          child: Container(
            width: 104,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    const SkyfyBackdrop(
                      height: 150,
                      styleIndex: SkyfyBackdrop.customIndex,
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.add_24_regular,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tt('Kustom', 'Custom'),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasImage)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: GestureDetector(
                        onTap: _pickCustomBackdrop,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            FluentIcons.edit_24_regular,
                            size: 15,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  if (selected && hasImage)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          FluentIcons.checkmark_20_filled,
                          size: 16,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.14)
                : colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
