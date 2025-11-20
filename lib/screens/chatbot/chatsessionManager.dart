// import 'dart:convert';
// import 'package:fixibot_app/model/chatSession.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ChatSessionManager {
//   final List<ChatSession> _sessions = [];

//   List<ChatSession> get sessions => List.unmodifiable(_sessions);

//   Future<void> loadSessions() async {
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString('all_chat_sessions');
//     if (stored != null) {
//       final List decoded = jsonDecode(stored);
//       _sessions
//         ..clear()
//         ..addAll(decoded.map((e) => ChatSession.fromJson(e)));
//     }
//   }

//   Future<void> _saveToPrefs() async {
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(
//       'all_chat_sessions',
//       jsonEncode(_sessions.map((s) => s.toJson()).toList()),
//     );
//   }

//   void createSession({
//     required String id,
//     required String title,
//     required String firstMessage,
//   }) {
//     final newSession = ChatSession(
//       id: id,
//       title: title,
//       messages: [
//         {"text": firstMessage, "isSent": true}
//       ],
//     );
//     _sessions.add(newSession);
//     _saveToPrefs();
//   }
// }



import 'dart:convert';
import 'package:fixibot_app/model/chatSession.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSessionManager {
  final String _currentUserId;
  List<ChatSession> _sessions = [];

  ChatSessionManager(this._currentUserId);

  List<ChatSession> get sessions => List.unmodifiable(_sessions);

  // Helper method to get the storage instance
  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // User-specific storage key
  String get _storageKey => 'chat_sessions_$_currentUserId';

  Future<void> loadSessions() async {
    final prefs = await _prefs;
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      try {
        final List decoded = jsonDecode(stored);
        _sessions = decoded.map((e) => ChatSession.fromJson(e)).toList();
        print('📥 Loaded ${_sessions.length} sessions for user: $_currentUserId');
      } catch (e) {
        print('❌ Error loading sessions for user $_currentUserId: $e');
        _sessions = [];
      }
    } else {
      _sessions = [];
      print('📥 No sessions found for user: $_currentUserId');
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await _prefs;
    await prefs.setString(
      _storageKey,
      jsonEncode(_sessions.map((s) => s.toJson()).toList()),
    );
    print('💾 Saved ${_sessions.length} sessions for user: $_currentUserId');
  }

  void createSession({
    required String id,
    required String title,
    required String firstMessage,
  }) {
    final newSession = ChatSession(
      id: id,
      title: title,
      messages: [
        {"text": firstMessage, "isSent": true}
      ],
    );
    _sessions.add(newSession);
    _saveToPrefs();
  }

  // Add methods to manage sessions
  void addMessageToSession(String sessionId, Map<String, dynamic> message) {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => ChatSession(id: sessionId, title: 'New Chat', messages: []),
    );
    
    if (!_sessions.contains(session)) {
      _sessions.add(session);
    }
    
    session.messages.add(message);
    _saveToPrefs();
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((session) => session.id == sessionId);
    _saveToPrefs();
    print('🗑️ Deleted session: $sessionId for user: $_currentUserId');
  }

  List<Map<String, dynamic>> getSessionMessages(String sessionId) {
    try {
      final session = _sessions.firstWhere((s) => s.id == sessionId);
      return session.messages;
    } catch (e) {
      return [];
    }
  }

  // Method to clear all sessions for current user (on logout)
  Future<void> clearCurrentUserSessions() async {
    final prefs = await _prefs;
    await prefs.remove(_storageKey);
    _sessions.clear();
    print('🗑️ Cleared all sessions for user: $_currentUserId');
  }

  // Convert to map for ChatHistoryScreen
  Map<String, List<Map<String, dynamic>>> getSessionsMap() {
    final Map<String, List<Map<String, dynamic>>> sessionsMap = {};
    for (final session in _sessions) {
      sessionsMap[session.id] = session.messages;
    }
    return sessionsMap;
  }
}