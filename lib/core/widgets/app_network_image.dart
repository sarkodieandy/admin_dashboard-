import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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
  });

  final String? url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double borderRadius;

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
      final highlight = theme.colorScheme.surface;

      content = CachedNetworkImage(
        imageUrl: u,
        height: height,
        width: width,
        fit: fit,
        placeholder: (context, _) => Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Container(
            height: height,
            width: width,
            color: base,
          ),
        ),
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
