import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/promo.dart';

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.promos});

  final List<Promo> promos;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  late final PageController _controller;
  double _page = 0;
  Timer? _autoTimer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
    _startAutoSlideIfNeeded();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PromoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.promos.length != widget.promos.length) {
      _startAutoSlideIfNeeded();
    }
  }

  void _startAutoSlideIfNeeded() {
    _autoTimer?.cancel();
    if (!mounted) return;
    if (widget.promos.length <= 1) return;

    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      if (!_controller.hasClients) return;
      if (_userInteracting) return;

      final promos = widget.promos;
      if (promos.length <= 1) return;

      final current = (_controller.page ?? _controller.initialPage.toDouble()).round();
      final next = (current + 1) % promos.length;

      if (next == 0) {
        await _controller.animateToPage(
          0,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
        );
      } else {
        await _controller.nextPage(
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promos = widget.promos;
    if (promos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 150,
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final isInteracting = notification.direction != ScrollDirection.idle;
          if (_userInteracting != isInteracting) {
            setState(() => _userInteracting = isInteracting);
          }
          if (!isInteracting) _startAutoSlideIfNeeded();
          return false;
        },
        child: PageView.builder(
          controller: _controller,
          itemCount: promos.length,
          itemBuilder: (context, index) {
            final promo = promos[index];
            final t = (index - _page).abs().clamp(0, 1).toDouble();
            final scale = 1 - (t * 0.04);
            final bgShift = (index - _page) * 18;
            final bgUrl = _bgFor(promo);

            return Transform.scale(
              scale: scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.r20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.r20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Transform.translate(
                          offset: Offset(bgShift, 0),
                          child: Opacity(
                            opacity: 0.22,
                            child: AppNetworkImage(
                              url: bgUrl,
                              borderRadius: 0,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary.withValues(alpha: 0.96),
                                theme.colorScheme.tertiary.withValues(alpha: 0.92),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: Opacity(
                            opacity: 0.26,
                            child: Transform.rotate(
                              angle: -0.08,
                              child: SizedBox(
                                height: 96,
                                width: 96,
                                child: AppNetworkImage(
                                  url: _accentIconFor(promo),
                                  borderRadius: 0,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.x18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: AppNetworkImage(
                                            url: _flashIcon(),
                                            borderRadius: 0,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          promo.code,
                                          style: theme.textTheme.labelLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                    ),
                                    child: Text(
                                      'Flash sale',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.92),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.x12),
                              Text(
                                _headline(promo),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                  height: 1.1,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _subhead(promo),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _headline(Promo promo) {
    return switch (promo.type) {
      PromoType.percent => AppStrings.promoPercentHeadline(promo.value.toStringAsFixed(0)),
      PromoType.fixed => AppStrings.promoFixedHeadline(Money.format(promo.value)),
    };
  }

  String _subhead(Promo promo) {
    final min = promo.minSubtotal <= 0 ? null : Money.format(promo.minSubtotal);
    if (min == null) return AppStrings.promoSubheadNoMin();
    return AppStrings.promoSubheadWithMin(min);
  }

  String _bgFor(Promo promo) {
    return switch (promo.code.toUpperCase()) {
      'FLK10' =>
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1400&q=80',
      'BEKWAI5' =>
        'https://images.unsplash.com/photo-1510627498534-cf7e9002facc?auto=format&fit=crop&w=1400&q=80',
      _ => 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1400&q=80',
    };
  }

  String _accentIconFor(Promo promo) {
    const base = 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72';
    return switch (promo.code.toUpperCase()) {
      'FLK10' => '$base/1f35b.png',
      'BEKWAI5' => '$base/1f964.png',
      _ => '$base/1f355.png',
    };
  }

  String _flashIcon() {
    const base = 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72';
    return '$base/26a1.png';
  }
}
