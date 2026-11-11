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

import 'package:musify/services/settings_manager.dart';

/// Tiny helper for the Skyfy screens: Indonesian copy when the app language
/// is Indonesian, English copy for every other language.
String tt(String id, String en) => languageSetting.languageCode == 'id' ? id : en;

/// Greeting used on the Home screen, based on the local time of day.
String skyfyGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 11) return tt('Selamat pagi', 'Good morning');
  if (hour < 15) return tt('Selamat siang', 'Good afternoon');
  if (hour < 18) return tt('Selamat sore', 'Good afternoon');
  return tt('Selamat malam', 'Good evening');
}
