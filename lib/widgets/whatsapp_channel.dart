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
import 'package:musify/utilities/skyfy_text.dart';
import 'package:musify/utilities/url_launcher.dart';

/// Official Skyfy WhatsApp Channel (news, announcements and updates).
const String skyfyWhatsappChannelUrl =
    'https://whatsapp.com/channel/0029VaxXr2L7NoZzrJrL5T2o';

/// Asks the user first, then opens the Skyfy WhatsApp Channel.
Future<void> confirmOpenWhatsappChannel(BuildContext context) async {
  final open = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(tt('Channel WhatsApp Skyfy', 'Skyfy WhatsApp Channel')),
        content: Text(
          tt(
            'Ingin mengunjungi Channel WhatsApp resmi Skyfy?',
            'Do you want to visit the official Skyfy WhatsApp Channel?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tt('Tidak', 'No')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tt('Ya', 'Yes')),
          ),
        ],
      );
    },
  );

  if (open == true) {
    await launchURL(Uri.parse(skyfyWhatsappChannelUrl));
  }
}
