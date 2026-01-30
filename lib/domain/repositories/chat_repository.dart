import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<String> getOrCreateChatId({required String orderId});

  Future<List<ChatMessage>> fetchMessages({
    required String chatId,
    required int limit,
    required int offset,
  });

  Stream<List<ChatMessage>> watchMessages({required String chatId});

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
  });
}

