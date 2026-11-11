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
import 'package:musify/constants/version.dart';
import 'package:musify/services/profile_manager.dart';
import 'package:musify/utilities/skyfy_text.dart';
import 'package:musify/widgets/skyfy_backdrop.dart';
import 'package:musify/widgets/skyfy_widgets.dart';

/// First screen of the app: logo, tagline and a short loading bar, then it
/// continues to the onboarding (first run) or straight to Home.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _continue();
      })
      ..forward();
  }

  void _continue() {
    if (!mounted) return;
    context.go(onboardingDone.value ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SkyfyBackdrop(height: MediaQuery.sizeOf(context).height),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                const SkyfyLogo(size: 120),
                const SizedBox(height: 18),
                Text(
                  'Skyfy',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Music for your moment',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(flex: 6),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return SizedBox(
                      width: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: Curves.easeInOut.transform(_controller.value),
                          minHeight: 4,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  tt('Memuat data...', 'Loading...'),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v$appVersion',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
