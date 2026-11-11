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
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:musify/services/profile_manager.dart';

/// Soft glow + flowing wave lines (or the user's own picture) used behind the
/// headers of the Skyfy screens. Works in both light and dark mode.
class SkyfyBackdrop extends StatelessWidget {
  const SkyfyBackdrop({
    super.key,
    this.height = 360,
    this.styleIndex,
    this.global = false,
  });

  final double height;

  /// True only for the single full-screen instance created by the app shell.
  /// Every other instance hides itself while "Full Background" is on.
  final bool global;

  /// Forces a style (used by the theme picker previews). When null the style
  /// chosen by the user is used.
  final int? styleIndex;

  /// `[top glow, wave line]` pairs. Index matches [backdropStyle].
  static const List<List<Color>> styles = [
    [Color(0xFF2B1F55), Color(0xFF8B6CF0)],
    [Color(0xFF12254E), Color(0xFF3B82F6)],
    [Color(0xFF4A2350), Color(0xFFF472B6)],
    [Color(0xFF181822), Color(0xFF55557A)],
  ];

  static const int stylesCount = 4;

  /// Style index that shows the picture picked by the user.
  static const int customIndex = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (styleIndex != null) {
      return _buildStyle(theme, styleIndex!);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: fullBackground,
      builder: (context, full, _) {
        if (full && !global) return const SizedBox.shrink();
        return ValueListenableBuilder<int>(
          valueListenable: backdropStyle,
          builder: (context, index, _) => _buildStyle(theme, index),
        );
      },
    );
  }

  Widget _buildStyle(ThemeData theme, int index) {
    if (index == customIndex) {
      return ValueListenableBuilder<String?>(
        valueListenable: customBackdrop,
        builder: (context, image, _) {
          final bytes = _decode(image);
          if (bytes == null) return _buildPaint(theme, 0);
          return _buildCustom(theme, bytes);
        },
      );
    }
    return _buildPaint(theme, index);
  }

  static Uint8List? _decode(String? image) {
    if (image == null || image.isEmpty) return null;
    try {
      final data = image.contains(',') ? image.split(',').last : image;
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }

  Widget _buildCustom(ThemeData theme, Uint8List bytes) {
    final base = theme.colorScheme.surface;
    final isLight = theme.brightness == Brightness.light;

    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    base.withValues(alpha: isLight ? 0.25 : 0.35),
                    base.withValues(alpha: isLight ? 0.7 : 0.8),
                    base,
                  ],
                  stops: const [0, 0.6, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaint(ThemeData theme, int index) {
    final safeIndex = index >= 0 && index < styles.length ? index : 0;
    final pair = styles[safeIndex];
    final base = theme.colorScheme.surface;
    final isLight = theme.brightness == Brightness.light;
    final top = isLight
        ? Color.alphaBlend(pair[1].withValues(alpha: 0.22), base)
        : pair[0];

    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(
          painter: _BackdropPainter(top: top, wave: pair[1], base: base),
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({
    required this.top,
    required this.wave,
    required this.base,
  });

  final Color top;
  final Color wave;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, base.withValues(alpha: 0)],
        ).createShader(rect),
    );

    final w = size.width;
    final h = size.height;

    final fill = Path()
      ..moveTo(0, h * 0.34)
      ..cubicTo(w * 0.28, h * 0.30, w * 0.46, h * 0.08, w * 0.72, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            wave.withValues(alpha: 0.30),
            wave.withValues(alpha: 0.02),
          ],
        ).createShader(rect),
    );

    final line1 = Path()
      ..moveTo(0, h * 0.34)
      ..cubicTo(w * 0.28, h * 0.30, w * 0.46, h * 0.08, w * 0.72, 0);
    final line2 = Path()
      ..moveTo(w * 0.35, h * 0.62)
      ..cubicTo(w * 0.62, h * 0.55, w * 0.85, h * 0.30, w, h * 0.22);

    canvas
      ..drawPath(
        line1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = wave.withValues(alpha: 0.45),
      )
      ..drawPath(
        line2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = wave.withValues(alpha: 0.22),
      );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.top != top ||
      oldDelegate.wave != wave ||
      oldDelegate.base != base;
}
