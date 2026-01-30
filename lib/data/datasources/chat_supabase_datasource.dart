import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message_model.dart';

class ChatSupabaseDatasource {
  ChatSupabaseDatasource(this._client);

  final SupabaseClient _client;

  Future<String?> fetchChatId({required String orderId}) async {
    final data = await _client.from('chats').select('id').eq('order_id', orderId).limit(1);
    final list = (data as List).whereType<Map<String, dynamic>>().toList();
    if (list.isEmpty) return null;
    return list.first['id'] as String?;
  }

  Future<String> createChat({required String orderId}) async {
    final data = await _client.from('chats').insert({'order_id': orderId}).select('id').single();
    return data['id'] as String;
  }

  Future<List<ChatMessageModel>> fetchMessages({
    required String chatId,
    required int limit,
    required int offset,
  }) async {
    final data = await _client
        .from('chat_messages')
        .select('id,chat_id,sender_id,message,created_at')
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);

    return (data as List).whereType<Map<String, dynamic>>().map(ChatMessageModel.fromJson).toList();
  }

  Stream<List<ChatMessageModel>> watchMessages({required String chatId}) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .order('id', ascending: true)
        .map(
          (rows) => rows.whereType<Map<String, dynamic>>().map(ChatMessageModel.fromJson).toList(),
        );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
  }) async {
    await _client.from('chat_messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'message': message,
    });
  }
}
