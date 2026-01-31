import 'dart:async';

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
    // Realtime can occasionally be misconfigured for a project or blocked on some networks.
    // We subscribe to realtime INSERTs and also keep a lightweight polling fallback so the UI stays fresh.
    //
    // This does not change any backend behavior (RLS still applies).
    final controller = StreamController<List<ChatMessageModel>>.broadcast();

    List<ChatMessageModel> last = const [];
    Timer? poll;
    RealtimeChannel? channel;

    Future<void> refresh() async {
      try {
        final rows = await fetchMessages(chatId: chatId, limit: 200, offset: 0);
        if (rows.isEmpty && last.isEmpty) return;
        if (rows.length == last.length && rows.isNotEmpty && last.isNotEmpty) {
          // Compare last id to avoid unnecessary emits.
          if (rows.last.id == last.last.id) return;
        }
        last = rows;
        if (!controller.isClosed) controller.add(rows);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller.onListen = () {
      // Initial load.
      unawaited(refresh());

      // Realtime insert subscription.
      channel = _client
          .channel('chat_messages:$chatId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'chat_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'chat_id',
              value: chatId,
            ),
            callback: (payload) {
              // Re-fetch so ordering stays correct and RLS is respected.
              unawaited(refresh());
            },
          );
      channel!.subscribe();

      // Poll fallback (kept light).
      poll = Timer.periodic(const Duration(seconds: 4), (_) => unawaited(refresh()));
    };

    controller.onCancel = () async {
      poll?.cancel();
      poll = null;
      if (channel != null) {
        await _client.removeChannel(channel!);
        channel = null;
      }
      await controller.close();
    };

    return controller.stream;
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
