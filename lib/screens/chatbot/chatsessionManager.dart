
// import 'dart:convert';
// import 'package:fixibot_app/model/chatSession.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ChatSessionManager {
//   final String _currentUserId;
//   List<ChatSession> _sessions = [];

//   ChatSessionManager(this._currentUserId);

//   List<ChatSession> get sessions => List.unmodifiable(_sessions);

//   // User-specific storage key
//   String get _storageKey => 'chat_sessions_$_currentUserId';

//   Future<void> loadSessions() async {
//     final prefs = await SharedPreferences.getInstance();
//     final stored = prefs.getString(_storageKey);
//     if (stored != null) {
//       try {
//         final List decoded = jsonDecode(stored);
//         _sessions = decoded.map((e) => ChatSession.fromJson(e)).toList();
//         print('📥 Loaded ${_sessions.length} sessions for user: $_currentUserId');
//       } catch (e) {
//         print('❌ Error loading sessions for user $_currentUserId: $e');
//         _sessions = [];
//       }
//     } else {
//       _sessions = [];
//       print('📥 No sessions found for user: $_currentUserId');
//     }
//   }

//   Future<void> _saveToPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(
//       _storageKey,
//       jsonEncode(_sessions.map((s) => s.toJson()).toList()),
//     );
//     print('💾 Saved ${_sessions.length} sessions for user: $_currentUserId');
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

//   void addMessageToSession(String sessionId, Map<String, dynamic> message) {
//     // Find existing session or create new one
//     ChatSession session;
//     try {
//       session = _sessions.firstWhere((s) => s.id == sessionId);
//     } catch (e) {
//       session = ChatSession(id: sessionId, title: 'New Chat', messages: []);
//       _sessions.add(session);
//     }
    
//     session.messages.add(message);
//     _saveToPrefs();
//   }

//   void deleteSession(String sessionId) {
//     _sessions.removeWhere((session) => session.id == sessionId);
//     _saveToPrefs();
//     print('🗑️ Deleted session: $sessionId for user: $_currentUserId');
//   }

//   List<Map<String, dynamic>> getSessionMessages(String sessionId) {
//     try {
//       final session = _sessions.firstWhere((s) => s.id == sessionId);
//       return session.messages;
//     } catch (e) {
//       return [];
//     }
//   }

//   // Convert to map for ChatHistoryScreen
//   Map<String, List<Map<String, dynamic>>> getSessionsMap() {
//     final Map<String, List<Map<String, dynamic>>> sessionsMap = {};
//     for (final session in _sessions) {
//       sessionsMap[session.id] = session.messages;
//     }
//     return sessionsMap;
//   }
//  Future<void> clearCurrentUserSessions() async {
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.remove(_storageKey);
//   _sessions.clear();
//   print('🗑️ Cleared all sessions for user: $_currentUserId');
// }
// }








import 'dart:convert';
import 'package:fixibot_app/model/chatSession.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSessionManager {
  final String _currentUserId;
  List<ChatSession> _sessions = [];

  ChatSessionManager(this._currentUserId);

  List<ChatSession> get sessions => List.unmodifiable(_sessions);

  // User-specific storage key
  String get _storageKey => 'chat_sessions_$_currentUserId';

  Future<void> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
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

  void addMessageToSession(String sessionId, Map<String, dynamic> message) {
    // Find existing session or create new one
    ChatSession session;
    try {
      session = _sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      session = ChatSession(id: sessionId, title: 'New Chat', messages: []);
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

  // Convert to map for ChatHistoryScreen
  Map<String, List<Map<String, dynamic>>> getSessionsMap() {
    final Map<String, List<Map<String, dynamic>>> sessionsMap = {};
    for (final session in _sessions) {
      sessionsMap[session.id] = session.messages;
    }
    return sessionsMap;
  }

  Future<void> clearCurrentUserSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _sessions.clear();
    print('🗑️ Cleared all sessions for user: $_currentUserId');
  }

  // Check if session exists
  bool sessionExists(String sessionId) {
    return _sessions.any((session) => session.id == sessionId);
  }
}