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

/// A song a lyrics lookup is performed for.
class TrackInfo {
  const TrackInfo({
    required this.title,
    required this.artist,
    this.album,
    this.duration,
  });

  final String title;
  final String artist;
  final String? album;
  final Duration? duration;

  TrackInfo copyWith({String? title, String? artist}) => TrackInfo(
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album,
    duration: duration,
  );
}

/// One timed line of a synchronized (LRC) lyrics file.
class LyricLine {
  const LyricLine(this.start, this.text);

  final Duration start;
  final String text;

  @override
  String toString() => '[$start] $text';
}

/// Lyrics returned by a provider.
///
/// [plain] is always usable text. [synced] is only set by providers that
/// return timestamps (e.g. LRCLIB) and is sorted by start time.
class Lyrics {
  const Lyrics({
    required this.source,
    this.plain,
    this.synced,
    this.trackDuration,
  });

  /// Human readable provider name, e.g. `lrclib.net`.
  final String source;
  final String? plain;
  final List<LyricLine>? synced;

  /// Length of the recording the timestamps were written for (LRCLIB gives
  /// it). Compared with the audio that is really playing to detect intros the
  /// lyrics file does not know about.
  final Duration? trackDuration;

  bool get isSynced => synced != null && synced!.isNotEmpty;

  /// Plain text, derived from [synced] when the provider sent no plain text.
  String get text {
    final p = plain;
    if (p != null && p.trim().isNotEmpty) return p;
    return (synced ?? const <LyricLine>[]).map((l) => l.text).join('\n');
  }

  bool get isEmpty => text.trim().isEmpty;

  /// Index of the line that should be highlighted at [position], or -1 when
  /// the song has not reached the first line yet.
  int lineIndexAt(Duration position) {
    final lines = synced;
    if (lines == null || lines.isEmpty) return -1;
    var lo = 0;
    var hi = lines.length - 1;
    var result = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].start <= position) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return result;
  }
}

/// Offset (added to the audio position) that lines the timestamps of [lyrics]
/// up with the audio that is playing.
///
/// When the audio is a few seconds longer than the recording the lyrics were
/// timed for, the extra time is almost always an intro (music videos, lyric
/// videos), so the vocals start later than the timestamps say and the lyrics
/// must be delayed by the difference (a negative offset). Anything outside
/// 3 to 45 seconds is treated as a different edit and left alone; the user
/// can still fine-tune it and the correction is saved per song.
Duration autoLyricsOffset(Lyrics lyrics, Duration? audioDuration) {
  final track = lyrics.trackDuration;
  if (track == null || audioDuration == null) return Duration.zero;
  final diff = audioDuration - track;
  if (diff >= const Duration(seconds: 3) &&
      diff <= const Duration(seconds: 45)) {
    return -diff;
  }
  return Duration.zero;
}
