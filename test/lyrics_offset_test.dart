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

import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/lyrics/lyrics_models.dart';

void main() {
  const lrc = Lyrics(
    source: 'test',
    trackDuration: Duration(minutes: 3, seconds: 46),
  );

  test('delays lyrics when the audio has an extra intro', () {
    final offset = autoLyricsOffset(lrc, const Duration(minutes: 4));
    expect(offset, const Duration(seconds: -14));
  });

  test('keeps lyrics untouched when durations match', () {
    expect(
      autoLyricsOffset(lrc, const Duration(minutes: 3, seconds: 47)),
      Duration.zero,
    );
  });

  test('ignores big differences (a different edit) and unknown durations', () {
    expect(
      autoLyricsOffset(lrc, const Duration(minutes: 8)),
      Duration.zero,
    );
    expect(autoLyricsOffset(lrc, null), Duration.zero);
    expect(
      autoLyricsOffset(const Lyrics(source: 'x'), const Duration(minutes: 4)),
      Duration.zero,
    );
  });
}
