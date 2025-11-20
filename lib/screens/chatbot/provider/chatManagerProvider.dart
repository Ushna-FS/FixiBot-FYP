// chat_manager_provider.dart
import 'package:fixibot_app/model/chatSession.dart';
import 'package:fixibot_app/screens/chatbot/chatsessionManager.dart';
import 'package:flutter/foundation.dart';

class ChatManagerProvider with ChangeNotifier {
  ChatSessionManager? _currentUserChatManager;
  String? _currentUserId;

  ChatSessionManager? get chatManager => _currentUserChatManager;
  String? get currentUserId => _currentUserId;

  // Initialize chat manager for logged-in user
  Future<void> initializeForUser(String userId) async {
    _currentUserId = userId;
    _currentUserChatManager = ChatSessionManager(userId);
    await _currentUserChatManager!.loadSessions();
    notifyListeners();
  }

  // Clear when user logs out
  void clearUser() {
    _currentUserId = null;
    _currentUserChatManager = null;
    notifyListeners();
  }

  // Proxy methods to chat manager
  List<ChatSession> get sessions => _currentUserChatManager?.sessions ?? [];

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
    notifyListeners();
  }

  void deleteSession(String sessionId) {
    _currentUserChatManager?.deleteSession(sessionId);
    notifyListeners();
  }

  Map<String, List<Map<String, dynamic>>> getSessionsMap() {
    if (_currentUserChatManager == null) return {};
    
    final Map<String, List<Map<String, dynamic>>> sessionsMap = {};
    for (final session in _currentUserChatManager!.sessions) {
      sessionsMap[session.id] = session.messages;
    }
    return sessionsMap;
  }
}