import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  static const routePath = '/app/inbox';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inbox = context.watch<NotificationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          if (auth.isSignedIn && inbox.unreadCount > 0)
            TextButton(
              onPressed: () => context.read<NotificationProvider>().markAllAsRead(),
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: !auth.isSignedIn
            ? const AppEmptyState(
                title: 'No notifications',
                body: 'Sign in (or continue as guest) to receive order updates.',
                icon: Icons.notifications_none,
              )
            : Builder(
                builder: (context) {
                  if (inbox.isLoading && inbox.notifications.isEmpty) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }

                  if (inbox.error != null && inbox.notifications.isEmpty) {
                    return AppErrorState(
                      title: 'Couldn’t load inbox',
                      body: inbox.error!,
                    );
                  }

                  if (inbox.notifications.isEmpty) {
                    return const AppEmptyState(
                      title: 'No notifications',
                      body: 'We’ll drop updates here — promos, receipts, and order status changes.',
                      icon: Icons.notifications_none,
                    );
                  }

                  final items = inbox.notifications;
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x12),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return AppCard(
                        onTap: () => context.read<NotificationProvider>().markAsRead(n.id),
                        padding: const EdgeInsets.all(AppSpacing.x14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                color: n.isRead
                                    ? theme.colorScheme.surfaceContainerHighest
                                    : theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(AppRadius.r16),
                              ),
                              child: Icon(
                                n.isRead ? Icons.notifications_none : Icons.notifications_rounded,
                                color: n.isRead
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.onPrimaryContainer,
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
                                          n.title,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: n.isRead ? FontWeight.w800 : FontWeight.w900,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      if (!n.isRead)
                                        Container(
                                          height: 10,
                                          width: 10,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.x6),
                                  Text(
                                    n.body,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
