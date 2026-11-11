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

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/services/account_service.dart';
import 'package:musify/utilities/skyfy_text.dart';

/// Shown once after the first Google sign-in: choose a unique username.
class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final TextEditingController _username = TextEditingController();
  late final TextEditingController _displayName = TextEditingController(
    text: AccountService.instance.authDisplayName,
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_username.text.trim().isEmpty || _displayName.text.trim().isEmpty) {
      setState(
        () => _error = tt(
          'Isi username dan nama tampilan',
          'Enter a username and a display name',
        ),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AccountService.instance.completeProfile(
        username: _username.text,
        displayName: _displayName.text,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = describeAccountError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    await AccountService.instance.signOut();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(tt('Lengkapi profil', 'Complete your profile'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tt(
                'Pilih username unik. Teman akan mencarimu dengan username ini.',
                'Pick a unique username. Friends will find you with it.',
              ),
              style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _displayName,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: tt('Nama tampilan', 'Display name'),
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _username,
              maxLength: 20,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                counterText: '',
                helperText: tt(
                  'Huruf kecil, angka, garis bawah',
                  'Lowercase letters, digits, underscore',
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: colorScheme.error)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(tt('Simpan', 'Save')),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: _busy ? null : _cancel,
                child: Text(tt('Keluar', 'Sign out')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
