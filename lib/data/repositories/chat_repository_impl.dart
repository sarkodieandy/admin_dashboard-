import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_supabase_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._datasource);

  final ChatSupabaseDatasource _datasource;

  @override
  Future<String> getOrCreateChatId({required String orderId}) async {
    final existing = await _datasource.fetchChatId(orderId: orderId);
    if (existing != null) return existing;
    return _datasource.createChat(orderId: orderId);
  }

  @override
  Future<List<ChatMessage>> fetchMessages({
    required String chatId,
    required int limit,
    required int offset,
  }) async {
    final models = await _datasource.fetchMessages(chatId: chatId, limit: limit, offset: offset);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<ChatMessage>> watchMessages({required String chatId}) {
    return _datasource
        .watchMessages(chatId: chatId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
  }) {
    return _datasource.sendMessage(chatId: chatId, senderId: senderId, message: message);
  }
}

