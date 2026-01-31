import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../domain/entities/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  static const routePath = '/app/orders';

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _didKickoff = false;
  bool _loadMoreArmed = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didKickoff) return;
    _didKickoff = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final orders = context.read<OrderProvider>();
      if (auth.isSignedIn && orders.orders.isEmpty && !orders.isLoading) {
        orders.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          if (auth.isSignedIn)
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => context.read<OrderProvider>().refresh(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: !auth.isSignedIn
            ? const AppEmptyState(
                title: 'No orders yet',
                body: 'Log in (or continue as guest) to place an order and track it live.',
                icon: Icons.receipt_long_outlined,
              )
            : RefreshIndicator(
                onRefresh: () => context.read<OrderProvider>().refresh(),
                child: Builder(
              builder: (context) {
                    if (orders.isLoading && orders.orders.isEmpty) {
                      return ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.x16),
                        itemCount: 6,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x12),
                        itemBuilder: (context, index) => _OrderSkeleton(theme: theme),
                      );
                    }

                    if (orders.error != null && orders.orders.isEmpty) {
                      return AppErrorState(
                        title: 'Couldn’t load orders',
                        body: orders.error!,
                        onRetry: () => context.read<OrderProvider>().refresh(),
                      );
                    }

                    if (!orders.isLoading && orders.orders.isEmpty) {
                      return const AppEmptyState(
                        title: 'No orders yet',
                        body: 'When you place an order, you’ll see updates here in real time.',
                        icon: Icons.receipt_long_outlined,
                      );
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        final m = notification.metrics;
                        final nearBottom = m.pixels >= m.maxScrollExtent - 240;
                        if (nearBottom && _loadMoreArmed) {
                          _loadMoreArmed = false;
                          context.read<OrderProvider>().loadMore();
                        } else if (!nearBottom) {
                          _loadMoreArmed = true;
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.x16),
                        itemCount: orders.orders.length + (orders.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x12),
                        itemBuilder: (context, index) {
                          if (index >= orders.orders.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.x12),
                              child: Center(
                                child: SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          final order = orders.orders[index];
                          return _OrderCard(order: order);
                        },
                      ),
                    );
                  },
                ),
              ),
      ),
      bottomNavigationBar: auth.isSignedIn && orders.orders.isNotEmpty
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.x16, 0, AppSpacing.x16, AppSpacing.x16),
                child: OutlinedButton.icon(
                  onPressed: () => context.push(OrderTrackingScreen.routePathFor(orders.orders.first.id)),
                  icon: const Icon(Icons.timeline_rounded),
                  label: const Text('Track latest order'),
                ),
              ),
            )
          : null,
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  static final DateFormat _dateFmt = DateFormat('EEE, MMM d • HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = _dateFmt.format(order.createdAt.toLocal());
    final status = _statusLabel(order.status);
    final isActive = order.isActive;

    return AppCard(
      onTap: () => context.push(OrderTrackingScreen.routePathFor(order.id)),
      padding: const EdgeInsets.all(AppSpacing.x14),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: isActive ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.r16),
            ),
            child: Icon(
              isActive ? Icons.receipt_long_rounded : Icons.history_rounded,
              color: isActive ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
            ),
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
                        status,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(theme, order.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        _statusChip(order.status),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _statusColor(theme, order.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        date,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      Money.format(order.total),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                if (order.scheduledFor != null) ...[
                  const SizedBox(height: AppSpacing.x6),
                  Text(
                    'Scheduled for ${_dateFmt.format(order.scheduledFor!.toLocal())}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order placed';
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

  String _statusChip(OrderStatus status) {
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

  Color _statusColor(ThemeData theme, OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return theme.colorScheme.secondary;
      case OrderStatus.cancelled:
        return theme.colorScheme.error;
      case OrderStatus.enRoute:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}

class _OrderSkeleton extends StatelessWidget {
  const _OrderSkeleton({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.x14),
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.r16),
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 12,
                    width: 160,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 10,
                    width: 210,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x14),
        ],
      ),
    );
  }
}
