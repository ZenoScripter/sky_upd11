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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/services/account_service.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/skyfy_text.dart';
import 'package:musify/widgets/skyfy_backdrop.dart';
import 'package:musify/widgets/skyfy_widgets.dart';

/// Sign in / register with e-mail or Google.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _displayName = TextEditingController();

  bool _register = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _afterSignIn();
    } catch (e) {
      if (mounted) setState(() => _error = describeAccountError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _afterSignIn() async {
    final uid = AccountService.instance.uid;
    final hasProfile =
        uid != null && await AccountService.instance.hasProfile(uid);
    if (!mounted) return;
    if (hasProfile) {
      context.pop();
    } else {
      context.pushReplacement('/settings/complete-profile');
    }
  }

  Future<void> _submit() {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(
        () => _error = tt(
          'Isi email dan password',
          'Enter your email and password',
        ),
      );
      return Future<void>.value();
    }
    if (_register) {
      if (_username.text.trim().isEmpty || _displayName.text.trim().isEmpty) {
        setState(
          () => _error = tt(
            'Isi username dan nama tampilan',
            'Enter a username and a display name',
          ),
        );
        return Future<void>.value();
      }
      return _run(
        () => AccountService.instance.register(
          email: email,
          password: password,
          username: _username.text,
          displayName: _displayName.text,
        ),
      );
    }
    return _run(() => AccountService.instance.signInWithEmail(email, password));
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text.trim());
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tt('Lupa password', 'Forgot password')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(hintText: tt('Email akunmu', 'Your account email')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tt('Batal', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tt('Kirim', 'Send')),
          ),
        ],
      ),
    );
    final email = controller.text.trim();
    if (send != true || email.isEmpty) return;

    try {
      await AccountService.instance.sendPasswordReset(email);
      if (!mounted) return;
      showToast(
        context,
        tt(
          'Tautan reset password dikirim ke email',
          'A password reset link was sent to your email',
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = describeAccountError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_register ? tt('Daftar', 'Sign up') : tt('Masuk', 'Sign in')),
      ),
      body: SingleChildScrollView(
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SkyfyBackdrop(height: 260),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: ValueListenableBuilder<bool>(
                valueListenable: AccountService.instance.available,
                builder: (context, available, _) {
                  if (!available) return _unavailable(colorScheme);
                  return _form(colorScheme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unavailable(ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const SkyfyLogo(size: 88),
        const SizedBox(height: 24),
        Text(
          tt(
            'Akun belum aktif di versi ini. Fitur musik tetap bisa dipakai seperti biasa.',
            'Accounts are not active in this build. Music features keep working as usual.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.5),
        ),
      ],
    );
  }

  Widget _form(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Center(child: SkyfyLogo(size: 84)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(tt('Masuk', 'Sign in'), textAlign: TextAlign.center),
                ),
                selected: !_register,
                onSelected: (_) => setState(() {
                  _register = false;
                  _error = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(tt('Daftar', 'Sign up'), textAlign: TextAlign.center),
                ),
                selected: _register,
                onSelected: (_) => setState(() {
                  _register = true;
                  _error = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_register) ...[
          TextField(
            controller: _displayName,
            maxLength: 30,
            textInputAction: TextInputAction.next,
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
            textInputAction: TextInputAction.next,
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
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _password,
          obscureText: _hidePassword,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(
                _hidePassword
                    ? FluentIcons.eye_24_regular
                    : FluentIcons.eye_off_24_regular,
                size: 20,
              ),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
        ),
        if (!_register)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _forgotPassword,
              child: Text(tt('Lupa password?', 'Forgot password?')),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: colorScheme.error)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(_register ? tt('Buat akun', 'Create account') : tt('Masuk', 'Sign in')),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(AccountService.instance.signInWithGoogle),
            child: Text(tt('Lanjut dengan Google', 'Continue with Google')),
          ),
        ),
      ],
    );
  }
}
