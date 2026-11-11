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

import 'dart:convert';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/services/profile_manager.dart';
import 'package:musify/widgets/skyfy_motion.dart';

/// The Skyfy app tile (S ribbon), the same artwork as the launcher icon.
class SkyfyLogo extends StatelessWidget {
  const SkyfyLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/ic_launcher.png',
      width: size,
      height: size,
    );
  }
}

/// Round profile picture: the photo picked by the user or a purple default.
class SkyfyAvatar extends StatelessWidget {
  const SkyfyAvatar({
    super.key,
    this.size = 96,
    this.showEditBadge = false,
    this.imageOverride,
    this.useOverride = false,
    this.onBadgeTap,
  });

  final double size;
  final bool showEditBadge;

  /// Used by the edit screen to preview a photo that is not saved yet.
  final String? imageOverride;
  final bool useOverride;
  final VoidCallback? onBadgeTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.55),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: useOverride
                    ? _buildImage(context, imageOverride)
                    : ValueListenableBuilder<String?>(
                        valueListenable: profileImage,
                        builder: (context, image, _) =>
                            _buildImage(context, image),
                      ),
              ),
            ),
          ),
          if (showEditBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: GestureDetector(
                onTap: onBadgeTap,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 1.4),
                  ),
                  child: Icon(
                    FluentIcons.edit_24_regular,
                    size: size * 0.16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, String? image) {
    final colorScheme = Theme.of(context).colorScheme;

    if (image != null && image.isNotEmpty) {
      try {
        final data = image.contains(',') ? image.split(',').last : image;
        return Image.memory(
          base64Decode(data),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _defaultAvatar(colorScheme),
        );
      } catch (_) {
        return _defaultAvatar(colorScheme);
      }
    }

    return _defaultAvatar(colorScheme);
  }

  Widget _defaultAvatar(ColorScheme colorScheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.85),
            const Color(0xFF3A2A7A),
          ],
        ),
      ),
      child: Icon(
        FluentIcons.person_24_filled,
        size: size * 0.5,
        color: Colors.white.withValues(alpha: 0.92),
      ),
    );
  }
}

/// Rounded dark list row used on the Profile / About / Settings screens.
class SkyfyMenuTile extends StatelessWidget {
  const SkyfyMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeSlideIn(
      child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(icon, size: 24, color: colorScheme.onSurface),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (onTap != null)
                  Icon(
                    FluentIcons.chevron_right_24_regular,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Small bold section label ("Playlist Kamu", "Genre", ...).
class SkyfySectionLabel extends StatelessWidget {
  const SkyfySectionLabel(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
