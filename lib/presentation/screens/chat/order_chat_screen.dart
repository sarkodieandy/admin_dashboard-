import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class OrderChatScreen extends StatelessWidget {
  const OrderChatScreen({super.key, required this.orderId});

  static const routePath = '/order/:orderId/chat';
  static String routePathFor(String orderId) => '/order/$orderId/chat';

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: AppEmptyState(
          title: 'Sign in to chat',
          body: 'Log in (or continue as guest) to message the restaurant.',
          icon: Icons.chat_bubble_outline_rounded,
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => ChatProvider(
        repository: context.read<ChatRepository>(),
        orderId: orderId,
        userId: user.id,
      ),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final raw = _controller.text;
    final text = raw.trim();
    if (text.isEmpty) return;

    final ok = await context.read<ChatProvider>().send(text);
    if (!mounted) return;
    if (ok) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          if (provider.chatId != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.x12),
              child: Center(
                child: Text(
                  'Reply time: ~2–5 mins',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }

                  if (provider.error != null && provider.messages.isEmpty) {
                    return AppErrorState(
                      title: AppStrings.somethingWentWrong,
                      body: provider.error!,
                    );
                  }

                  if (provider.messages.isEmpty) {
                    return const AppEmptyState(
                      title: 'Say hello 👋',
                      body: 'Need to change a note or ask a quick question? Message the restaurant here.',
                      icon: Icons.chat_bubble_outline_rounded,
                    );
                  }

                  final messages = provider.messages;

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.x16, AppSpacing.x12, AppSpacing.x16, AppSpacing.x12),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[messages.length - 1 - index];
                      final isMe = msg.senderId == provider.userId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(AppRadius.r16),
                                  topRight: const Radius.circular(AppRadius.r16),
                                  bottomLeft: Radius.circular(isMe ? AppRadius.r16 : AppRadius.r8),
                                  bottomRight: Radius.circular(isMe ? AppRadius.r8 : AppRadius.r16),
                                ),
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                              ),
                              child: Text(
                                msg.message,
                                style: theme.textTheme.bodyMedium?.copyWith(height: 1.25),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if ((provider.error ?? '').trim().isNotEmpty && provider.messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.x16, 0, AppSpacing.x16, AppSpacing.x10),
                child: Text(
                  provider.error!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.x16, 0, AppSpacing.x16, AppSpacing.x16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(hintText: 'Type a message…'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x12),
                    SizedBox(
                      height: 52,
                      width: 52,
                      child: FilledButton(
                        onPressed: provider.isSending ? null : _send,
                        child: provider.isSending
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
