import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../orders/order_tracking_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static const routePath = '/app/chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Map<String, DateTime> _lastSeen = {};

  void _markSeen(String orderId, DateTime? at) {
    if (at == null) return;
    final prev = _lastSeen[orderId];
    if (prev == null || at.isAfter(prev)) {
      setState(() {
        _lastSeen[orderId] = at;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ordersProvider = context.watch<OrderProvider>();
    final router = GoRouter.of(context);
    final orders = ordersProvider.orders;
    final theme = Theme.of(context);

    if (!auth.isSignedIn || auth.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.x16),
            child: AppEmptyState(
              title: 'Sign in to chat',
              body: 'Log in (or continue as guest) to message the restaurant.',
              icon: Icons.chat_bubble_outline_rounded,
            ),
          ),
        ),
      );
    }

    final hasOrders = orders.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: hasOrders
            ? ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.x16),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _ChatOrderTile(
                    order: order,
                    userId: auth.user!.id,
                    lastSeen: _lastSeen[order.id],
                    onTap: () {
                      router.push(OrderTrackingScreen.routePathFor(order.id));
                      _markSeen(order.id, DateTime.now());
                    },
                    onReceive: (id, time) => _markSeen(id, time),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.x12),
                itemCount: orders.length,
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x32),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.x20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 42, color: theme.colorScheme.primary),
                        const SizedBox(height: AppSpacing.x12),
                        Text(
                          'No chats yet',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: AppSpacing.x6),
                        Text(
                          'Place an order to start chatting with the restaurant in real time.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ChatOrderTile extends StatefulWidget {
  const _ChatOrderTile({
    required this.order,
    required this.userId,
    required this.lastSeen,
    required this.onTap,
    required this.onReceive,
  });

  final Order order;
  final String userId;
  final DateTime? lastSeen;
  final VoidCallback onTap;
  final void Function(String orderId, DateTime? at) onReceive;

  @override
  State<_ChatOrderTile> createState() => _ChatOrderTileState();
}

class _ChatOrderTileState extends State<_ChatOrderTile> {
  late final Future<String> _chatIdFuture;
  late final ChatRepository _chatRepo;

  @override
  void initState() {
    super.initState();
    _chatRepo = context.read<ChatRepository>();
    _chatIdFuture = _chatRepo.getOrCreateChatId(orderId: widget.order.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<String>(
      future: _chatIdFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: 140, color: theme.colorScheme.surfaceContainer, margin: EdgeInsets.zero),
                      const SizedBox(height: AppSpacing.x6),
                      Container(height: 10, width: 80, color: theme.colorScheme.surfaceContainer),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final chatId = snapshot.data!;
        return StreamBuilder<List<ChatMessage>>(
          stream: _chatRepo.watchMessages(chatId: chatId),
          builder: (context, snap) {
            final lastMessage = snap.data?.isNotEmpty == true ? snap.data!.last : null;
            final subtitle = lastMessage?.message ?? 'Tap to open chat';
            final hasUnread = lastMessage != null &&
                lastMessage.senderId != widget.userId &&
                (widget.lastSeen == null || widget.lastSeen!.isBefore(lastMessage.createdAt));
            // keep parent informed of latest timestamp
            if (lastMessage != null) {
              widget.onReceive(widget.order.id, lastMessage.createdAt);
            }

            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.x16),
              child: InkWell(
                onTap: () {
                  widget.onTap();
                },
                borderRadius: BorderRadius.circular(AppRadius.r20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                      ),
                      child: Icon(Icons.chat_bubble_outline_rounded, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: AppSpacing.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Order #${widget.order.id.substring(0, 8)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                Money.format(widget.order.total),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x6),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
