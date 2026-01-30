import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/order_item.dart';
import '../../../domain/entities/order_status_event.dart';
import '../../../domain/entities/item_addon.dart';
import '../../../domain/repositories/menu_repository.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../chat/order_chat_screen.dart';
import '../reviews/order_review_screen.dart';
import 'orders_screen.dart';
import '../../design_system/app_components.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  static const routePath = '/order/:orderId';
  static String routePathFor(String orderId) => '/order/$orderId';

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<OrderRepository>();
    final cartCount = context.select<CartProvider, int>((c) => c.itemCount);

    return StreamBuilder<Order?>(
      stream: repo.watchOrder(orderId: orderId),
      builder: (context, snapshot) {
        final order = snapshot.data;
        final theme = Theme.of(context);

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: SafeArea(
            child: order == null
                ? const AppEmptyState(
                    title: 'Order not found',
                    body: 'If you just placed it, give us a second to sync.',
                    icon: Icons.receipt_long_outlined,
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.25),
                                theme.colorScheme.surface,
                              ],
                              stops: const [0.0, 0.55],
                            ),
                          ),
                        ),
                      ),
                      ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.x16,
                          AppSpacing.x12,
                          AppSpacing.x16,
                          110,
                        ),
                        children: [
                          _TopActionsRow(
                            cartCount: cartCount,
                            onBack: () {
                              if (context.canPop()) {
                                context.pop();
                                return;
                              }
                              context.go(OrdersScreen.routePath);
                            },
                            onChat: () => context.push(
                              OrderChatScreen.routePathFor(order.id),
                            ),
                            onCart: () => context.push(CartScreen.routePath),
                          ),
                          const SizedBox(height: AppSpacing.x12),
                          StaggeredSlideFadeIn(
                            index: 0,
                            child: _TrackingHero(order: order),
                          ),
                          const SizedBox(height: AppSpacing.x12),
                          StaggeredSlideFadeIn(
                            index: 1,
                            child: _DriverCard(order: order),
                          ),
                          const SizedBox(height: AppSpacing.x12),
                          StreamBuilder<List<OrderStatusEvent>>(
                            stream: repo.watchOrderStatusEvents(
                              orderId: orderId,
                            ),
                            builder: (context, eventsSnap) {
                              final events = eventsSnap.data ?? const [];
                              return StaggeredSlideFadeIn(
                                index: 2,
                                child: _ProgressCard(
                                  order: order,
                                  events: events,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.x12),
                          FutureBuilder<List<OrderItem>>(
                            future: repo.fetchOrderItems(orderId: orderId),
                            builder: (context, itemsSnap) {
                              if (itemsSnap.hasError) {
                                return AppErrorState(
                                  title: AppStrings.somethingWentWrong,
                                  body: itemsSnap.error.toString(),
                                );
                              }
                              final items = itemsSnap.data;
                              if (items == null) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppSpacing.x16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              return _DetailsExpandable(
                                order: order,
                                items: items,
                              );
                            },
                          ),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _BottomActions(
                          order: order,
                          onContact: () => context.push(
                            OrderChatScreen.routePathFor(order.id),
                          ),
                          onCall: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Calling is coming soon'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order, required this.items});

  final Order order;
  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = order.addressSnapshot;
    final addressLine = (address['address']?.toString() ?? '').trim();
    final landmark = (address['landmark']?.toString() ?? '').trim();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push(OrderChatScreen.routePathFor(order.id)),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Message'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          for (final it in items) ...[
            Row(
              children: [
                Text(
                  '${it.qty}×',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it.nameSnapshot,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((it.variantSnapshot ?? '').trim().isNotEmpty)
                        Text(
                          it.variantSnapshot!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (it.addonsSnapshot.isNotEmpty)
                        Text(
                          it.addonsSnapshot
                              .map((a) => a['name'])
                              .whereType<String>()
                              .join(', '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.x10),
                Text(
                  Money.format(it.total),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x10),
          ],
          const SizedBox(height: AppSpacing.x8),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: AppSpacing.x12),
          _MiniRow(label: 'Subtotal', value: Money.format(order.subtotal)),
          const SizedBox(height: AppSpacing.x6),
          _MiniRow(label: 'Delivery', value: Money.format(order.deliveryFee)),
          if (order.discount > 0) ...[
            const SizedBox(height: AppSpacing.x6),
            _MiniRow(
              label: 'Discount',
              value: '- ${Money.format(order.discount)}',
            ),
          ],
          if (order.tip > 0) ...[
            const SizedBox(height: AppSpacing.x6),
            _MiniRow(label: 'Tip', value: Money.format(order.tip)),
          ],
          const SizedBox(height: AppSpacing.x10),
          _MiniRow(
            label: 'Total',
            value: Money.format(order.total),
            emphasis: true,
          ),
          const SizedBox(height: AppSpacing.x12),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: Text(
                  [
                    addressLine,
                    if (landmark.isNotEmpty) 'Landmark: $landmark',
                  ].where((e) => e.trim().isNotEmpty).join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          if (order.status == OrderStatus.delivered) ...[
            const SizedBox(height: AppSpacing.x16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push(OrderReviewScreen.routePathFor(order.id)),
                    icon: const Icon(Icons.star_border_rounded),
                    label: const Text('Rate'),
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reorder(context),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reorder'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _reorder(BuildContext context) async {
    final menuRepo = context.read<MenuRepository>();
    final cart = context.read<CartProvider>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    int added = 0;
    int skipped = 0;

    for (final it in items) {
      final itemId = it.itemId;
      if (itemId == null) {
        skipped++;
        continue;
      }

      try {
        final menuItem = await menuRepo.fetchMenuItemDetail(itemId: itemId);
        if (menuItem.isSoldOut || !menuItem.isActive) {
          skipped++;
          continue;
        }

        final variantName = (it.variantSnapshot ?? '').trim().toLowerCase();
        final variant = variantName.isEmpty
            ? null
            : menuItem.variants
                  .where((v) => v.name.trim().toLowerCase() == variantName)
                  .firstOrNull;

        final addons = <ItemAddon>[];
        for (final raw in it.addonsSnapshot) {
          final id = raw['id']?.toString();
          if (id == null) continue;
          final addon = menuItem.addons.where((a) => a.id == id).firstOrNull;
          if (addon != null) addons.add(addon);
        }

        await cart.addFromMenuItem(
          item: menuItem,
          qty: it.qty,
          note: '',
          variant: variant,
          addons: addons,
        );
        added++;
      } catch (_) {
        skipped++;
      }
    }

    final msg = added == 0
        ? 'No items could be reordered right now.'
        : skipped == 0
        ? 'Added $added item(s) to your cart.'
        : 'Added $added item(s). Skipped $skipped unavailable item(s).';

    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        action: added == 0
            ? null
            : SnackBarAction(
                label: AppStrings.cart,
                onPressed: () => router.push(CartScreen.routePath),
              ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasis
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)
        : theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _TopActionsRow extends StatelessWidget {
  const _TopActionsRow({
    required this.cartCount,
    required this.onBack,
    required this.onChat,
    required this.onCart,
  });

  final int cartCount;
  final VoidCallback onBack;
  final VoidCallback onChat;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _IconPillButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const Spacer(),
        _IconPillButton(
          tooltip: 'Chat',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: onChat,
        ),
        const SizedBox(width: AppSpacing.x10),
        _IconPillButton(
          tooltip: AppStrings.cart,
          iconWidget: AppBadgeIcon(
            icon: Icons.shopping_bag_outlined,
            count: cartCount,
          ),
          onTap: onCart,
        ),
        const SizedBox(width: 2),
        Icon(
          Icons.more_vert_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _IconPillButton extends StatelessWidget {
  const _IconPillButton({
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.tooltip,
  });

  final VoidCallback onTap;
  final IconData? icon;
  final Widget? iconWidget;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          AppComponents.haptic();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            height: 44,
            width: 44,
            child: Center(
              child:
                  iconWidget ??
                  Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackingHero extends StatelessWidget {
  const _TrackingHero({required this.order});

  final Order order;

  static const _mapUrl =
      'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=1400&q=60';

  // Unsplash photo ID (stable) -> redirects to images.unsplash.com.
  static const _riderUrl = 'https://source.unsplash.com/afDu-GuxjjM/1200x800';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = _headline(order.status);
    final sub = _subhead(order.status);
    final eta = _eta(order.status);

    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.14,
                child: AppNetworkImage(
                  url: _mapUrl,
                  borderRadius: 0,
                  fit: BoxFit.cover,
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
                      theme.colorScheme.surface.withValues(alpha: 0.80),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x16,
                AppSpacing.x16,
                AppSpacing.x16,
                AppSpacing.x14,
              ),
              child: Column(
                children: [
                  Text(
                    'Tracking Order',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      eta,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x10),
                  Expanded(
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) {
                          final slide = (1 - t) * 10;
                          return Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, slide),
                              child: child,
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.r20),
                          child: AppNetworkImage(
                            url: _riderUrl,
                            height: 118,
                            width: 210,
                            borderRadius: 0,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.2,
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

  String _headline(OrderStatus status) {
    return switch (status) {
      OrderStatus.enRoute => 'Your food is on the way!',
      OrderStatus.delivered => 'Delivered to you.',
      OrderStatus.cancelled => 'This order was cancelled.',
      OrderStatus.ready => 'Packed and ready to go.',
      OrderStatus.preparing => 'Cooking fresh in the kitchen.',
      OrderStatus.confirmed => 'Confirmed — we’re getting started.',
      OrderStatus.placed => 'Order received.',
    };
  }

  String _subhead(OrderStatus status) {
    return switch (status) {
      OrderStatus.enRoute => 'Keep your phone close just in case.',
      OrderStatus.delivered => 'Enjoy your meal.',
      OrderStatus.cancelled => 'If this was unexpected, message us.',
      _ => 'We’ll keep you updated as things move.',
    };
  }

  String _eta(OrderStatus status) {
    return switch (status) {
      OrderStatus.enRoute => 'Est. Arrival 10–12 min',
      OrderStatus.ready => 'Est. Arrival 15–25 min',
      OrderStatus.preparing => 'Est. Arrival 25–40 min',
      OrderStatus.confirmed => 'Est. Arrival 30–45 min',
      OrderStatus.placed => 'Est. Arrival 35–50 min',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
    };
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnRoute = order.status == OrderStatus.enRoute;
    final isDelivered = order.status == OrderStatus.delivered;
    final label = isDelivered
        ? 'Delivered'
        : isEnRoute
        ? 'Arriving soon'
        : 'Driver assigned soon';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Icon(
              Icons.delivery_dining_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver: Alex',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Honda Scooter  •  ABC 1234',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.order, required this.events});

  final Order order;
  final List<OrderStatusEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = const [
      OrderStatus.placed,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.enRoute,
      OrderStatus.delivered,
    ];
    final currentIndex = steps.indexWhere((s) => s == order.status);
    final isCancelled = order.status == OrderStatus.cancelled;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracking Order...',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          if (isCancelled)
            Row(
              children: [
                Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: Text(
                    'This order was cancelled.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            )
          else
            _AnimatedProgressStepper(
              steps: steps,
              currentIndex: currentIndex,
              events: events,
              activeColor: theme.colorScheme.secondary,
              lineColor: theme.colorScheme.outlineVariant,
            ),
        ],
      ),
    );
  }
}

class _AnimatedProgressStepper extends StatefulWidget {
  const _AnimatedProgressStepper({
    required this.steps,
    required this.currentIndex,
    required this.events,
    required this.activeColor,
    required this.lineColor,
  });

  final List<OrderStatus> steps;
  final int currentIndex;
  final List<OrderStatusEvent> events;
  final Color activeColor;
  final Color lineColor;

  @override
  State<_AnimatedProgressStepper> createState() => _AnimatedProgressStepperState();
}

class _AnimatedProgressStepperState extends State<_AnimatedProgressStepper> {
  double _prev = 0;

  @override
  void initState() {
    super.initState();
    _prev = _progressFor(widget.currentIndex, widget.steps.length);
  }

  @override
  void didUpdateWidget(covariant _AnimatedProgressStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex || oldWidget.steps.length != widget.steps.length) {
      _prev = _prev.clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = _progressFor(widget.currentIndex, widget.steps.length);
    final begin = _prev;
    final end = next;

    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.currentIndex),
      tween: Tween(begin: begin, end: end),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      onEnd: () {
        _prev = end;
      },
      builder: (context, progress, _) {
        return Column(
          children: [
            for (int i = 0; i < widget.steps.length; i++) ...[
              StaggeredSlideFadeIn(
                index: i,
                baseDelay: const Duration(milliseconds: 30),
                offsetY: 8,
                child: _ProgressRow(
                  index: i,
                  status: widget.steps[i],
                  isDone: i < widget.currentIndex,
                  isCurrent: i == widget.currentIndex,
                  timestamp: widget.events
                      .where((e) => e.status == widget.steps[i])
                      .cast<OrderStatusEvent?>()
                      .firstOrNull
                      ?.createdAt,
                  activeColor: widget.activeColor,
                ),
              ),
              if (i != widget.steps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: SizedBox(
                    height: 16,
                    width: 2,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: widget.lineColor,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: FractionallySizedBox(
                            heightFactor: _segmentFill(progress, i, widget.steps.length),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.activeColor,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  double _progressFor(int currentIndex, int total) {
    if (currentIndex < 0) return 0;
    return ((currentIndex + 1) / total).clamp(0.0, 1.0);
  }

  double _segmentFill(double progress, int segmentIndex, int segmentsTotal) {
    final per = 1 / segmentsTotal;
    final start = segmentIndex * per;
    final end = (segmentIndex + 1) * per;
    if (progress <= start) return 0;
    if (progress >= end) return 1;
    return ((progress - start) / (end - start)).clamp(0.0, 1.0);
  }
}

class _ProgressRow extends StatefulWidget {
  const _ProgressRow({
    required this.index,
    required this.status,
    required this.isDone,
    required this.isCurrent,
    required this.timestamp,
    required this.activeColor,
  });

  final int index;
  final OrderStatus status;
  final bool isDone;
  final bool isCurrent;
  final DateTime? timestamp;
  final Color activeColor;

  @override
  State<_ProgressRow> createState() => _ProgressRowState();
}

class _ProgressRowState extends State<_ProgressRow> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _ProgressRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCurrent != widget.isCurrent) _sync();
  }

  void _sync() {
    if (widget.isCurrent) {
      _pulse ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat(reverse: true);
    } else {
      _pulse?.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('HH:mm');

    final active = widget.activeColor;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: widget.isCurrent ? FontWeight.w900 : FontWeight.w700,
      height: 1.15,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _pulse ?? kAlwaysDismissedAnimation,
          builder: (context, _) {
            final t = _pulse?.value ?? 0;
            final glow = widget.isCurrent ? (0.10 + (t * 0.16)) : 0.0;
            final ringW = widget.isCurrent ? (1.4 + (t * 0.6)) : 1.0;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: widget.isDone
                    ? active.withValues(alpha: 0.14)
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: (widget.isDone || widget.isCurrent) ? active : theme.colorScheme.outlineVariant,
                  width: ringW,
                ),
                boxShadow: widget.isCurrent
                    ? [
                        BoxShadow(
                          color: active.withValues(alpha: glow),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) {
                  final fade = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                  final scale = Tween<double>(begin: 0.88, end: 1).animate(fade);
                  return FadeTransition(opacity: fade, child: ScaleTransition(scale: scale, child: child));
                },
                child: Icon(
                  widget.isDone
                      ? Icons.check_rounded
                      : widget.isCurrent
                          ? Icons.circle
                          : Icons.circle_outlined,
                  key: ValueKey('${widget.isDone}_${widget.isCurrent}'),
                  size: 16,
                  color: widget.isDone || widget.isCurrent
                      ? active
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.40),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: AppSpacing.x12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_label(widget.status), style: textStyle),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: widget.timestamp == null
                    ? const SizedBox.shrink()
                    : Padding(
                        key: ValueKey(widget.timestamp),
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          fmt.format(widget.timestamp!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _label(OrderStatus status) {
    return switch (status) {
      OrderStatus.placed => 'Order received',
      OrderStatus.confirmed => 'Order confirmed',
      OrderStatus.preparing => 'Preparing your order',
      OrderStatus.ready => 'Picked up by rider',
      OrderStatus.enRoute => 'On the way to you',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
    };
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.order,
    required this.onContact,
    required this.onCall,
  });

  final Order order;
  final VoidCallback onContact;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = order.status == OrderStatus.cancelled;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x16,
          0,
          AppSpacing.x16,
          AppSpacing.x14,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: disabled ? null : onContact,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Contact'),
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
                onPressed: disabled ? null : onCall,
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Call'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsExpandable extends StatefulWidget {
  const _DetailsExpandable({required this.order, required this.items});

  final Order order;
  final List<OrderItem> items;

  @override
  State<_DetailsExpandable> createState() => _DetailsExpandableState();
}

class _DetailsExpandableState extends State<_DetailsExpandable> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              AppComponents.haptic();
              setState(() => _open = !_open);
            },
            borderRadius: BorderRadius.circular(AppRadius.r16),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x16,
                0,
                AppSpacing.x16,
                AppSpacing.x16,
              ),
              child: _ItemsCard(order: widget.order, items: widget.items),
            ),
            crossFadeState: _open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}
