import 'dart:convert';
import 'package:fixibot_app/model/chatSession.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSessionManager {
  final List<ChatSession> _sessions = [];

  List<ChatSession> get sessions => List.unmodifiable(_sessions);

  Future<void> loadSessions() async {
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getString('all_chat_sessions');
    if (stored != null) {
      final List decoded = jsonDecode(stored);
      _sessions
        ..clear()
        ..addAll(decoded.map((e) => ChatSession.fromJson(e)));
    }
  }

  Future<void> _saveToPrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      'all_chat_sessions',
      jsonEncode(_sessions.map((s) => s.toJson()).toList()),
    );
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
}
