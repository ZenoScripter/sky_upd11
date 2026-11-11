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
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/artwork_provider.dart';
import 'package:musify/utilities/async_loader.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/skyfy_text.dart';
import 'package:musify/widgets/announcement_box.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/recommended_songs_section.dart';
import 'package:musify/widgets/section_header.dart';
import 'package:musify/widgets/skyfy_backdrop.dart';
import 'package:musify/widgets/skyfy_motion.dart';
import 'package:musify/widgets/skyfy_widgets.dart';
import 'package:musify/widgets/whatsapp_channel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List> _suggestedPlaylistsFuture;
  late Future<List> _recommendedSongsFuture;

  @override
  void initState() {
    super.initState();
    _suggestedPlaylistsFuture = getPlaylists(
      playlistsNum: recommendedCubesNumber,
    );
    _recommendedSongsFuture = getRecommendedSongs();
    externalRecommendations.addListener(_refreshRecommendedSongs);
  }

  @override
  void dispose() {
    externalRecommendations.removeListener(_refreshRecommendedSongs);
    super.dispose();
  }

  void _refreshRecommendedSongs() {
    if (!mounted) return;
    setState(() {
      _recommendedSongsFuture = getRecommendedSongs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playlistHeight = MediaQuery.sizeOf(context).height * 0.25 / 1.1;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SkyfyBackdrop(height: 340),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topInset + 10, 20, 0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 22),
                Text(
                  skyfyGreeting(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                const FadeSlideIn(child: SkyfyClock()),
                const SizedBox(height: 12),
                const SizedBox(height: 6),
                ValueListenableBuilder<String?>(
                  valueListenable: announcementURL,
                  builder: (_, _url, __) {
                    if (_url == null) return const SizedBox.shrink();
                    final isSponsorshipAnnouncement =
                        isSponsorshipAnnouncementUrl(_url);
                    final _message = isSponsorshipAnnouncement
                        ? context.l10n!.sponsorProject
                        : context.l10n!.newAnnouncement;
                    final _icon = isSponsorshipAnnouncement
                        ? FluentIcons.heart_24_filled
                        : FluentIcons.megaphone_24_filled;

                    return AnnouncementBox(
                      message: _message,
                      url: _url,
                      icon: _icon,
                      onDismiss: () async {
                        announcementURL.value = null;
                      },
                    );
                  },
                ),
                FadeSlideIn(delayMs: 160, child: _buildHeroSection()),
                FadeSlideIn(delayMs: 240, child: _buildRecentlyPlayed()),
                _buildSuggestedPlaylists(playlistHeight),
                _buildSuggestedPlaylists(playlistHeight, showOnlyLiked: true),
                _buildRecommendedSongsSection(),
                const MiniPlayerBottomSpace(),
              ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        const SkyfyLogo(size: 38),
        const SizedBox(width: 10),
        Text(
          'Skyfy',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: tt('Pemberitahuan', 'Notifications'),
          onPressed: () => confirmOpenWhatsappChannel(context),
          icon: const Icon(FluentIcons.megaphone_24_regular),
        ),
        GestureDetector(
          onTap: () => context.go('/settings'),
          child: const SkyfyAvatar(size: 40),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return AsyncLoader<List<dynamic>>(
      future: _suggestedPlaylistsFuture,
      loadingWidget: const SizedBox(height: 8),
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      builder: (context, playlists) {
        if (playlists.isEmpty || playlists.first is! Map) {
          return const SizedBox.shrink();
        }
        final playlist = playlists.first as Map;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _HeroMixCard(
            playlist: playlist,
            onTap: () => context.push('/home/playlist/${playlist['ytid']}'),
          ),
        );
      },
    );
  }

  Widget _buildRecentlyPlayed() {
    return ValueListenableBuilder<List>(
      valueListenable: userRecentlyPlayed,
      builder: (context, recent, _) {
        final songs = recent.whereType<Map>().take(8).toList();
        if (songs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkyfySectionLabel(
              tt('Terakhir Diputar', 'Recently Played'),
              actionLabel: tt('Lihat semua', 'See all'),
              onAction: () => context.go('/library/userSongs/recents'),
            ),
            SizedBox(
              height: 158,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: songs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _RecentSongTile(
                  song: songs[index],
                  onTap: () => audioHandler.playPlaylistSong(
                    playlist: {
                      'title': tt('Terakhir Diputar', 'Recently Played'),
                      'list': songs,
                    },
                    songIndex: index,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuggestedPlaylists(
    double playlistHeight, {
    bool showOnlyLiked = false,
  }) {
    if (showOnlyLiked) {
      return ValueListenableBuilder<List<Map>>(
        valueListenable: userLikedPlaylists,
        builder: (_, likedPlaylists, __) => _buildSuggestedPlaylistsSection(
          playlistHeight,
          likedPlaylists
              .where((playlist) => !isArtistPlaylist(playlist))
              .take(recommendedCubesNumber)
              .toList(),
          showOnlyLiked: true,
        ),
      );
    }

    return AsyncLoader<List<dynamic>>(
      future: _suggestedPlaylistsFuture,
      loadingWidget: const SizedBox.shrink(),
      builder: (context, playlists) => _buildSuggestedPlaylistsSection(
        playlistHeight,
        playlists.length > 1 ? playlists.sublist(1) : playlists,
      ),
    );
  }

  Widget _buildSuggestedPlaylistsSection(
    double playlistHeight,
    List<dynamic> playlists, {
    bool showOnlyLiked = false,
  }) {
    if (playlists.isEmpty) return const SizedBox.shrink();

    final sectionTitle = showOnlyLiked
        ? context.l10n!.backToFavorites
        : context.l10n!.suggestedPlaylists;
    final itemsNumber = playlists.length.clamp(0, recommendedCubesNumber);

    return Column(
      children: [
        SectionHeader(
          title: sectionTitle,
          icon: showOnlyLiked
              ? FluentIcons.heart_24_filled
              : FluentIcons.list_24_filled,
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: playlistHeight + 50),
          child: _buildHorizontalList(playlists, itemsNumber, playlistHeight),
        ),
      ],
    );
  }

  Widget _buildHorizontalList(
    List<dynamic> playlists,
    int itemCount,
    double height,
  ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap: () => context.push('/home/playlist/${playlist['ytid']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlaylistCube(playlist, size: height),
                const SizedBox(height: 8),
                SizedBox(
                  width: height,
                  child: Text(
                    playlist['title']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendedSongsSection() {
    return AsyncLoader<List<dynamic>>(
      future: _recommendedSongsFuture,
      builder: (context, data) {
        if (data.isEmpty) return const SizedBox.shrink();
        return _buildRecommendedForYouSection(context, data);
      },
    );
  }

  Widget _buildRecommendedForYouSection(
    BuildContext context,
    List<dynamic> data,
  ) {
    return RecommendedSongsSection(
      title: context.l10n!.recommendedForYou,
      songs: data,
      listKeyPrefix: 'home_recommended',
    );
  }
}

/// Wide "mix" card at the top of Home: artwork, dark gradient and a play pill.
class _HeroMixCard extends StatelessWidget {
  const _HeroMixCard({required this.playlist, required this.onTap});

  final Map playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = playlist['image']?.toString();
    final title = playlist['title']?.toString() ?? '';

    Widget artwork() {
      final fallback = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.9),
              const Color(0xFF2A1B5E),
            ],
          ),
        ),
      );
      if (image == null || image.isEmpty) return fallback;
      try {
        return Image(
          image: ArtworkProvider.get(image),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 176,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              artwork(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 76,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tt('Pilihan playlist untukmu', 'A playlist picked for you'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FluentIcons.play_24_filled,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square cover + title/artist used in the "Recently Played" row.
class _RecentSongTile extends StatelessWidget {
  const _RecentSongTile({required this.song, required this.onTap});

  final Map song;
  final VoidCallback onTap;

  String? _imageUrl() {
    for (final key in ['lowResImage', 'image', 'highResImage']) {
      final value = song[key]?.toString();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = _imageUrl();
    final title = formatSongTitle(song['title']?.toString() ?? '');
    final artist = song['artist']?.toString() ?? '';

    Widget cover() {
      final fallback = ColoredBox(
        color: colorScheme.surfaceContainerHigh,
        child: Icon(
          FluentIcons.music_note_2_24_regular,
          color: colorScheme.primary,
          size: 34,
        ),
      );
      if (image == null) return fallback;
      try {
        return Image(
          image: ArtworkProvider.get(image),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(width: 104, height: 104, child: cover()),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
