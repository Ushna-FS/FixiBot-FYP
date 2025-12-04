import 'package:fixibot_app/screens/chatbot/chatsessionManager.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class ChatManagerProvider extends GetxController {
  ChatSessionManager? _currentUserChatManager;
  String? _currentUserId;
  
  // Observable sessions
  final RxMap<String, List<Map<String, dynamic>>> _sessionsMap = <String, List<Map<String, dynamic>>>{}.obs;

  // Make sure this getter exists and works correctly
  bool get isInitialized => _currentUserId != null && _currentUserChatManager != null;
  String? get currentUserId => _currentUserId;

  Map<String, List<Map<String, dynamic>>> get sessionsMap => _sessionsMap;

  // Initialize chat manager for logged-in user
  Future<void> initializeForUser(String userId) async {
    try {
      print('🔄 Initializing ChatManagerProvider for user: $userId');
      
      // 🔥 CLEAR PREVIOUS STATE FIRST
      _currentUserId = userId;
      _currentUserChatManager = ChatSessionManager(userId);
      _sessionsMap.clear();
      
      // Load sessions
      await _currentUserChatManager!.loadSessions();
      
      // Update state
      _updateSessionsMap();
      
      print('✅ ChatManagerProvider initialized for user: $userId');
      print('✅ Sessions loaded: ${_sessionsMap.length}');
      
      // Notify listeners
      update();
      
    } catch (e) {
      print('❌ Error initializing ChatManagerProvider: $e');
      // 🔥 RESET TO AVOID CORRUPTED STATE
      _currentUserId = null;
      _currentUserChatManager = null;
      _sessionsMap.clear();
      update();
      rethrow;
    }
  }

  void _updateSessionsMap() {
    if (_currentUserChatManager != null) {
      _sessionsMap.value = _currentUserChatManager!.getSessionsMap();
    }
    update();
  }

  Map<String, List<Map<String, dynamic>>> getSessionsMap() {
    return _sessionsMap;
  }

  // Create a new chat session
  void createSession({
    required String id,
    required String title,
    required String firstMessage,
  }) {
    if (!isInitialized) {
      print('❌ ChatManagerProvider not initialized - cannot create session');
      return;
    }
    
    _currentUserChatManager!.createSession(
      id: id,
      title: title,
      firstMessage: firstMessage,
    );
    _updateSessionsMap();
    print('✅ Created new session: $id');
  }

  // Add message to existing session
  void addMessageToSession(String sessionId, Map<String, dynamic> message) {
    if (!isInitialized) {
      print('❌ ChatManagerProvider not initialized - cannot add message');
      return;
    }
    
    _currentUserChatManager!.addMessageToSession(sessionId, message);
    _updateSessionsMap();
    print('✅ Added message to session: $sessionId');
  }

  // Delete a session
  void deleteSession(String sessionId) {
    if (!isInitialized) {
      print('❌ ChatManagerProvider not initialized - cannot delete session');
      return;
    }
    
    _currentUserChatManager!.deleteSession(sessionId);
    _updateSessionsMap();
    print('✅ Deleted session: $sessionId');
  }

  // Get messages for a specific session
  List<Map<String, dynamic>> getSessionMessages(String sessionId) {
    if (!isInitialized) {
      print('❌ ChatManagerProvider not initialized - cannot get messages');
      return [];
    }
    
    return _currentUserChatManager!.getSessionMessages(sessionId);
  }

  // 🔥 NEW: Check if session exists
  bool sessionExists(String sessionId) {
    if (!isInitialized) return false;
    return _sessionsMap.containsKey(sessionId);
  }

  // 🔥 NEW: Get session count
  int get sessionCount {
    if (!isInitialized) return 0;
    return _sessionsMap.length;
  }

  // 🔥 NEW: Clear all sessions for current user
  Future<void> clearAllSessions() async {
    if (!isInitialized) {
      print('❌ ChatManagerProvider not initialized - cannot clear sessions');
      return;
    }
    
    await _currentUserChatManager!.clearCurrentUserSessions();
    _sessionsMap.clear();
    update();
    print('✅ Cleared all sessions for user: $_currentUserId');
  }

  // Clear user data (on logout)
  void clearUser() {
    _currentUserId = null;
    _currentUserChatManager = null;
    _sessionsMap.clear();
    update();
    print('✅ ChatManagerProvider user data cleared');
  }

  // 🔥 NEW: Get latest session ID (most recent)
  String? get latestSessionId {
    if (!isInitialized || _sessionsMap.isEmpty) return null;
    
    final sortedIds = _sessionsMap.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedIds.first;
  }

  // 🔥 NEW: Get session title
  String getSessionTitle(String sessionId) {
    final messages = getSessionMessages(sessionId);
    if (messages.isEmpty) return 'Untitled Chat';
    
    // Use first message as title, truncated
    final firstMessage = messages.first['text']?.toString() ?? 'Untitled Chat';
    return firstMessage.length > 30 
        ? '${firstMessage.substring(0, 30)}...' 
        : firstMessage;
  }

  // 🔥 NEW: Get session preview (last message)
  String getSessionPreview(String sessionId) {
    final messages = getSessionMessages(sessionId);
    if (messages.isEmpty) return '';
    
    // Use last message as preview, truncated
    final lastMessage = messages.last['text']?.toString() ?? '';
    return lastMessage.length > 50 
        ? '${lastMessage.substring(0, 50)}...' 
        : lastMessage;
  }

  // 🔥 NEW: Check if session has vehicle info
  Map<String, String?> getSessionVehicleInfo(String sessionId) {
    final messages = getSessionMessages(sessionId);
    String? vehicleBrand;
    String? vehicleModel;

    for (var msg in messages) {
      if (msg.containsKey('brand') || msg.containsKey('model')) {
        vehicleBrand = msg['brand']?.toString();
        vehicleModel = msg['model']?.toString();
        break;
      }
    }

    return {
      'brand': vehicleBrand,
      'model': vehicleModel,
    };
  }

  // 🔥 NEW: Force refresh sessions from storage
  Future<void> refreshSessions() async {
    if (!isInitialized) {
      print('❌ ChatManagerProvider not initialized - cannot refresh');
      return;
    }
    
    await _currentUserChatManager!.loadSessions();
    _updateSessionsMap();
    print('✅ Sessions refreshed: ${_sessionsMap.length} sessions');
  }

  // 🔥 NEW: Get all session IDs sorted by date (newest first)
  List<String> getSortedSessionIds() {
    if (!isInitialized) return [];
    
    return _sessionsMap.keys.toList()..sort((a, b) => b.compareTo(a));
  }

  // 🔥 NEW: Debug information
  void printDebugInfo() {
    print('=== ChatManagerProvider Debug Info ===');
    print('Initialized: $isInitialized');
    print('User ID: $_currentUserId');
    print('Session Count: ${_sessionsMap.length}');
    print('Session IDs: ${_sessionsMap.keys.toList()}');
    print('=====================================');
  }
}














