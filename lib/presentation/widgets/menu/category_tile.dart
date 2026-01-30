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
    final imageUrl = _imageUrlFor(category.name);
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
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        url: imageUrl,
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.00),
                              Colors.black.withValues(alpha: 0.18),
                            ],
                          ),
                        ),
                      ),
                    ],
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

  String _imageUrlFor(String name) {
    final n = name.toLowerCase();
    // Real photos for a nicer UI (stable, cached by the CDN).
    // Note: Keep these lightweight (w=256) since they are used as small thumbnails.
    if (n.contains('drink')) {
      return 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=256&q=80';
    }
    if (n.contains('dessert')) {
      return 'https://images.unsplash.com/photo-1505253216365-03599a2dc57b?auto=format&fit=crop&w=256&q=80';
    }
    if (n.contains('wrap') || n.contains('shawarma')) {
      return 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=256&q=80';
    }
    if (n.contains('swallow') || n.contains('soup')) {
      return 'https://images.unsplash.com/photo-1604908176997-125f25cc500f?auto=format&fit=crop&w=256&q=80';
    }
    if (n.contains('grill') || n.contains('chicken')) {
      return 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=256&q=80';
    }
    if (n.contains('side')) {
      return 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=256&q=80';
    }
    if (n.contains('jollof') || n.contains('rice')) {
      return 'https://images.unsplash.com/photo-1604908554100-279b9fba6c14?auto=format&fit=crop&w=256&q=80';
    }
    if (n.contains('local')) {
      return 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=256&q=80';
    }
    return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=256&q=80';
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
