import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:finger_licking_customer/domain/entities/chat_message.dart';
import 'package:finger_licking_customer/domain/repositories/chat_repository.dart';
import 'package:finger_licking_customer/presentation/providers/chat_provider.dart';

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({this.sendCompleter});

  final Completer<void>? sendCompleter;

  int sendCalls = 0;

  @override
  Future<String> getOrCreateChatId({required String orderId}) async => 'chat_1';

  @override
  Future<List<ChatMessage>> fetchMessages({required String chatId, required int limit, required int offset}) async {
    return const [];
  }

  @override
  Stream<List<ChatMessage>> watchMessages({required String chatId}) => const Stream.empty();

  @override
  Future<void> sendMessage({required String chatId, required String senderId, required String message}) async {
    sendCalls += 1;
    await (sendCompleter?.future ?? Future<void>.value());
  }
}

void main() {
  test('ChatProvider does not double-send while sending', () async {
    final sendCompleter = Completer<void>();
    final repo = _FakeChatRepository(sendCompleter: sendCompleter);
    final provider = ChatProvider(repository: repo, orderId: 'order_1', userId: 'user_1');
    addTearDown(provider.dispose);

    // Allow _init() to run.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final first = provider.send('hello');
    final second = provider.send('world');

    expect(await second, isFalse);
    expect(repo.sendCalls, 1);

    sendCompleter.complete();
    expect(await first, isTrue);
    expect(repo.sendCalls, 1);
  });
}