//perff
// import 'package:fixibot_app/screens/chatbot/chatsessionManager.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';

// class ChatManagerProvider extends GetxController {
//   ChatSessionManager? _currentUserChatManager;
//   String? _currentUserId;
  
//   // Observable sessions
//   final RxMap<String, List<Map<String, dynamic>>> _sessionsMap = <String, List<Map<String, dynamic>>>{}.obs;

//   // Make sure this getter exists and works correctly
//   bool get isInitialized => _currentUserId != null && _currentUserChatManager != null;
//   String? get currentUserId => _currentUserId;

//   Map<String, List<Map<String, dynamic>>> get sessionsMap => _sessionsMap;

//   // Initialize chat manager for logged-in user
//   Future<void> initializeForUser(String userId) async {
//     _currentUserId = userId;
//     _currentUserChatManager = ChatSessionManager(userId);
//     await _currentUserChatManager!.loadSessions();
//     _updateSessionsMap();
//     update();
//     print('✅ ChatManagerProvider initialized for user: $userId');
//     print('✅ Sessions loaded: ${_sessionsMap.length}');
//   }

//   void _updateSessionsMap() {
//     if (_currentUserChatManager != null) {
//       _sessionsMap.value = _currentUserChatManager!.getSessionsMap();
//     }
//     update();
//   }

//   Map<String, List<Map<String, dynamic>>> getSessionsMap() {
//     return _sessionsMap;
//   }

//   // Create a new chat session
//   void createSession({
//     required String id,
//     required String title,
//     required String firstMessage,
//   }) {
//     if (!isInitialized) {
//       print('❌ ChatManagerProvider not initialized - cannot create session');
//       return;
//     }
    
//     _currentUserChatManager!.createSession(
//       id: id,
//       title: title,
//       firstMessage: firstMessage,
//     );
//     _updateSessionsMap();
//     print('✅ Created new session: $id');
//   }

//   // Add message to existing session
//   void addMessageToSession(String sessionId, Map<String, dynamic> message) {
//     if (!isInitialized) {
//       print('❌ ChatManagerProvider not initialized - cannot add message');
//       return;
//     }
    
//     _currentUserChatManager!.addMessageToSession(sessionId, message);
//     _updateSessionsMap();
//     print('✅ Added message to session: $sessionId');
//   }

