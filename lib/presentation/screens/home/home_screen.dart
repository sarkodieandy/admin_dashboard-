import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../screens/menu/category_menu_screen.dart';
import '../../screens/menu/menu_item_detail_screen.dart';
import '../../screens/menu/search_screen.dart';
import '../cart/cart_screen.dart';
import '../orders/orders_screen.dart';
import '../../widgets/menu/category_tile.dart';
import '../../widgets/menu/menu_item_card.dart';
import '../../widgets/menu/promo_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routePath = '/app/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final theme = Theme.of(context);
    final cartCount = context.select<CartProvider, int>((c) => c.itemCount);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.appName),
            Text(
              '${AppStrings.restaurantName} • ${AppStrings.restaurantLocation}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.cart,
            onPressed: () => context.push(CartScreen.routePath),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined),
                if (cartCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: theme.colorScheme.surface, width: 2),
                      ),
                      child: Text(
                        cartCount > 9 ? '9+' : '$cartCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.14,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                  BlendMode.softLight,
                ),
                child: AppNetworkImage(
                  url: _backgroundFoodUrl(menu),
                  borderRadius: 0,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.92),
                    theme.colorScheme.surface.withValues(alpha: 0.96),
                    theme.colorScheme.surface,
                  ],
                  stops: const [0.0, 0.32, 1.0],
                ),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () => context.read<MenuProvider>().loadHome(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.x16,
                MediaQuery.paddingOf(context).top + kToolbarHeight + AppSpacing.x12,
                AppSpacing.x16,
                AppSpacing.x16,
              ),
              children: [
                _HomeHero(onSearchTap: () => context.push(SearchScreen.routePath)),
                const SizedBox(height: AppSpacing.x16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) {
                    final fade = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                    final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(fade);
                    return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
                  },
                  child: (menu.homeError != null && menu.promos.isEmpty && !menu.isHomeLoading)
                      ? AppErrorState(
                          key: const ValueKey('promo_error'),
                          title: AppStrings.couldntLoadHomeTitle,
                          body: menu.homeError!,
                          onRetry: () => context.read<MenuProvider>().loadHome(force: true),
                        )
                      : (menu.isHomeLoading && menu.promos.isEmpty)
                          ? const SkeletonBox(
                              key: ValueKey('promo_skeleton'),
                              height: 150,
                              width: double.infinity,
                              radius: AppRadius.r20,
                            )
                          : PromoCarousel(
                              key: ValueKey('promo_${menu.promos.length}'),
                              promos: menu.promos,
                            ),
                ),
                const SizedBox(height: AppSpacing.x20),
                Row(
                  children: [
                    Text(
                      AppStrings.categoriesTitle,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    if (menu.isHomeLoading)
                      Text(
                        AppStrings.loading,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) {
                    final fade = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                    final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(fade);
                    return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
                  },
                  child: (menu.isHomeLoading && menu.categories.isEmpty)
                      ? GridView.count(
                          key: const ValueKey('categories_skeleton'),
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.x12,
                          mainAxisSpacing: AppSpacing.x12,
                          childAspectRatio: 1.35,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            SkeletonBox(height: 120, width: double.infinity),
                            SkeletonBox(height: 120, width: double.infinity),
                            SkeletonBox(height: 120, width: double.infinity),
                            SkeletonBox(height: 120, width: double.infinity),
                          ],
                        )
                      : GridView.builder(
                          key: ValueKey('categories_${menu.categories.length}'),
                          itemCount: menu.categories.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.x12,
                            mainAxisSpacing: AppSpacing.x12,
                            childAspectRatio: 1.35,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final category = menu.categories[index];
                            return CategoryTile(
                              category: category,
                              onTap: () => context.push(CategoryMenuScreen.routePathFor(category.id)),
                            );
                          },
                        ),
                ),
                const SizedBox(height: AppSpacing.x8),
                Row(
                  children: [
                    Text(
                      AppStrings.popularTodayTitle,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    if (menu.popularItems.isNotEmpty)
                      Text(
                        AppStrings.handpicked,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) {
                    final fade = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                    final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(fade);
                    return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
                  },
                  child: (menu.isHomeLoading && menu.popularItems.isEmpty)
                      ? SizedBox(
                          key: const ValueKey('popular_skeleton'),
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 4,
                            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.x12),
                            itemBuilder: (_, _) => const SkeletonBox(height: 200, width: 190),
                          ),
                        )
                      : SizedBox(
                          key: ValueKey('popular_${menu.popularItems.length}'),
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: menu.popularItems.length,
                            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.x12),
                            itemBuilder: (context, index) {
                              final item = menu.popularItems[index];
                              return MenuItemCard(
                                item: item,
                                onTap: () => context.push(MenuItemDetailScreen.routePathFor(item.id)),
                              );
                            },
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.x20),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.x16),
                  onTap: () => context.go(OrdersScreen.routePath),
                  child: Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.r16),
                        ),
                        child: Icon(Icons.history_rounded, color: theme.colorScheme.onSecondaryContainer),
                      ),
                      const SizedBox(width: AppSpacing.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.reorderFromHistory,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: AppSpacing.x6),
                            Text(
                              AppStrings.reorderFromHistoryBody,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _backgroundFoodUrl(MenuProvider menu) {
  for (final item in menu.popularItems) {
    final url = (item.imageUrl ?? '').trim();
    if (url.isNotEmpty) return url;
  }

  return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1600&q=60';
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.32,
              child: AppNetworkImage(
                url:
                    'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1600&q=60',
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
                    theme.colorScheme.surface.withValues(alpha: 0.10),
                    theme.colorScheme.surface.withValues(alpha: 0.86),
                    theme.colorScheme.surface.withValues(alpha: 0.96),
                  ],
                  stops: const [0.0, 0.70, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.80),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      AppStrings.serviceAreaTitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x12),
                  Text(
                    AppStrings.whatAreYouCravingTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  Text(
                    AppStrings.serviceAreaBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: theme.colorScheme.surface.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(AppRadius.r20),
                    child: InkWell(
                      onTap: onSearchTap,
                      borderRadius: BorderRadius.circular(AppRadius.r20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(AppRadius.r20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: AppSpacing.x10),
                            Expanded(
                              child: Text(
                                AppStrings.searchHint,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
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
      ),
    );
  }
}
