import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/menu/menu_item_card.dart';
import '../../widgets/menu/spice_indicator.dart';
import '../cart/cart_screen.dart';
import '../../design_system/app_components.dart';

class MenuItemDetailScreen extends StatefulWidget {
  const MenuItemDetailScreen({super.key, required this.itemId});

  static String routePathFor(String itemId) => '/app/home/item/$itemId';

  final String itemId;

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  String? _variantId;
  final Set<String> _addonIds = {};
  final _note = TextEditingController();
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadItemDetail(widget.itemId);
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final theme = Theme.of(context);

    final item = menu.itemDetail(widget.itemId);
    final isLoading = menu.isItemDetailLoading(widget.itemId);
    final error = menu.itemDetailError(widget.itemId);

    if (item == null && isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: Column(
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.r20),
                  ),
                ),
                const SizedBox(height: AppSpacing.x16),
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                ),
                const SizedBox(height: AppSpacing.x10),
                Container(
                  height: 18,
                  width: 220,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (item == null && error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: AppErrorState(
          title: AppStrings.couldntLoadItemTitle,
          body: error,
          onRetry: () =>
              context.read<MenuProvider>().loadItemDetail(widget.itemId),
        ),
      );
    }

    if (item == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final images = item.images;
    final selectedVariant = item.variants.isEmpty
        ? null
        : item.variants.firstWhere(
            (v) => v.id == _variantId,
            orElse: () => item.variants.first,
          );

    _variantId ??= selectedVariant?.id;

    final addonsTotal = item.addons
        .where((a) => _addonIds.contains(a.id))
        .fold<double>(0, (sum, a) => sum + a.price);
    final variantDelta = selectedVariant?.priceDelta ?? 0;
    final unitPrice = item.basePrice + variantDelta + addonsTotal;
    final total = unitPrice * _qty;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          if (item.isSoldOut)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.x12),
              child: Center(
                child: Chip(
                  label: const Text(AppStrings.soldOut),
                  backgroundColor: theme.colorScheme.errorContainer,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.x16),
          children: [
            Hero(
              tag: 'menu_item_image_${item.id}',
              child: _ImageCarousel(
                images: images.map((e) => e.imageUrl).toList(),
                fallbackUrl: item.imageUrl,
              ),
            ),
            const SizedBox(height: AppSpacing.x16),
            Text(
              item.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.x8),
            Row(
              children: [
                Text(
                  Money.format(item.basePrice),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                SpiceIndicator(level: item.spiceLevel),
              ],
            ),
            if ((item.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x12),
              Text(
                item.description!,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
              ),
            ],
            if (item.variants.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x20),
              Text(
                AppStrings.chooseSize,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final v in item.variants)
                    ChoiceChip(
                      selected: v.id == _variantId,
                      onSelected: item.isSoldOut
                          ? null
                          : (_) => setState(() => _variantId = v.id),
                      label: Text(
                        v.priceDelta == 0
                            ? v.name
                            : AppStrings.withPriceDelta(
                                label: v.name,
                                delta: Money.format(v.priceDelta),
                              ),
                      ),
                    ),
                ],
              ),
            ],
            if (item.addons.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x20),
              Text(
                AppStrings.extras,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              for (final a in item.addons)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.x10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: CheckboxListTile(
                    value: _addonIds.contains(a.id),
                    onChanged: item.isSoldOut
                        ? null
                        : (v) {
                            setState(() {
                              if (v == true) {
                                _addonIds.add(a.id);
                              } else {
                                _addonIds.remove(a.id);
                              }
                            });
                          },
                    title: Text(
                      a.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      a.price == 0
                          ? AppStrings.free
                          : '+ ${Money.format(a.price)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.x20),
            Text(
              AppStrings.anyNotes,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            TextField(
              controller: _note,
              enabled: !item.isSoldOut,
              maxLines: 2,
              decoration: const InputDecoration(hintText: AppStrings.notesHint),
            ),
            const SizedBox(height: AppSpacing.x16),
            Row(
              children: [
                _QtyButton(
                  icon: Icons.remove_rounded,
                  onPressed: item.isSoldOut || _qty <= 1
                      ? null
                      : () => setState(() => _qty--),
                ),
                const SizedBox(width: AppSpacing.x12),
                Text(
                  '$_qty',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                _QtyButton(
                  icon: Icons.add_rounded,
                  onPressed: item.isSoldOut
                      ? null
                      : () => setState(() => _qty++),
                ),
                const Spacer(),
                Expanded(
                  flex: 2,
                  child: PressScale(
                    enabled: !item.isSoldOut,
                    child: ElevatedButton(
                      onPressed: item.isSoldOut
                          ? null
                          : () async {
                              AppComponents.haptic();
                              final selectedAddons = item.addons
                                  .where((a) => _addonIds.contains(a.id))
                                  .toList();
                              await context.read<CartProvider>().addFromMenuItem(
                                item: item,
                                qty: _qty,
                                note: _note.text,
                                variant: selectedVariant,
                                addons: selectedAddons,
                              );

                              if (!context.mounted) return;
                              final messenger = ScaffoldMessenger.of(context);
                              messenger.hideCurrentSnackBar();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Added to cart'),
                                  duration: const Duration(milliseconds: 1200),
                                  action: SnackBarAction(
                                    label: AppStrings.cart,
                                    onPressed: () {
                                      messenger.hideCurrentSnackBar();
                                      context.push(CartScreen.routePath);
                                    },
                                  ),
                                ),
                              );
                            },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        child: Text(
                          '${AppStrings.add} • ${Money.format(total)}',
                          key: ValueKey(total),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x20),
            FutureBuilder(
              future: menu.fetchFrequentlyBoughtTogether(
                itemId: item.id,
                categoryId: item.categoryId,
              ),
              builder: (context, snapshot) {
                final together = snapshot.data ?? const [];
                if (together.isEmpty) return const SizedBox.shrink();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final cardWidth = (availableWidth * 0.6).clamp(
                      160.0,
                      220.0,
                    );
                    final cardHeight = (cardWidth * 1.16).clamp(210.0, 260.0);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.frequentlyBoughtTogether,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x10),
                        SizedBox(
                          height: cardHeight,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: together.length,
                            padding: EdgeInsets.zero,
                            separatorBuilder: (_, index) =>
                                const SizedBox(width: AppSpacing.x12),
                            itemBuilder: (context, index) {
                              final it = together[index];
                              return MenuItemCard(
                                item: it,
                                onTap: () => context.push(
                                  MenuItemDetailScreen.routePathFor(it.id),
                                ),
                                width: cardWidth,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.images, required this.fallbackUrl});

  final List<String> images;
  final String? fallbackUrl;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isNotEmpty
        ? widget.images
        : [
            (widget.fallbackUrl ?? '').trim(),
          ].where((e) => e.isNotEmpty).toList();

    if (images.isEmpty) {
      return AppNetworkImage(
        url: null,
        height: 240,
        width: double.infinity,
        borderRadius: AppRadius.r20,
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r20),
          child: SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, index) {
                return AppNetworkImage(
                  url: images[index],
                  height: 240,
                  width: double.infinity,
                  borderRadius: 0,
                );
              },
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 7,
                      width: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: index == _current ? 0.95 : 0.45,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Ink(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface),
      ),
    );
  }
}
