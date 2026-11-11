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
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/version.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/skyfy_text.dart';
import 'package:musify/utilities/url_launcher.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/qris_dialog.dart';
import 'package:musify/widgets/skyfy_backdrop.dart';
import 'package:musify/widgets/skyfy_widgets.dart';
import 'package:musify/widgets/whatsapp_channel.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(tt('Tentang Skyfy', 'About Skyfy'))),
      body: SingleChildScrollView(
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SkyfyBackdrop(height: 280),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
              children: <Widget>[
                const SkyfyLogo(size: 92),
                const SizedBox(height: 12),
                Text(
                  'Skyfy',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Music for your moment',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'v$appVersion  •  Free',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  tt(
                    'Aplikasi pemutar musik modern dengan tampilan elegan, ringan, dan semua fitur gratis.',
                    'A modern music player with an elegant, lightweight look and every feature for free.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.person_24_regular,
                          size: 24,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Developer',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Wildan Tirta Permana',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _ContactRow(
                  logoAsset: 'assets/images/logo_tiktok.png',
                  label: 'TikTok',
                  value: '@nexsyncc',
                  onTap: () =>
                      launchURL(Uri.parse('https://www.tiktok.com/@nexsyncc')),
                ),
                _ContactRow(
                  logoAsset: 'assets/images/logo_instagram.png',
                  label: 'Instagram',
                  value: '@nexsyncc',
                  onTap: () =>
                      launchURL(Uri.parse('https://www.instagram.com/nexsyncc')),
                ),
                const _ContactRow(
                  icon: FluentIcons.mail_24_regular,
                  label: 'Email',
                  value: 'wilgtwilgt@gmail.com',
                ),
                const SizedBox(height: 14),
                const _WhatsappChannelCard(),
                const SizedBox(height: 10),
                SkyfyMenuTile(
                  icon: FluentIcons.code_24_filled,
                  title: 'GitHub',
                  subtitle: 'github.com/ZenoScripter',
                  onTap: () => launchURL(
                    Uri.parse('https://github.com/ZenoScripter'),
                  ),
                ),
                SkyfyMenuTile(
                  icon: FluentIcons.heart_24_filled,
                  title: tt('Dukung Skyfy', 'Support Skyfy'),
                  subtitle: 'QRIS',
                  onTap: () => showQrisDialog(context),
                ),
                SkyfyMenuTile(
                  icon: FluentIcons.document_24_regular,
                  title: tt('Lisensi', 'Licenses'),
                  subtitle: tt('Lisensi open source', 'Open source licenses'),
                  onTap: () => context.push('/settings/license'),
                ),
                const MiniPlayerBottomSpace(),
              ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    this.icon,
    this.logoAsset,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData? icon;
  final String? logoAsset;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                if (logoAsset != null)
                  Image.asset(
                    logoAsset!,
                    width: 30,
                    height: 30,
                  )
                else
                  Icon(icon, size: 24, color: colorScheme.onSurface),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: tt('Salin', 'Copy'),
                  icon: Icon(
                    FluentIcons.copy_24_regular,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (!context.mounted) return;
                    showToast(context, tt('Disalin', 'Copied'));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhatsappChannelCard extends StatelessWidget {
  const _WhatsappChannelCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => confirmOpenWhatsappChannel(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  FluentIcons.megaphone_24_filled,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tt('Channel WhatsApp Skyfy', 'Skyfy WhatsApp Channel'),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tt(
                        'Channel ini digunakan untuk membagikan informasi, pengumuman, dan update terbaru mengenai aplikasi Skyfy.',
                        'This channel is used to share news, announcements and the latest updates about the Skyfy app.',
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                FluentIcons.chevron_right_24_regular,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
