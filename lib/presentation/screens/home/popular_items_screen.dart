import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/menu_item.dart';
import '../../providers/menu_provider.dart';
import '../../design_system/app_components.dart';
import '../menu/menu_item_detail_screen.dart';

class PopularItemsScreen extends StatefulWidget {
  const PopularItemsScreen({super.key});

  static const routePath = '/app/home/popular';

  @override
  State<PopularItemsScreen> createState() => _PopularItemsScreenState();
}

class _PopularItemsScreenState extends State<PopularItemsScreen> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menu = context.read<MenuProvider>();
      if (menu.popularItems.isEmpty) {
        menu.loadHome(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final theme = Theme.of(context);
    final items = menu.popularItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Popular Items')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<MenuProvider>().loadHome(force: true),
          child: Builder(
            builder: (context) {
              if (menu.isHomeLoading && items.isEmpty) {
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.x16),
                  itemCount: 10,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x12),
                  itemBuilder: (context, index) => Container(
                    height: 92,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                    ),
                  ),
                );
              }

              if ((menu.homeError ?? '').trim().isNotEmpty && items.isEmpty) {
                return AppErrorState(
                  title: AppStrings.somethingWentWrong,
                  body: menu.homeError!,
                  onRetry: () => context.read<MenuProvider>().loadHome(force: true),
                );
              }

              if (items.isEmpty) {
                return const AppEmptyState(
                  title: 'No popular items yet',
                  body: 'Check back soon for today’s best picks.',
                  icon: Icons.local_fire_department_outlined,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.x16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return StaggeredSlideFadeIn(
                    index: index,
                    child: _PopularRow(
                      item: item,
                      onTap: () => context.push(MenuItemDetailScreen.routePathFor(item.id)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PopularRow extends StatelessWidget {
  const _PopularRow({required this.item, required this.onTap});

  final MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PressScale(
      onPressed: onTap,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x12),
            child: Row(
              children: [
                Hero(
                  tag: 'menu_item_image_${item.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.r14),
                    child: AppNetworkImage(
                      url: item.imageUrl,
                      height: 66,
                      width: 66,
                      borderRadius: 0,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '30–40 min • 4.${item.spiceLevel.clamp(0, 9)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Money.format(item.basePrice),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
