import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:fixibot_app/constants/app_colors.dart';

class ChatDetailScreen extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final String? vehicleBrand;
  final String? vehicleModel;

  const ChatDetailScreen({
    super.key,
    required this.messages,
    this.vehicleBrand,
    this.vehicleModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Chat History",
      ),
      body: Column(
        children: [
          // Vehicle info
          if (vehicleBrand != null || vehicleModel != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "Vehicle: ${vehicleBrand ?? ''} ${vehicleModel ?? ''}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainColor,
                ),
              ),
            ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                final isUser = m['isSent'] == true;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isUser ? AppColors.mainColor : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (m.containsKey("imagePath"))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(m["imagePath"]),
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (m.containsKey("text"))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              m["text"],
                              style: TextStyle(
                                  color:
                                      isUser ? Colors.white : Colors.black87),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
