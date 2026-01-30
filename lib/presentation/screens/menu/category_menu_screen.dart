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
import '../../providers/menu_provider.dart';
import '../../widgets/menu/spice_indicator.dart';
import 'menu_item_detail_screen.dart';

class CategoryMenuScreen extends StatefulWidget {
  const CategoryMenuScreen({super.key, required this.categoryId});

  static String routePathFor(String categoryId) => '/app/home/category/$categoryId';

  final String categoryId;

  @override
  State<CategoryMenuScreen> createState() => _CategoryMenuScreenState();
}

class _CategoryMenuScreenState extends State<CategoryMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadCategoryItems(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final theme = Theme.of(context);
    final categoryName = menu.categories
        .where((c) => c.id == widget.categoryId)
        .map((c) => c.name)
        .cast<String?>()
        .firstOrNull;

    final isLoading = menu.isCategoryLoading(widget.categoryId);
    final error = menu.categoryError(widget.categoryId);
    final items = menu.categoryItems(widget.categoryId);

    return Scaffold(
      appBar: AppBar(title: Text(categoryName ?? AppStrings.menuTitle)),
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 240) {
              context.read<MenuProvider>().loadMoreCategoryItems(widget.categoryId);
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () => context.read<MenuProvider>().loadCategoryItems(
                  widget.categoryId,
                  refresh: true,
                ),
            child: Builder(
              builder: (context) {
                if (isLoading && items.isEmpty) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    itemCount: 8,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x12),
                    itemBuilder: (_, _) => Container(
                      height: 84,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                      ),
                    ),
                  );
                }

                if (error != null && items.isEmpty) {
                  return AppErrorState(
                    title: AppStrings.couldntLoadMenuTitle,
                    body: error,
                    onRetry: () => context.read<MenuProvider>().loadCategoryItems(widget.categoryId, refresh: true),
                  );
                }

                if (!isLoading && items.isEmpty) {
                  return const AppEmptyState(
                    title: AppStrings.nothingHereTitle,
                    body: AppStrings.nothingHereBody,
                    icon: Icons.restaurant_menu_rounded,
                  );
                }

                final isLoadingMore = menu.isCategoryLoadingMore(widget.categoryId);
                final showBottomLoader = isLoadingMore || menu.categoryHasMore(widget.categoryId);

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    itemCount: items.length + (showBottomLoader ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x12),
                    itemBuilder: (context, index) {
                      if (index >= items.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x12),
                        child: Center(
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }

                    final item = items[index];
                    return InkWell(
                      onTap: () => context.push(MenuItemDetailScreen.routePathFor(item.id)),
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                      child: Ink(
                        padding: const EdgeInsets.all(AppSpacing.x12),
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
                        child: Row(
                          children: [
                            AppNetworkImage(
                              url: item.imageUrl,
                              height: 66,
                              width: 66,
                              borderRadius: AppRadius.r14,
                            ),
                            const SizedBox(width: AppSpacing.x12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      if (item.isSoldOut)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.errorContainer,
                                            borderRadius: BorderRadius.circular(AppRadius.pill),
                                          ),
                                          child: Text(
                                            AppStrings.soldOut,
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: theme.colorScheme.onErrorContainer,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if ((item.description ?? '').trim().isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.x6),
                                    Text(
                                      item.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.x10),
                                  Row(
                                    children: [
                                      Text(
                                        Money.format(item.basePrice),
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.x12),
                                      SpiceIndicator(level: item.spiceLevel, compact: true),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