//   // Delete a session
//   void deleteSession(String sessionId) {
//     if (!isInitialized) {
//       print('❌ ChatManagerProvider not initialized - cannot delete session');
//       return;
//     }
    
//     _currentUserChatManager!.deleteSession(sessionId);
//     _updateSessionsMap();
//     print('✅ Deleted session: $sessionId');
//   }

//   // Get messages for a specific session
//   List<Map<String, dynamic>> getSessionMessages(String sessionId) {
//     if (!isInitialized) {
//       print('❌ ChatManagerProvider not initialized - cannot get messages');
//       return [];
//     }
    
//     return _currentUserChatManager!.getSessionMessages(sessionId);
//   }

//   // 🔥 NEW: Check if session exists
//   bool sessionExists(String sessionId) {
//     if (!isInitialized) return false;
//     return _sessionsMap.containsKey(sessionId);
//   }

//   // 🔥 NEW: Get session count
//   int get sessionCount {
//     if (!isInitialized) return 0;
//     return _sessionsMap.length;
//   }

//   // 🔥 NEW: Clear all sessions for current user
//   Future<void> clearAllSessions() async {
//     if (!isInitialized) {
//       print('❌ ChatManagerProvider not initialized - cannot clear sessions');
//       return;
//     }
    
//     await _currentUserChatManager!.clearCurrentUserSessions();
//     _sessionsMap.clear();
//     update();
//     print('✅ Cleared all sessions for user: $_currentUserId');
//   }

//   // Clear user data (on logout)
//   void clearUser() {
//     _currentUserId = null;
//     _currentUserChatManager = null;
//     _sessionsMap.clear();
//     update();
//     print('✅ ChatManagerProvider user data cleared');
//   }

//   // 🔥 NEW: Get latest session ID (most recent)
//   String? get latestSessionId {
//     if (!isInitialized || _sessionsMap.isEmpty) return null;
    
//     final sortedIds = _sessionsMap.keys.toList()..sort((a, b) => b.compareTo(a));
//     return sortedIds.first;
//   }

//   // 🔥 NEW: Get session title
//   String getSessionTitle(String sessionId) {
//     final messages = getSessionMessages(sessionId);
//     if (messages.isEmpty) return 'Untitled Chat';
    
//     // Use first message as title, truncated
//     final firstMessage = messages.first['text']?.toString() ?? 'Untitled Chat';
//     return firstMessage.length > 30 
//         ? '${firstMessage.substring(0, 30)}...' 
//         : firstMessage;
//   }

//   // 🔥 NEW: Get session preview (last message)
//   String getSessionPreview(String sessionId) {
//     final messages = getSessionMessages(sessionId);
//     if (messages.isEmpty) return '';
    
//     // Use last message as preview, truncated
//     final lastMessage = messages.last['text']?.toString() ?? '';
//     return lastMessage.length > 50 
//         ? '${lastMessage.substring(0, 50)}...' 
//         : lastMessage;
//   }

//   // 🔥 NEW: Check if session has vehicle info
//   Map<String, String?> getSessionVehicleInfo(String sessionId) {
//     final messages = getSessionMessages(sessionId);
//     String? vehicleBrand;
//     String? vehicleModel;

//     for (var msg in messages) {
//       if (msg.containsKey('brand') || msg.containsKey('model')) {
//         vehicleBrand = msg['brand']?.toString();
//         vehicleModel = msg['model']?.toString();
//         break;
//       }
//     }

//     return {
//       'brand': vehicleBrand,
//       'model': vehicleModel,
//     };
//   }

//   // 🔥 NEW: Force refresh sessions from storage
//   Future<void> refreshSessions() async {
//     if (!isInitialized) {
//       print('❌ ChatManagerProvider not initialized - cannot refresh');
//       return;
//     }
    
//     await _currentUserChatManager!.loadSessions();
//     _updateSessionsMap();
//     print('✅ Sessions refreshed: ${_sessionsMap.length} sessions');
//   }

//   // 🔥 NEW: Get all session IDs sorted by date (newest first)
//   List<String> getSortedSessionIds() {
//     if (!isInitialized) return [];
    
//     return _sessionsMap.keys.toList()..sort((a, b) => b.compareTo(a));
//   }

//   // 🔥 NEW: Debug information
//   void printDebugInfo() {
//     print('=== ChatManagerProvider Debug Info ===');
//     print('Initialized: $isInitialized');
//     print('User ID: $_currentUserId');
//     print('Session Count: ${_sessionsMap.length}');
//     print('Session IDs: ${_sessionsMap.keys.toList()}');
//     print('=====================================');
//   }
// }