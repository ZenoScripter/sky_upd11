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

/// Shows the QRIS code used to support Skyfy. Pinch to zoom for scanning.
Future<void> showQrisDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      final maxHeight = MediaQuery.sizeOf(context).height * 0.62;

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tt('Dukung Skyfy', 'Support Skyfy'),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tt(
                  'Scan dengan aplikasi e-wallet atau mobile banking.',
                  'Scan with any e-wallet or mobile banking app.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.asset(
                      'assets/images/qris.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tt('Terima kasih atas dukunganmu', 'Thank you for your support'),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tt('Tutup', 'Close')),
              ),
            ],
          ),
        ),
      );
    },
  );
}
