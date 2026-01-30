import '../../domain/entities/chat_message.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.message,
    required this.createdAt,
    this.senderId,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String?,
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String chatId;
  final String? senderId;
  final String message;
  final DateTime createdAt;

  ChatMessage toEntity() => ChatMessage(
        id: id,
        chatId: chatId,
        senderId: senderId,
        message: message,
        createdAt: createdAt,
      );
}

