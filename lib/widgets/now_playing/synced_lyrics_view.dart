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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/main.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/services/lyrics/lyrics_models.dart';

/// Shows time-synced lyrics: the current line is highlighted and kept in view,
/// tapping a line seeks to it, and the timing can be nudged with +/- buttons
/// when a lyrics file is slightly early or late.
class SyncedLyricsView extends StatefulWidget {
  const SyncedLyricsView({
    super.key,
    required this.lyrics,
    this.fontSize = 20,
    this.textColor,
    this.leftAlign = false,
    this.songId,
  });

  final Lyrics lyrics;

  /// Size of every lyric line (the fullscreen view uses a bigger one).
  final double fontSize;

  /// Overrides the default text color.
  final Color? textColor;

  /// Left aligns the lines instead of centering them.
  final bool leftAlign;

  /// Used to remember the offset correction of each song.
  final String? songId;

  @override
  State<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<SyncedLyricsView> {
  static const Duration _offsetStep = Duration(milliseconds: 500);
  static const Duration _manualScrollPause = Duration(seconds: 4);
  static const Duration _scrollDuration = Duration(milliseconds: 350);

  StreamSubscription<PositionData>? _positionSubscription;
  List<GlobalKey> _lineKeys = const [];
  Duration _position = Duration.zero;
  Duration _offset = Duration.zero;
  Duration _autoOffset = Duration.zero;
  bool _hasSavedOffset = false;
  bool _autoResolved = false;
  int _activeIndex = -1;
  DateTime _autoScrollResumesAt = DateTime.fromMillisecondsSinceEpoch(0);

  List<LyricLine> get _lines => widget.lyrics.synced ?? const <LyricLine>[];

  @override
  void initState() {
    super.initState();
    _prepareLines();
    _loadOffset();
    _position = audioHandler.currentPositionData.position;
    _resolveAutoOffset(audioHandler.currentPositionData.duration);
    _activeIndex = _computeActiveIndex();
    _positionSubscription = audioHandler.positionDataStream.listen((data) {
      _position = data.position;
      final before = _offset;
      _resolveAutoOffset(data.duration);
      if (_offset != before && mounted) setState(() {});
      _refreshActiveLine();
    });
    _scheduleScrollToActive(animate: false);
  }

  @override
  void didUpdateWidget(SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.lyrics, widget.lyrics)) {
      _prepareLines();
      _loadOffset();
      _resolveAutoOffset(audioHandler.currentPositionData.duration);
      _activeIndex = _computeActiveIndex();
      _scheduleScrollToActive(animate: false);
    }
  }

  @override
  void dispose() {
    unawaited(_positionSubscription?.cancel());
    super.dispose();
  }

  /// Saved correction of this song, or none.
  Duration? _readSavedOffset() {
    final id = widget.songId;
    if (id == null || id.isEmpty) return null;
    try {
      final raw = Hive.box('settings').get('lyricsOffsets');
      if (raw is Map) {
        final value = raw[id];
        if (value is int) return Duration(milliseconds: value);
      }
    } catch (_) {}
    return null;
  }

  void _writeSavedOffset(Duration? value) {
    final id = widget.songId;
    if (id == null || id.isEmpty) return;
    try {
      final box = Hive.box('settings');
      final raw = box.get('lyricsOffsets');
      final map = Map<String, dynamic>.from(
        raw is Map ? raw : const <String, dynamic>{},
      )..remove(id);
      if (value != null) map[id] = value.inMilliseconds;
      while (map.length > 500) {
        map.remove(map.keys.first);
      }
      unawaited(box.put('lyricsOffsets', map));
    } catch (_) {}
  }

  void _loadOffset() {
    final saved = _readSavedOffset();
    _hasSavedOffset = saved != null;
    _autoResolved = false;
    _autoOffset = Duration.zero;
    _offset = saved ?? Duration.zero;
  }

  /// Smart offset: once the real audio length is known, delay lyrics whose
  /// timestamps were written for a shorter recording (see [autoLyricsOffset]).
  void _resolveAutoOffset(Duration duration) {
    if (_autoResolved || duration <= Duration.zero) return;
    _autoResolved = true;
    _autoOffset = autoLyricsOffset(widget.lyrics, duration);
    if (!_hasSavedOffset) _offset = _autoOffset;
  }

  void _prepareLines() {
    _lineKeys = List<GlobalKey>.generate(_lines.length, (_) => GlobalKey());
  }

  int _computeActiveIndex() => widget.lyrics.lineIndexAt(_position + _offset);

  void _refreshActiveLine() {
    final index = _computeActiveIndex();
    if (index == _activeIndex || !mounted) return;
    setState(() => _activeIndex = index);
    _scheduleScrollToActive();
  }

  void _scheduleScrollToActive({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (DateTime.now().isBefore(_autoScrollResumesAt)) return;
      if (_activeIndex < 0 || _activeIndex >= _lineKeys.length) return;

      final lineContext = _lineKeys[_activeIndex].currentContext;
      if (lineContext == null) return;

      unawaited(
        Scrollable.ensureVisible(
          lineContext,
          alignment: 0.4,
          duration: animate ? _scrollDuration : Duration.zero,
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  void _changeOffset(Duration delta) {
    setState(() {
      if (delta == Duration.zero) {
        // Back to the automatic value and forget the saved correction.
        _offset = _autoOffset;
        _hasSavedOffset = false;
        _writeSavedOffset(null);
      } else {
        _offset += delta;
        _hasSavedOffset = true;
        _writeSavedOffset(_offset);
      }
      _activeIndex = _computeActiveIndex();
    });
    _autoScrollResumesAt = DateTime.fromMillisecondsSinceEpoch(0);
    _scheduleScrollToActive();
  }

  void _seekToLine(LyricLine line) {
    final target = line.start - _offset;
    unawaited(audioHandler.seek(target.isNegative ? Duration.zero : target));
    _autoScrollResumesAt = DateTime.fromMillisecondsSinceEpoch(0);
  }

  String get _offsetLabel {
    if (_offset == Duration.zero) return '0.0s';
    final seconds = _offset.inMilliseconds / 1000;
    final auto = !_hasSavedOffset && _offset == _autoOffset ? ' auto' : '';
    return '${seconds > 0 ? '+' : ''}${seconds.toStringAsFixed(1)}s$auto';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = widget.textColor ?? colorScheme.onSecondaryContainer;
    final lines = _lines;

    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollStartNotification>(
            onNotification: (notification) {
              // Only a finger/mouse drag pauses auto-scroll, not our own
              // ensureVisible animation (which has no drag details).
              if (notification.dragDetails != null) {
                _autoScrollResumesAt = DateTime.now().add(_manualScrollPause);
              }
              return false;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Blank space above and below lets the first and last lines
                // reach the vertical middle of the card.
                final edgePadding = constraints.maxHeight * 0.4;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    edgePadding,
                    20,
                    edgePadding,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: widget.leftAlign
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      for (var i = 0; i < lines.length; i++)
                        _buildLine(i, lines[i], textColor),
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          '© ${widget.lyrics.source}',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        _buildOffsetControls(textColor),
      ],
    );
  }

  Widget _buildLine(int index, LyricLine line, Color baseColor) {
    final isActive = index == _activeIndex;
    return GestureDetector(
      key: _lineKeys[index],
      behavior: HitTestBehavior.opaque,
      onTap: () => _seekToLine(line),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: widget.fontSize,
            height: 1.4,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: baseColor.withValues(alpha: isActive ? 1 : 0.45),
          ),
          textAlign: widget.leftAlign ? TextAlign.left : TextAlign.center,
          child: Text(line.text.isEmpty ? '♪' : line.text),
        ),
      ),
    );
  }

  Widget _buildOffsetControls(Color color) {
    final dimmed = color.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            color: dimmed,
            icon: const Icon(FluentIcons.subtract_24_regular),
            onPressed: () => _changeOffset(-_offsetStep),
          ),
          GestureDetector(
            onTap: () => _changeOffset(Duration.zero),
            child: Text(
              _offsetLabel,
              style: TextStyle(fontSize: 12, color: dimmed),
            ),
          ),
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            color: dimmed,
            icon: const Icon(FluentIcons.add_24_regular),
            onPressed: () => _changeOffset(_offsetStep),
          ),
        ],
      ),
    );
  }
}
