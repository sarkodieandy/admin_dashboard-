import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/category.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.onTap,
  });

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconUrl = _iconUrlFor(category.name);
    final hint = _hintFor(category.name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.tertiaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: AppNetworkImage(
                    url: iconUrl,
                    height: 26,
                    width: 26,
                    fit: BoxFit.contain,
                    borderRadius: 0,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.x6),
              Text(
                hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _iconUrlFor(String name) {
    final n = name.toLowerCase();
    const base = 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72';
    if (n.contains('drink')) return '$base/1f964.png';
    if (n.contains('dessert')) return '$base/1f370.png';
    if (n.contains('wrap') || n.contains('shawarma')) return '$base/1f959.png';
    if (n.contains('swallow') || n.contains('soup')) return '$base/1f35c.png';
    if (n.contains('grill') || n.contains('chicken')) return '$base/1f357.png';
    if (n.contains('side')) return '$base/1f35f.png';
    if (n.contains('jollof') || n.contains('rice')) return '$base/1f35b.png';
    if (n.contains('local')) return '$base/1f37d.png';
    return '$base/1f372.png';
  }

  String _hintFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('drink')) return AppStrings.categoryHintDrinks;
    if (n.contains('grill') || n.contains('chicken')) return AppStrings.categoryHintGrills;
    if (n.contains('side')) return AppStrings.categoryHintSides;
    if (n.contains('jollof') || n.contains('rice')) return AppStrings.categoryHintRice;
    return AppStrings.categoryHintDefault;
  }
}
