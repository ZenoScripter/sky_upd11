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

import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/services/data_manager.dart';

/// Display name shown on the Home greeting and the Profile page.
final profileName = ValueNotifier<String>(
  (Hive.box('user').get('profileName', defaultValue: 'Listener') as String?) ??
      'Listener',
);

/// Profile photo stored as a `data:` URL (see `pickImage`). Null = default.
final profileImage = ValueNotifier<String?>(
  Hive.box('user').get('profileImage') as String?,
);

/// Whether the first-run onboarding has been completed.
final onboardingDone = ValueNotifier<bool>(
  (Hive.box('settings').get('onboardingDone', defaultValue: false) as bool?) ??
      false,
);

/// Index of the selected decorative background (see `SkyfyBackdrop`).
final backdropStyle = ValueNotifier<int>(
  (Hive.box('settings').get('backdropStyle', defaultValue: 0) as int?) ?? 0,
);

/// When true the background fills the whole app instead of only the top of
/// the header screens.
final fullBackground = ValueNotifier<bool>(
  (Hive.box('settings').get('fullBackground', defaultValue: false) as bool?) ??
      false,
);

Future<void> setFullBackground(bool value) async {
  fullBackground.value = value;
  await addOrUpdateData<bool>('settings', 'fullBackground', value);
}

/// User-picked background image (`data:` URL) used by backdrop style
/// `SkyfyBackdrop.customIndex`.
final customBackdrop = ValueNotifier<String?>(
  Hive.box('settings').get('customBackdrop') as String?,
);

Future<void> setCustomBackdrop(String? image) async {
  customBackdrop.value = image;
  await addOrUpdateData<String?>('settings', 'customBackdrop', image);
}

Future<void> saveProfile({required String name, String? image}) async {
  final cleanName = name.trim().isEmpty ? 'Listener' : name.trim();
  profileName.value = cleanName;
  profileImage.value = image;
  await addOrUpdateData<String>('user', 'profileName', cleanName);
  await addOrUpdateData<String?>('user', 'profileImage', image);
}

Future<void> completeOnboarding() async {
  onboardingDone.value = true;
  await addOrUpdateData<bool>('settings', 'onboardingDone', true);
}

Future<void> setBackdropStyle(int index) async {
  backdropStyle.value = index;
  await addOrUpdateData<int>('settings', 'backdropStyle', index);
}
