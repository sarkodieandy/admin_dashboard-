class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String chatId;
  final String? senderId;
  final String message;
  final DateTime createdAt;
}

