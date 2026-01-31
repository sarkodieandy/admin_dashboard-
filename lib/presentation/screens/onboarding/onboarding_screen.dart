import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_network_image.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const routePath = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _prefsKeySeen = 'seen_onboarding';
  static const _twemojiBase = 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72';

  late final PageController _controller;
  int _index = 0;
  DateTime? _pausedUntil;
  Timer? _autoTimer;

  final _pages = const [
    _OnboardingPageData(
      title: 'Order your favourites',
      body: 'Browse the menu and add items to your cart in seconds.',
      iconUrl: '$_twemojiBase/1f6d2.png',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1400&q=80',
    ),
    _OnboardingPageData(
      title: 'Fast delivery in Bekwai',
      body: 'Add a landmark and we’ll deliver quickly within our service area.',
      iconUrl: '$_twemojiBase/1f69a.png',
      imageUrl:
          'https://images.unsplash.com/photo-1521305916504-4a1121188589?auto=format&fit=crop&w=1400&q=80',
    ),
    _OnboardingPageData(
      title: 'Track every order',
      body: 'Get updates and re‑order your favourites in one tap.',
      iconUrl: '$_twemojiBase/1f9fe.png',
      imageUrl:
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1400&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) => _autoAdvance());
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeySeen, true);
  }

  Future<void> _finish() async {
    await _markSeen();
    if (!mounted) return;
    context.go(HomeScreen.routePath);
  }

  Future<void> _skip() => _finish();

  Future<void> _next() async {
    if (_index >= _pages.length - 1) {
      await _finish();
      return;
    }

    await _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _back() async {
    if (_index <= 0) return;
    await _controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _pauseAuto([Duration duration = const Duration(seconds: 8)]) {
    _pausedUntil = DateTime.now().add(duration);
  }

  Future<void> _autoAdvance() async {
    if (!mounted) return;
    if (!_controller.hasClients) return;
    if (_index >= _pages.length - 1) return;
    final until = _pausedUntil;
    if (until != null && DateTime.now().isBefore(until)) return;

    await _controller.nextPage(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = BorderSide(color: Colors.white.withValues(alpha: 0.18));

    return Scaffold(
      body: Stack(
        children: [
          Listener(
            onPointerDown: (_) => _pauseAuto(),
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: _pages.length,
              itemBuilder: (context, i) => _OnboardingPage(
                data: _pages[i],
                controller: _controller,
                index: i,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16, vertical: AppSpacing.x12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.charcoal.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Row(
                  children: [
                    Text(
                      AppStrings.appName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: _skip,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x16,
                  AppSpacing.x16,
                  AppSpacing.x16,
                  AppSpacing.x16,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.x14),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(AppRadius.r20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.32),
                        blurRadius: 26,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dots(count: _pages.length, index: _index),
                      const SizedBox(height: AppSpacing.x12),
                      Row(
                        children: [
                          if (_index > 0) ...[
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: outline,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.r16),
                                  ),
                                ),
                                onPressed: _back,
                                child: const Text('Back'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x12),
                          ],
                          Expanded(
                            child: AppButton(
                              label: _index == _pages.length - 1 ? 'Start ordering' : 'Next',
                              onPressed: _next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x10),
                      if (_index == _pages.length - 1)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: outline,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.r16),
                                  ),
                                ),
                                onPressed: () => context.push(SignupScreen.routePath),
                                child: const Text(AppStrings.signUp),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: outline,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.r16),
                                  ),
                                ),
                                onPressed: () => context.push(LoginScreen.routePath),
                                child: const Text(AppStrings.logIn),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.body,
    required this.iconUrl,
    required this.imageUrl,
  });

  final String title;
  final String body;
  final String iconUrl;
  final String imageUrl;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.controller,
    required this.index,
  });

  final _OnboardingPageData data;
  final PageController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onDark = Colors.white;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients
            ? (controller.page ?? controller.initialPage.toDouble())
            : controller.initialPage.toDouble();
        final delta = (page - index).clamp(-1.0, 1.0);
        final focus = (1 - delta.abs()).clamp(0.0, 1.0);

        final bgX = delta * 26;
        final cardY = (1 - focus) * 18;
        final cardOpacity = (0.72 + (focus * 0.28)).clamp(0.0, 1.0);
        final iconScale = 0.92 + (focus * 0.08);

        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(bgX, 0),
              child: AppNetworkImage(
                url: data.imageUrl,
                height: double.infinity,
                width: double.infinity,
                borderRadius: 0,
                fit: BoxFit.cover,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.62),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.x16, 90, AppSpacing.x16, 140),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Opacity(
                    opacity: cardOpacity,
                    child: Transform.translate(
                      offset: Offset(0, cardY),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.x16),
                        decoration: BoxDecoration(
                          color: AppColors.charcoal.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(AppRadius.r20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.30),
                              blurRadius: 24,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.scale(
                              scale: iconScale,
                              child: Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(AppRadius.r16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                ),
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.all(9),
                                  child: AppNetworkImage(
                                    url: data.iconUrl,
                                    height: 26,
                                    width: 26,
                                    fit: BoxFit.contain,
                                    borderRadius: 0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.x12),
                            Text(
                              data.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: onDark,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.x8),
                            Text(
                              data.body,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 7,
          width: i == index ? 18 : 7,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: i == index ? 0.95 : 0.45),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}
