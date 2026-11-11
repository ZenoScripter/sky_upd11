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
import 'package:musify/services/profile_manager.dart';
import 'package:musify/utilities/skyfy_text.dart';
import 'package:musify/widgets/skyfy_backdrop.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

/// Three short intro slides shown once, right after the splash screen.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _index = 0;

  List<_OnboardingSlide> get _slides => [
    _OnboardingSlide(
      icon: FluentIcons.music_note_2_24_filled,
      title: tt('Nikmati Musik\nTanpa Batas', 'Enjoy Music\nWithout Limits'),
      description: tt(
        'Dengarkan, unduh, dan kelola lagu favoritmu dengan mudah, cepat, dan gratis.',
        'Listen, download and manage your favourite songs easily, quickly and for free.',
      ),
    ),
    _OnboardingSlide(
      icon: FluentIcons.arrow_download_24_filled,
      title: tt('Dengarkan\nBahkan Offline', 'Listen Even\nWhen Offline'),
      description: tt(
        'Unduh lagu favoritmu dan putar kapan saja, tanpa perlu koneksi internet.',
        'Download your favourite songs and play them anytime, no internet needed.',
      ),
    ),
    _OnboardingSlide(
      icon: FluentIcons.color_24_regular,
      title: tt('Playlist &\nTema Kustom', 'Playlists &\nCustom Themes'),
      description: tt(
        'Susun playlist sendiri dan atur tema serta warna aksen sesuai moodmu.',
        'Build your own playlists and pick the theme and accent that fit your mood.',
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await completeOnboarding();
    if (!mounted) return;
    context.go('/home');
  }

  void _next() {
    if (_index >= _slides.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final slides = _slides;
    final isLast = _index == slides.length - 1;

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
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                    child: AnimatedOpacity(
                      opacity: isLast ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: TextButton(
                        onPressed: isLast ? null : _finish,
                        child: Text(
                          tt('Lewati', 'Skip'),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: slides.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, i) => _SlideView(slide: slides[i]),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? colorScheme.primary
                            : colorScheme.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _next,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast
                                ? tt('Mulai Sekarang', 'Get Started')
                                : tt('Lanjut', 'Next'),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            FluentIcons.chevron_right_24_regular,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _SlideArt(icon: slide.icon)),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.description,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideArt extends StatelessWidget {
  const _SlideArt({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget card(double angle, Color color, double size, Widget? child) {
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: 260,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            top: 30,
            child: card(
              -0.28,
              colorScheme.primary.withValues(alpha: 0.18),
              130,
              null,
            ),
          ),
          Positioned(
            right: 4,
            bottom: 18,
            child: card(
              0.26,
              colorScheme.primary.withValues(alpha: 0.28),
              120,
              null,
            ),
          ),
          card(
            -0.05,
            colorScheme.primary.withValues(alpha: 0.55),
            150,
            Icon(icon, size: 74, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
