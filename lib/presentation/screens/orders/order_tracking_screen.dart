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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Order tracking'),
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.go(OrdersScreen.routePath);
              },
            ),
            actions: [
              IconButton(
                tooltip: 'Chat',
                onPressed: order == null ? null : () => context.push(OrderChatScreen.routePathFor(order.id)),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
              ),
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
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                          ),
                          child: Text(
                            cartCount > 9 ? '9+' : '$cartCount',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
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
          body: SafeArea(
            child: order == null
                ? const AppEmptyState(
                    title: 'Order not found',
                    body: 'If you just placed it, give us a second to sync.',
                    icon: Icons.receipt_long_outlined,
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    children: [
                      _StatusHeader(order: order),
                      const SizedBox(height: AppSpacing.x12),
                      StreamBuilder<List<OrderStatusEvent>>(
                        stream: repo.watchOrderStatusEvents(orderId: orderId),
                        builder: (context, eventsSnap) {
                          final events = eventsSnap.data ?? const [];
                          return _Timeline(order: order, events: events);
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
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          return _ItemsCard(order: order, items: items);
                        },
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('EEE, MMM d • HH:mm');
    final when = order.scheduledFor ?? order.createdAt;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headline(order.status),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          Text(
            _subhead(order.status),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  order.scheduledFor == null ? 'Placed ${fmt.format(when)}' : 'Scheduled ${fmt.format(when)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Text(
                  Money.format(order.total),
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _headline(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Your food is being prepared 🍲';
      case OrderStatus.ready:
        return 'Ready for pickup';
      case OrderStatus.enRoute:
        return 'Rider is on the way 🛵';
      case OrderStatus.delivered:
        return 'Delivered — enjoy!';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _subhead(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'We’ve received your order. Hang tight — we’ll confirm soon.';
      case OrderStatus.confirmed:
        return 'Kitchen is getting started. We’ll keep you updated.';
      case OrderStatus.preparing:
        return 'Everything is cooking fresh. You’ll get a ping when it’s ready.';
      case OrderStatus.ready:
        return 'Packed and ready. Dispatch is next.';
      case OrderStatus.enRoute:
        return 'Almost there. Keep your phone close just in case.';
      case OrderStatus.delivered:
        return 'Thanks for ordering Finger Licking — Bekwai.';
      case OrderStatus.cancelled:
        return 'If this was unexpected, chat us and we’ll help.';
    }
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order, required this.events});

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
            'Progress',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
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
            Column(
              children: [
                for (int i = 0; i < steps.length; i++) ...[
                  _TimelineRow(
                    status: steps[i],
                    isDone: i <= currentIndex,
                    isCurrent: i == currentIndex,
                    timestamp: events.where((e) => e.status == steps[i]).cast<OrderStatusEvent?>().firstOrNull?.createdAt,
                  ),
                  if (i != steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Container(
                        height: 14,
                        width: 2,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.status,
    required this.isDone,
    required this.isCurrent,
    required this.timestamp,
  });

  final OrderStatus status;
  final bool isDone;
  final bool isCurrent;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('HH:mm');
    final color = isDone ? theme.colorScheme.primary : theme.colorScheme.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: isDone ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(
            isDone ? Icons.check_rounded : Icons.circle_outlined,
            size: 16,
            color: isDone ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.x12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _label(status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                  height: 1.15,
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: AppSpacing.x4),
                Text(
                  fmt.format(timestamp!),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _label(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.enRoute:
        return 'En route';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
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
          Text(
            'Order details',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.x12),
          for (final it in items) ...[
            Row(
              children: [
                Text(
                  '${it.qty}×',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it.nameSnapshot,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
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
                          it.addonsSnapshot.map((a) => a['name']).whereType<String>().join(', '),
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
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
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
            _MiniRow(label: 'Discount', value: '- ${Money.format(order.discount)}'),
          ],
          if (order.tip > 0) ...[
            const SizedBox(height: AppSpacing.x6),
            _MiniRow(label: 'Tip', value: Money.format(order.tip)),
          ],
          const SizedBox(height: AppSpacing.x10),
          _MiniRow(label: 'Total', value: Money.format(order.total), emphasis: true),
          const SizedBox(height: AppSpacing.x12),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: Text(
                  [addressLine, if (landmark.isNotEmpty) 'Landmark: $landmark']
                      .where((e) => e.trim().isNotEmpty)
                      .join(' • '),
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
                    onPressed: () => context.push(OrderReviewScreen.routePathFor(order.id)),
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
            : menuItem.variants.where((v) => v.name.trim().toLowerCase() == variantName).firstOrNull;

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
        : theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

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
