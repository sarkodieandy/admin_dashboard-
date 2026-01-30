import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../orders/orders_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  static const routePath = '/app/chat';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.x16),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.x16),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                    ),
                    child: Icon(Icons.support_agent_rounded, color: theme.colorScheme.onSecondaryContainer),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Text(
                      'Chat opens per order. Pick an order to message the restaurant.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x16),
            AppEmptyState(
              title: 'No chats yet',
              body: 'When you start a chat from an order, your messages will appear here.',
              icon: Icons.chat_bubble_outline_rounded,
              actionLabel: 'View orders',
              onAction: () => context.go(OrdersScreen.routePath),
            ),
          ],
        ),
      ),
    );
  }
}
