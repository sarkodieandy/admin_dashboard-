import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required ChatRepository repository,
    required String orderId,
    required String userId,
  })  : _repository = repository,
        _orderId = orderId,
        _userId = userId {
    unawaited(_init());
  }

  final ChatRepository _repository;
  final String _orderId;
  final String _userId;

  StreamSubscription<List<ChatMessage>>? _sub;

  bool _isLoading = true;
  String? _error;
  bool _isSending = false;

  String? _chatId;
  List<ChatMessage> _messages = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSending => _isSending;

  String? get chatId => _chatId;
  List<ChatMessage> get messages => _messages;

  String get userId => _userId;

  Future<void> _init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _repository.getOrCreateChatId(orderId: _orderId);
      _chatId = id;

      await _sub?.cancel();
      _sub = _repository.watchMessages(chatId: id).listen((messages) {
        _messages = messages;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> send(String text) async {
    final id = _chatId;
    if (id == null) return;

    final message = text.trim();
    if (message.isEmpty) return;
    if (message.length > AppConstants.maxChatMessageLength) {
      _error = 'Message is too long.';
      notifyListeners();
      return;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.sendMessage(chatId: id, senderId: _userId, message: message);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

