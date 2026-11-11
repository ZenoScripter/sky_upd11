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

import 'package:material_ui/material_ui.dart';

/// Skyfy design tokens (dark purple "music for your moment" look).
class SkyfyColors {
  const SkyfyColors._();

  static const Color background = Color(0xFF0E0E14);
  static const Color surface = Color(0xFF1A1B24);
  static const Color surfaceLow = Color(0xFF14151D);
  static const Color surfaceHigh = Color(0xFF222333);
  static const Color surfaceHighest = Color(0xFF2A2B3E);
  static const Color primary = Color(0xFFA78BFA);
  static const Color accent = Color(0xFFC4B5FD);
  static const Color text = Color(0xFFEEE6F0);
  static const Color textMuted = Color(0xFFA9A3B8);
  static const Color outline = Color(0xFF34344A);
  static const Color outlineSoft = Color(0xFF272839);
  static const Color glowTop = Color(0xFF2B1F55);
}

const Color skyfyDefaultAccent = SkyfyColors.primary;

const availableColors = <Color>[
  Color(0xFFA78BFA), // Skyfy Purple (default)
  Color(0xFF4F7DF3), // Blue
  Color(0xFFD946EF), // Magenta
  Color(0xFFEF4444), // Red
  Color(0xFFF97316), // Orange
  Color(0xFF22C55E), // Green
  Color(0xFF009688), // Material Teal
  Color(0xFF2196F3), // Material Blue
  Color(0xFFBA68C8), // Material Purple Light
  Color(0xFF00BCD4), // Material Cyan
  Color(0xFF00FA9A), // Medium Spring Green
  Color(0xFF9ACD32), // Yellow Green
  Color(0xFFCDDC39), // Lime
  Color(0xFFF08080), // Light Coral
  Color(0xFFE9967A), // Dark Salmon
  Color(0xFFFFC0CB), // Pink
  Color(0xFF6495ED), // Cornflower Blue
  Color(0xFFA6C8FF), // Lighter Cornflower Blue
  Color(0xFFF8C733), // Cadmium Yellow
  Color(0xFFBDB76B), // Dark Khaki
  Color(0xFFC4A092), // Material Brown
  Color(0xFFE2C09F), // Pale Peach
  Color(0xff91cef4), // Material Skycolor
  Color(0xFFAABBCC), // Light Steel Blue
];
