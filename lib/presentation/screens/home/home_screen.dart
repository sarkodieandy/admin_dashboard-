import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../screens/menu/category_menu_screen.dart';
import '../../screens/menu/menu_item_detail_screen.dart';
import '../../screens/menu/search_screen.dart';
import 'popular_items_screen.dart';
import '../cart/cart_screen.dart';
import '../inbox/inbox_screen.dart';
import '../../design_system/app_components.dart';
import '../../widgets/menu/category_tile.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/menu/promo_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routePath = '/app/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _didLoad = false;
  String? _selectedCategoryId;
  _HomeFilters _filters = const _HomeFilters();
  late final ScrollController _scrollController;
  final ValueNotifier<double> _scrollY = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollY.value = _scrollController.offset;
      });
  }

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
  void dispose() {
    _scrollController.dispose();
    _scrollY.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final theme = Theme.of(context);
    final cartCount = context.select<CartProvider, int>((c) => c.itemCount);
    final unread = context.select<NotificationProvider, int>(
      (p) => p.unreadCount,
    );
    final filteredPopular = _filters.apply(menu.popularItems);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        titleSpacing: 12,
        title: _DeliveryTitle(
          location: AppStrings.restaurantLocation,
          onTap: () {
            AppComponents.haptic();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Delivery location coming soon')),
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.search,
            onPressed: () => context.push(SearchScreen.routePath),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: AppStrings.inbox,
            onPressed: () => context.push(InboxScreen.routePath),
            icon: AppBadgeIcon(
              icon: Icons.notifications_none_rounded,
              count: unread,
            ),
          ),
          IconButton(
            tooltip: AppStrings.cart,
            onPressed: () => context.push(CartScreen.routePath),
            icon: AppBadgeIcon(
              icon: Icons.shopping_cart_outlined,
              count: cartCount,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<MenuProvider>().loadHome(force: true),
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x16,
            AppSpacing.x12,
            AppSpacing.x16,
            AppSpacing.x16,
          ),
          children: [
            StaggeredSlideFadeIn(
              index: 0,
              child: _HomeSearchBar(
                onTapSearch: () {
                  AppComponents.haptic();
                  context.push(SearchScreen.routePath);
                },
                onTapFilter: () {
                  AppComponents.haptic();
                  _openFiltersSheet(
                    context,
                    popularItems: menu.popularItems,
                    current: _filters,
                    onChanged: (next) => setState(() => _filters = next),
                  );
                },
                hasActiveFilters: _filters.isActive,
              ),
            ),
            const SizedBox(height: AppSpacing.x14),
            StaggeredSlideFadeIn(
              index: 1,
              child: _CategoryChips(
                isLoading: menu.isHomeLoading && menu.categories.isEmpty,
                categories: menu.categories,
                selectedId: _selectedCategoryId,
                onTap: (id) {
                  setState(() => _selectedCategoryId = id);
                  AppComponents.haptic();
                  context.push(CategoryMenuScreen.routePathFor(id));
                },
              ),
            ),
            const SizedBox(height: AppSpacing.x14),
            ValueListenableBuilder<double>(
              valueListenable: _scrollY,
              builder: (context, y, _) {
                final p = (y / 600).clamp(0.0, 1.0);
                return StaggeredSlideFadeIn(
                  index: 2,
                  beginScale: 0.975,
                  child: _HomeHeroCard(
                    bgUrl: _backgroundFoodUrl(menu),
                    parallax: p,
                    onBrowse: () {
                      AppComponents.haptic();
                      context.push(SearchScreen.routePath);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.x14),
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
                      key: const ValueKey('flash_error'),
                      title: 'Couldn’t load flash sales',
                      body: menu.homeError!,
                      onRetry: () => context.read<MenuProvider>().loadHome(force: true),
                    )
                  : (menu.isHomeLoading && menu.promos.isEmpty)
                      ? const SkeletonBox(
                          key: ValueKey('flash_skeleton'),
                          height: 150,
                          width: double.infinity,
                          radius: AppRadius.r20,
                        )
                      : StaggeredSlideFadeIn(
                          key: ValueKey('flash_${menu.promos.length}'),
                          index: 3,
                          child: PromoCarousel(promos: menu.promos),
                        ),
            ),
            const SizedBox(height: AppSpacing.x20),
            if (menu.homeError != null &&
                menu.categories.isEmpty &&
                menu.popularItems.isEmpty &&
                !menu.isHomeLoading)
              AppErrorState(
                title: AppStrings.couldntLoadHomeTitle,
                body: menu.homeError!,
                onRetry: () =>
                    context.read<MenuProvider>().loadHome(force: true),
              ),
            if (menu.homeError == null ||
                menu.popularItems.isNotEmpty ||
                menu.isHomeLoading) ...[
              StaggeredSlideFadeIn(
                index: 3,
                child: SectionHeader(
                  title: 'Popular Items',
                  actionLabel: 'See all',
                  onAction: () => context.push(PopularItemsScreen.routePath),
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) {
                  final fade = CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutCubic,
                  );
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(fade);
                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: (menu.isHomeLoading && menu.popularItems.isEmpty)
                    ? GridView.count(
                        key: const ValueKey('popular_skeleton'),
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.x12,
                        mainAxisSpacing: AppSpacing.x12,
                        childAspectRatio: 0.72,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: const [
                          SkeletonBox(height: 240, width: double.infinity),
                          SkeletonBox(height: 240, width: double.infinity),
                          SkeletonBox(height: 240, width: double.infinity),
                          SkeletonBox(height: 240, width: double.infinity),
                        ],
                      )
                    : filteredPopular.isEmpty
                    ? Container(
                        key: const ValueKey('popular_empty'),
                        padding: const EdgeInsets.all(AppSpacing.x16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.r16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_alt_off_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.x12),
                            Expanded(
                              child: Text(
                                'No items match your filters.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(
                                () => _filters = const _HomeFilters(),
                              ),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        key: ValueKey(
                          'popular_${filteredPopular.length}_${_filters.hashCode}',
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredPopular.take(4).length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppSpacing.x12,
                              mainAxisSpacing: AppSpacing.x12,
                              childAspectRatio: 0.72,
                            ),
                        itemBuilder: (context, index) {
                          final item = filteredPopular[index];
                          return StaggeredSlideFadeIn(
                            index: index,
                            child: _RecommendedCard(
                              item: item,
                              onTap: () => context.push(
                                MenuItemDetailScreen.routePathFor(item.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
            const SizedBox(height: AppSpacing.x8),
          ],
        ),
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

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.item, required this.onTap});

  final MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final isTight = constraints.maxHeight < 238 || textScale > 1.15;
        final imageH = isTight ? 104.0 : 116.0;
        final buttonSize = isTight ? 34.0 : 36.0;

        return PressScale(
          child: InkWell(
            onTap: () {
              AppComponents.haptic();
              onTap();
            },
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'menu_item_image_${item.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                      child: AppNetworkImage(
                        url: item.imageUrl,
                        height: imageH,
                        width: double.infinity,
                        borderRadius: 0,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x12),
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
                          if (!isTight) ...[
                            const SizedBox(height: 4),
                            Text(
                              '30–40 min',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.1,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4.${(item.spiceLevel.clamp(0, 9))}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x10),
                          Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    Money.format(item.basePrice),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: buttonSize,
                                width: buttonSize,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    backgroundColor: theme.colorScheme.secondary,
                                    foregroundColor: theme.colorScheme.onSecondary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.r12),
                                    ),
                                  ),
                                  onPressed: onTap,
                                  child: const Icon(Icons.add_rounded, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.isLoading,
    required this.categories,
    required this.selectedId,
    required this.onTap,
  });

  final bool isLoading;
  final List<Category> categories;
  final String? selectedId;
  final void Function(String categoryId) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) =>
              const SkeletonBox(height: 44, width: 110, radius: AppRadius.pill),
        ),
      );
    }

    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final c = categories[index];
          final id = c.id;
          final name = c.name;
          final img = categoryImageUrlFor(name);
          final selected = id == selectedId;

          return StaggeredSlideFadeIn(
            index: index,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: ShapeDecoration(
                color: selected
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.surface,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                shape: const StadiumBorder(),
                child: InkWell(
                  onTap: () => onTap(id),
                  customBorder: const StadiumBorder(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: AppNetworkImage(
                            url: img,
                            height: 24,
                            width: 24,
                            borderRadius: 0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          name,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.1,
                            color: selected
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeliveryTitle extends StatelessWidget {
  const _DeliveryTitle({required this.location, required this.onTap});

  final String location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Deliver to $location',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar({
    required this.onTapSearch,
    required this.onTapFilter,
    required this.hasActiveFilters,
  });

  final VoidCallback onTapSearch;
  final VoidCallback onTapFilter;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              onTap: onTapSearch,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search for dishes, drinks…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x12),
        _FilterButton(onTap: onTapFilter, showDot: hasActiveFilters),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap, required this.showDot});

  final VoidCallback onTap;
  final bool showDot;

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
          child: SizedBox(
            height: 44,
            width: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    Icons.tune_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (showDot)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      builder: (context, s, _) {
                        return Transform.scale(
                          scale: s,
                          child: Container(
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.bgUrl,
    required this.onBrowse,
    required this.parallax,
  });

  final String bgUrl;
  final VoidCallback onBrowse;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.65),
            theme.colorScheme.surfaceContainerHighest,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.18,
                child: Transform.translate(
                  offset: Offset(0, parallax * 12),
                  child: AppNetworkImage(
                    url: bgUrl,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                  final isTight =
                      constraints.maxWidth < 340 || textScale > 1.15;
                  final imageSize = isTight ? 92.0 : 110.0;

                  final title = Text(
                    'Delicious Meals\nDelivered to You',
                    maxLines: isTight ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      height: 1.05,
                    ),
                  );

                  final button = SizedBox(
                    height: 38,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      onPressed: onBrowse,
                      child: const Text('Browse Menu'),
                    ),
                  );

                  final image = ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                    child: AppNetworkImage(
                      url: bgUrl,
                      height: imageSize,
                      width: imageSize,
                      borderRadius: 0,
                      fit: BoxFit.cover,
                    ),
                  );

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            title,
                            const SizedBox(height: AppSpacing.x12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: button,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x12),
                      if (!isTight)
                        image
                      else
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: image,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _HomeSort { recommended, priceLowHigh, priceHighLow }

enum _SpiceFilter { any, mild, pepper, hot }

class _HomeFilters {
  const _HomeFilters({
    this.sort = _HomeSort.recommended,
    this.spice = _SpiceFilter.any,
    this.priceMin,
    this.priceMax,
    this.includeSoldOut = false,
  });

  final _HomeSort sort;
  final _SpiceFilter spice;
  final double? priceMin;
  final double? priceMax;
  final bool includeSoldOut;

  bool get isActive =>
      sort != _HomeSort.recommended ||
      spice != _SpiceFilter.any ||
      includeSoldOut ||
      priceMin != null ||
      priceMax != null;

  _HomeFilters copyWith({
    _HomeSort? sort,
    _SpiceFilter? spice,
    double? priceMin,
    double? priceMax,
    bool? includeSoldOut,
    bool clearPrice = false,
  }) {
    return _HomeFilters(
      sort: sort ?? this.sort,
      spice: spice ?? this.spice,
      includeSoldOut: includeSoldOut ?? this.includeSoldOut,
      priceMin: clearPrice ? null : (priceMin ?? this.priceMin),
      priceMax: clearPrice ? null : (priceMax ?? this.priceMax),
    );
  }

  List<MenuItem> apply(List<MenuItem> items) {
    Iterable<MenuItem> out = items;
    out = out.where((i) => i.isActive);
    if (!includeSoldOut) out = out.where((i) => !i.isSoldOut);

    if (spice != _SpiceFilter.any) {
      out = out.where((i) {
        final s = i.spiceLevel;
        return switch (spice) {
          _SpiceFilter.mild => s <= 3,
          _SpiceFilter.pepper => s >= 4 && s <= 6,
          _SpiceFilter.hot => s >= 7,
          _SpiceFilter.any => true,
        };
      });
    }

    final min = priceMin;
    final max = priceMax;
    if (min != null) out = out.where((i) => i.basePrice >= min);
    if (max != null) out = out.where((i) => i.basePrice <= max);

    final list = out.toList();
    switch (sort) {
      case _HomeSort.recommended:
        return list;
      case _HomeSort.priceLowHigh:
        list.sort((a, b) => a.basePrice.compareTo(b.basePrice));
        return list;
      case _HomeSort.priceHighLow:
        list.sort((a, b) => b.basePrice.compareTo(a.basePrice));
        return list;
    }
  }
}

Future<void> _openFiltersSheet(
  BuildContext context, {
  required List<MenuItem> popularItems,
  required _HomeFilters current,
  required ValueChanged<_HomeFilters> onChanged,
}) async {
  final theme = Theme.of(context);
  final prices =
      popularItems.map((e) => e.basePrice).where((p) => p.isFinite).toList()
        ..sort();
  final min = prices.isEmpty ? 0.0 : prices.first;
  final max = prices.isEmpty ? 200.0 : prices.last;
  final initialMin = (current.priceMin ?? min).clamp(min, max);
  final initialMax = (current.priceMax ?? max).clamp(min, max);

  var next = current;
  var range = RangeValues(initialMin, initialMax);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          final t = Theme.of(context);
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.x16,
              right: AppSpacing.x16,
              bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.x16,
              top: AppSpacing.x8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filter',
                        style: t.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        AppComponents.haptic();
                        setLocal(() {
                          next = const _HomeFilters();
                          range = RangeValues(min, max);
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x10),
                Text(
                  'Sort',
                  style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ChoiceChip(
                      label: 'Recommended',
                      selected: next.sort == _HomeSort.recommended,
                      onTap: () => setLocal(
                        () => next = next.copyWith(sort: _HomeSort.recommended),
                      ),
                    ),
                    _ChoiceChip(
                      label: 'Price: Low → High',
                      selected: next.sort == _HomeSort.priceLowHigh,
                      onTap: () => setLocal(
                        () =>
                            next = next.copyWith(sort: _HomeSort.priceLowHigh),
                      ),
                    ),
                    _ChoiceChip(
                      label: 'Price: High → Low',
                      selected: next.sort == _HomeSort.priceHighLow,
                      onTap: () => setLocal(
                        () =>
                            next = next.copyWith(sort: _HomeSort.priceHighLow),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x16),
                Text(
                  'Spice',
                  style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ChoiceChip(
                      label: 'Any',
                      selected: next.spice == _SpiceFilter.any,
                      onTap: () => setLocal(
                        () => next = next.copyWith(spice: _SpiceFilter.any),
                      ),
                    ),
                    _ChoiceChip(
                      label: 'Mild',
                      selected: next.spice == _SpiceFilter.mild,
                      onTap: () => setLocal(
                        () => next = next.copyWith(spice: _SpiceFilter.mild),
                      ),
                    ),
                    _ChoiceChip(
                      label: 'Pepper',
                      selected: next.spice == _SpiceFilter.pepper,
                      onTap: () => setLocal(
                        () => next = next.copyWith(spice: _SpiceFilter.pepper),
                      ),
                    ),
                    _ChoiceChip(
                      label: 'Hot',
                      selected: next.spice == _SpiceFilter.hot,
                      onTap: () => setLocal(
                        () => next = next.copyWith(spice: _SpiceFilter.hot),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Price range',
                        style: t.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${Money.format(range.start)} – ${Money.format(range.end)}',
                      style: t.textTheme.bodySmall?.copyWith(
                        color: t.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: range,
                  min: min,
                  max: max == min ? (min + 1) : max,
                  divisions: 20,
                  onChanged: (v) {
                    setLocal(() {
                      range = v;
                      next = next.copyWith(priceMin: v.start, priceMax: v.end);
                    });
                  },
                ),
                SwitchListTile.adaptive(
                  value: next.includeSoldOut,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) =>
                      setLocal(() => next = next.copyWith(includeSoldOut: v)),
                  title: const Text('Include sold out'),
                ),
                const SizedBox(height: AppSpacing.x10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          AppComponents.haptic();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          AppComponents.haptic();
                          onChanged(next);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () {
          AppComponents.haptic();
          onTap();
        },
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.1,
              color: selected
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
