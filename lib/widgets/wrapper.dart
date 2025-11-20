import 'package:fixibot_app/screens/chatbot/chatviewHistory.dart';
import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fixibot_app/screens/chatbot/chatDetailScreen.dart';

class ChatHistoryWrapper extends StatelessWidget {
  const ChatHistoryWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final chatManagerProvider = Get.find<ChatManagerProvider>();
    
    return GetBuilder<ChatManagerProvider>(
      builder: (controller) {
        return ChatHistoryScreen(
          sessions: controller.getSessionsMap(),
          onOpenSession: (sessionId) {
            final messages = controller.getSessionMessages(sessionId);
            
            // Extract vehicle info
            String? vehicleBrand;
            String? vehicleModel;
            for (var msg in messages) {
              if (msg.containsKey('brand') || msg.containsKey('model')) {
                vehicleBrand = msg['brand'] ?? '';
                vehicleModel = msg['model'] ?? '';
                break;
              }
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  messages: messages,
                  vehicleBrand: vehicleBrand,
                  vehicleModel: vehicleModel,
                ),
              ),
            );
          },
          onDeleteSession: (sessionId) {
            controller.deleteSession(sessionId);
          },
        );
      },
    );
  }
}