import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fixibot_app/screens/chatbot/chatDetailScreen.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';

class ChatHistoryParentWidget extends StatelessWidget {
  const ChatHistoryParentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Chat History"),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Check if providers are registered
    if (!Get.isRegistered<ChatManagerProvider>()) {
      print('❌ ChatManagerProvider not registered');
      return _buildErrorWidget("Chat system not ready\nPlease restart the app");
    }

    if (!Get.isRegistered<SharedPrefsHelper>()) {
      print('❌ SharedPrefsHelper not registered');
      return _buildErrorWidget("Storage system not ready\nPlease restart the app");
    }

    final chatManagerProvider = Get.find<ChatManagerProvider>();
    print('🔍 ChatManagerProvider found: ${chatManagerProvider.isInitialized}');

    return GetBuilder<ChatManagerProvider>(
      builder: (controller) {
        print('🔄 GetBuilder rebuilt - isInitialized: ${controller.isInitialized}');
        
        // Check if provider is initialized
        if (!controller.isInitialized) {
          print('❌ ChatManagerProvider not initialized');
          print('❌ Current User ID: ${controller.currentUserId}');
          return _buildLoadingWidget(controller);
        }

        final sessions = controller.getSessionsMap();
        final ids = sessions.keys.toList()..sort((a, b) => b.compareTo(a));

        print('📊 Sessions count: ${sessions.length}');
        print('📊 IDs count: ${ids.length}');

        if (ids.isEmpty) {
          return _buildEmptyWidget();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: ids.length,
          itemBuilder: (_, i) {
            final id = ids[i];
            final messages = sessions[id] ?? [];
            final firstMsg = messages.isNotEmpty
                ? (messages.first['text']?.toString() ?? 'Untitled chat')
                : 'Untitled chat';
            final lastMsg = messages.isNotEmpty
                ? (messages.last['text']?.toString() ?? '')
                : '';

            return Dismissible(
              key: Key('$id-${messages.length}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.redAccent,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => controller.deleteSession(id),
              child: GestureDetector(
                onTap: () {
                  String? vehicleBrand;
                  String? vehicleModel;

                  for (var msg in messages) {
                    if (msg.containsKey('brand') || msg.containsKey('model')) {
                      vehicleBrand = msg['brand']?.toString() ?? '';
                      vehicleModel = msg['model']?.toString() ?? '';
                      break;
                    }
                  }

                  Get.to(
                    () => ChatDetailScreen(
                      messages: messages,
                      vehicleBrand: vehicleBrand,
                      vehicleModel: vehicleModel,
                    ),
                  );
                },
                child: _historyTile(firstMsg, lastMsg, _formatDate(id)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Try to register dependencies manually
              _registerDependencies();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(ChatManagerProvider controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text("Loading your chats..."),
          const SizedBox(height: 8),
          Text(
            "User ID: ${controller.currentUserId ?? 'Not set'}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _tryInitializeChatManager();
            },
            child: const Text("Initialize Chat Manager"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "No saved chats yet",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Start a conversation with Fixibot!",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to chat screen
              Get.back(); // Go back and start a new chat
            },
            child: const Text("Start New Chat"),
          ),
        ],
      ),
    );
  }

  void _registerDependencies() {
    print('🔄 Attempting to register dependencies...');
    
    try {
      if (!Get.isRegistered<SharedPrefsHelper>()) {
        Get.put(SharedPrefsHelper(), permanent: true);
        print('✅ SharedPrefsHelper registered');
      }
      
      if (!Get.isRegistered<ChatManagerProvider>()) {
        Get.put(ChatManagerProvider(), permanent: true);
        print('✅ ChatManagerProvider registered');
      }
      
      Get.snackbar(
        'Success',
        'Dependencies registered successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ Error registering dependencies: $e');
      Get.snackbar(
        'Error',
        'Failed to register dependencies: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _tryInitializeChatManager() async {
    print('🔄 Attempting to initialize chat manager...');
    
    try {
      // Safe way to get SharedPrefsHelper
      SharedPrefsHelper sharedPrefs;
      if (Get.isRegistered<SharedPrefsHelper>()) {
        sharedPrefs = Get.find<SharedPrefsHelper>();
      } else {
        print('❌ SharedPrefsHelper not registered, registering now...');
        sharedPrefs = Get.put(SharedPrefsHelper(), permanent: true);
      }

      final userId = await sharedPrefs.getCurrentUserId();
      
      if (userId != null && userId.isNotEmpty) {
        print('✅ Found user ID: $userId');
        
        // Safe way to get ChatManagerProvider
        ChatManagerProvider chatManager;
        if (Get.isRegistered<ChatManagerProvider>()) {
          chatManager = Get.find<ChatManagerProvider>();
        } else {
          print('❌ ChatManagerProvider not registered, registering now...');
          chatManager = Get.put(ChatManagerProvider(), permanent: true);
        }
        
        await chatManager.initializeForUser(userId);
        
        Get.snackbar(
          'Success',
          'Chat manager initialized successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
        );
      } else {
        print('❌ No user ID found in SharedPreferences');
        Get.snackbar(
          'Error',
          'No user found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print('❌ Error initializing chat manager: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  String _formatDate(String epoch) {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(epoch));
      final two = (int n) => n.toString().padLeft(2, '0');
      return "${dt.month}/${dt.day} ${two(dt.hour)}:${two(dt.minute)}";
    } catch (_) {
      return 'Invalid date';
    }
  }

  Widget _historyTile(String first, String last, String date) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.mainColor,
            child: Text(
              first.isNotEmpty ? first[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.secondaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                if (last.isNotEmpty)
                  Text(
                    last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}