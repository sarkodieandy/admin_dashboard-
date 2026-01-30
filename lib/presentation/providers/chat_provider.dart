import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
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

  bool _disposed = false;
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
    if (!_disposed) notifyListeners();

    try {
      AppLogger.i('chat_init_start orderId=$_orderId', tag: 'chat');
      final id = await _repository.getOrCreateChatId(orderId: _orderId);
      _chatId = id;

      await _sub?.cancel();
      _sub = _repository.watchMessages(chatId: id).listen(
        (messages) {
          _messages = messages;
          if (!_disposed) notifyListeners();
        },
        onError: (error, stackTrace) {
          AppLogger.e('chat_watch_failed orderId=$_orderId chatId=$id', tag: 'chat', error: error, stackTrace: stackTrace);
          _error = error.toString();
          if (!_disposed) notifyListeners();
        },
      );
      AppLogger.i('chat_init_ok orderId=$_orderId chatId=$id', tag: 'chat');
    } catch (error, stackTrace) {
      AppLogger.e('chat_init_failed orderId=$_orderId', tag: 'chat', error: error, stackTrace: stackTrace);
      _error = error.toString();
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> send(String text) async {
    final id = _chatId;
    if (id == null) return false;
    if (_isSending) return false;

    final message = text.trim();
    if (message.isEmpty) return false;
    if (message.length > AppConstants.maxChatMessageLength) {
      _error = 'Message is too long.';
      if (!_disposed) notifyListeners();
      return false;
    }

    _isSending = true;
    _error = null;
    if (!_disposed) notifyListeners();

    try {
      AppLogger.i('chat_send_start chatId=$id', tag: 'chat');
      await _repository.sendMessage(chatId: id, senderId: _userId, message: message);
      AppLogger.i('chat_send_ok chatId=$id', tag: 'chat');
      return true;
    } catch (e) {
      AppLogger.e('chat_send_failed chatId=$id', tag: 'chat', error: e);
      _error = e.toString();
      return false;
    } finally {
      _isSending = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
