import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../utils/app_logger.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.r16,
    this.useShimmerPlaceholder = false,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String? url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double borderRadius;
  final bool useShimmerPlaceholder;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = (url ?? '').trim();

    Widget content;
    if (u.isEmpty) {
      content = Container(
        height: height,
        width: width,
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.restaurant_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      final base = theme.colorScheme.surfaceContainerHighest;

      content = CachedNetworkImage(
        imageUrl: u,
        height: height,
        width: width,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: const Duration(milliseconds: 80),
        placeholder: (context, _) {
          // Shimmer is intentionally optional; on dense lists it can cause jank on low-end devices.
          if (!useShimmerPlaceholder) {
            return Container(height: height, width: width, color: base);
          }
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, t, _) {
              final a = 0.10 + (0.10 * (1 - (2 * (t - 0.5)).abs()));
              return Container(
                height: height,
                width: width,
                color: base.withValues(alpha: 1),
                foregroundDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + (2 * t), -0.2),
                    end: Alignment(-0.2 + (2 * t), 0.2),
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: a),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              );
            },
          );
        },
        errorWidget: (context, _, error) {
          AppLogger.w('image_load_failed: $u', tag: 'image', error: error);
          return Container(
            height: height,
            width: width,
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: content,
    );
  }
}
