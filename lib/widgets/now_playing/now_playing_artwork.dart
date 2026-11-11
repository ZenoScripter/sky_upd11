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

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart' show audioHandler;
import 'package:musify/models/position_data.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/lyrics/lyrics_models.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/async_loader.dart';
import 'package:musify/utilities/skyfy_text.dart';
import 'package:musify/widgets/flip_card.dart';
import 'package:musify/widgets/now_playing/synced_lyrics_view.dart';
import 'package:musify/widgets/song_artwork.dart';

class NowPlayingArtwork extends StatelessWidget {
  const NowPlayingArtwork({
    super.key,
    required this.size,
    required this.metadata,
    required this.lyricsController,
  });
  final Size size;
  final MediaItem metadata;
  final FlipCardController lyricsController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isLandscape = screenWidth > screenHeight;
    final isDesktop = screenWidth > 800;
    final imageSize = isDesktop
        ? screenHeight * 0.38
        : isLandscape
        ? screenHeight * 0.45
        : screenWidth < 360
        ? screenWidth * 0.75
        : screenWidth < 600
        ? screenWidth * 0.80
        : screenWidth * 0.65;

    const borderRadius = 24.0;

    return FlipCard(
      rotateSide: RotateSide.right,
      onTapFlipping:
          !offlineMode.value && !(metadata.extras?['isLive'] ?? false),
      controller: lyricsController,
      frontWidget: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: SongArtworkWidget(
                metadata: metadata,
                size: imageSize,
                errorWidgetIconSize: size.width / 8,
                borderRadius: borderRadius,
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: _AudioQualityBadge(metadata: metadata),
            ),
          ],
        ),
      ),
      backWidget: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _LyricsView(metadata: metadata)),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => showFullscreenLyrics(context, metadata),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onSecondaryContainer.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.text_quote_24_regular,
                        size: 16,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tt('Layar penuh', 'Full screen'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fetches and caches lyrics lazily per song.
class _LyricsView extends StatefulWidget {
  const _LyricsView({
    super.key,
    required this.metadata,
    this.fullscreen = false,
    this.textColor,
  });
  final MediaItem metadata;
  final bool fullscreen;
  final Color? textColor;

  @override
  State<_LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<_LyricsView> {
  String? _resolvedKey;
  late Future<Lyrics?> _lyricsFuture;

  @override
  void initState() {
    super.initState();
    _resolveIfNeeded();
  }

  @override
  void didUpdateWidget(_LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveIfNeeded();
  }

  void _resolveIfNeeded() {
    final key = '${widget.metadata.artist} - ${widget.metadata.title}';
    if (key == _resolvedKey) return;
    _resolvedKey = key;
    _lyricsFuture = getSongLyricsResult(
      widget.metadata.artist,
      widget.metadata.title,
      duration: widget.metadata.duration,
      album: widget.metadata.album,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = widget.textColor ?? colorScheme.onSecondaryContainer;

    Widget unavailable() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.text_quote_24_regular,
            size: 48,
            color: textColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n!.lyricsNotAvailable,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return AsyncLoader<Lyrics?>(
      future: _lyricsFuture,
      emptyWidget: unavailable(),
      errorBuilder: (ctx, error, stack) => unavailable(),
      builder: (context, lyrics) {
        if (lyrics == null || lyrics.isEmpty) return unavailable();

        // Re-evaluated when the setting changes, so toggling it takes effect
        // without reloading the lyrics.
        return ValueListenableBuilder<bool>(
          valueListenable: syncedLyricsEnabled,
          builder: (context, syncedEnabled, _) {
            if (lyrics.isSynced && syncedEnabled) {
              return SyncedLyricsView(
                lyrics: lyrics,
                songId: widget.metadata.id,
                fontSize: widget.fullscreen ? 28 : 20,
                textColor: textColor,
                leftAlign: widget.fullscreen,
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: widget.fullscreen
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  if (!lyrics.isSynced) ...[
                    Text(
                      tt(
                        'Lirik ini tidak punya timestamp, jadi tidak ikut bergerak bersama lagu.',
                        'These lyrics have no timestamps, so they do not follow the song.',
                      ),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                      textAlign: widget.fullscreen
                          ? TextAlign.left
                          : TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    formatPlainLyrics(lyrics),
                    style: TextStyle(
                      fontSize: widget.fullscreen ? 24 : 18,
                      fontWeight: widget.fullscreen
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: textColor,
                      height: 1.6,
                    ),
                    textAlign: widget.fullscreen
                        ? TextAlign.left
                        : TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

typedef _AudioQualityInfo = ({int bitrateKbps, String codec});

String _normalizeCodec(String codec) => switch (codec) {
  final c when c.startsWith('opus') => 'Opus',
  final c when c.startsWith('mp4a') => 'AAC',
  final c => c,
};

/// Resolves a song's stored or playback audio quality, or null if unavailable.
Future<_AudioQualityInfo?> _resolveAudioQuality(String ytid) async {
  final offlineSong = getOfflineSongByYtid(ytid);
  final offlineBitrate = offlineSong['audioBitrateKbps'] as int?;
  final offlineCodec = offlineSong['audioCodec'] as String?;
  if (offlineBitrate != null && offlineCodec != null) {
    return (bitrateKbps: offlineBitrate, codec: _normalizeCodec(offlineCodec));
  }
  if (offlineSong.isNotEmpty || offlineMode.value) return null;

  // Free for a song that is playing: the stream it picked is already resolved
  // and cached, so this reads it back instead of asking YouTube again.
  final stream = await fetchBestAudioStream(ytid);
  if (stream == null) return null;

  return (
    bitrateKbps: stream.bitrate.kiloBitsPerSecond.round(),
    codec: _normalizeCodec(stream.audioCodec),
  );
}

/// Shows the current song's resolved audio bitrate and codec.
class _AudioQualityBadge extends StatefulWidget {
  const _AudioQualityBadge({required this.metadata});
  final MediaItem metadata;

  @override
  State<_AudioQualityBadge> createState() => _AudioQualityBadgeState();
}

class _AudioQualityBadgeState extends State<_AudioQualityBadge> {
  String? _resolvedYtid;
  Future<_AudioQualityInfo?>? _infoFuture;

  @override
  void initState() {
    super.initState();
    _resolveIfNeeded();
  }

  @override
  void didUpdateWidget(_AudioQualityBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveIfNeeded();
  }

  void _resolveIfNeeded() {
    final ytid = widget.metadata.extras?['ytid']?.toString();
    if (ytid == _resolvedYtid) return;
    _resolvedYtid = ytid;

    final shouldResolve =
        showAudioQualityBadge.value && ytid != null && ytid.isNotEmpty;
    _infoFuture = shouldResolve ? _resolveAudioQuality(ytid) : null;
  }

  @override
  Widget build(BuildContext context) {
    final infoFuture = _infoFuture;
    if (infoFuture == null) return const SizedBox.shrink();

    return FutureBuilder<_AudioQualityInfo?>(
      future: infoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${info.bitrateKbps} kbps • ${info.codec}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

/// Opens the lyrics on a full screen page, Spotify style.
Future<void> showFullscreenLyrics(BuildContext context, MediaItem metadata) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondary) =>
          _FullscreenLyricsPage(metadata: metadata),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _FullscreenLyricsPage extends StatelessWidget {
  const _FullscreenLyricsPage({required this.metadata});

  final MediaItem metadata;

  String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = colorScheme.primaryContainer;
    final textColor = colorScheme.onPrimaryContainer;

    // Follows the song that is playing, so the title and the lyrics change
    // together with the song (no need to leave and reopen the page).
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      initialData: metadata,
      builder: (context, snapshot) {
        final current = snapshot.data ?? metadata;
        return _buildPage(context, current, background, textColor);
      },
    );
  }

  Widget _buildPage(
    BuildContext context,
    MediaItem current,
    Color background,
    Color textColor,
  ) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      FluentIcons.chevron_down_24_regular,
                      color: textColor,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          current.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          current.artist ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _LyricsView(
                key: ValueKey(current.id),
                metadata: current,
                fullscreen: true,
                textColor: textColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: StreamBuilder<PositionData>(
                stream: audioHandler.positionDataStream,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final position = data?.position ?? Duration.zero;
                  final duration = data?.duration ?? Duration.zero;
                  final progress = duration.inMilliseconds <= 0
                      ? 0.0
                      : (position.inMilliseconds / duration.inMilliseconds)
                            .clamp(0.0, 1.0);

                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: textColor.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _format(position),
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _format(duration),
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return GestureDetector(
                  onTap: playing ? audioHandler.pause : audioHandler.play,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: textColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      playing
                          ? FluentIcons.pause_24_regular
                          : FluentIcons.play_24_filled,
                      color: background,
                      size: 30,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}
