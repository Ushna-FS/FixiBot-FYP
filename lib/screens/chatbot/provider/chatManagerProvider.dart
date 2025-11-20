import 'package:fixibot_app/model/chatSession.dart';
import 'package:fixibot_app/screens/chatbot/chatsessionManager.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class ChatManagerProvider extends GetxController {
  ChatSessionManager? _currentUserChatManager;
  String? _currentUserId;
  
  // Make sessions observable
  final RxList<ChatSession> _sessions = <ChatSession>[].obs;
  List<ChatSession> get sessions => _sessions;

  ChatSessionManager? get chatManager => _currentUserChatManager;
  String? get currentUserId => _currentUserId;

  // Initialize chat manager for logged-in user
  Future<void> initializeForUser(String userId) async {
    _currentUserId = userId;
    _currentUserChatManager = ChatSessionManager(userId);
    await _currentUserChatManager!.loadSessions();
    _sessions.value = _currentUserChatManager!.sessions;
    update();
    print('✅ ChatManagerProvider initialized for user: $userId');
  }

  // Clear when user logs out
  void clearUser() {
    _currentUserId = null;
    _currentUserChatManager = null;
    _sessions.clear();
    update();
    print('✅ ChatManagerProvider cleared');
  }

  void createSession({
    required String id,
    required String title,
    required String firstMessage,
  }) {
    _currentUserChatManager?.createSession(
      id: id,
      title: title,
      firstMessage: firstMessage,
    );
    _sessions.value = _currentUserChatManager?.sessions ?? [];
    update();
  }

  void deleteSession(String sessionId) {
    _currentUserChatManager?.deleteSession(sessionId);
    _sessions.value = _currentUserChatManager?.sessions ?? [];
    update();
  }

  Map<String, List<Map<String, dynamic>>> getSessionsMap() {
    if (_currentUserChatManager == null) return {};
    
    final Map<String, List<Map<String, dynamic>>> sessionsMap = {};
    for (final session in _currentUserChatManager!.sessions) {
      sessionsMap[session.id] = session.messages;
    }
    return sessionsMap;
  }

  void addMessageToSession(String sessionId, Map<String, dynamic> message) {
    _currentUserChatManager?.addMessageToSession(sessionId, message);
    _sessions.value = _currentUserChatManager?.sessions ?? [];
    update();
  }

  List<Map<String, dynamic>> getSessionMessages(String sessionId) {
    return _currentUserChatManager?.getSessionMessages(sessionId) ?? [];
  }
}