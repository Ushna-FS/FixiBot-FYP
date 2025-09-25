import 'package:fixibot_app/screens/chatbot/chatDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';

class ChatHistoryScreen extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> sessions;
  final ValueChanged<String> onOpenSession;
  final ValueChanged<String> onDeleteSession;

  const ChatHistoryScreen({
    super.key,
    required this.sessions,
    required this.onOpenSession,
    required this.onDeleteSession,
  });

  String _formatDate(String epoch) {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(epoch));
      final two = (int n) => n.toString().padLeft(2, '0');
      return "${dt.month}/${dt.day}  ${two(dt.hour)}:${two(dt.minute)}";
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ids = sessions.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: const CustomAppBar(title: "Chat History"),
      body: ids.isEmpty
          ? const Center(child: Text("No saved chats yet"))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: ids.length,
              itemBuilder: (_, i) {
                final id = ids[i];
                final messages = sessions[id] ?? [];
                final firstMsg = messages.isNotEmpty
                    ? (messages.first['text'] ?? 'Untitled chat')
                    : 'Untitled chat';
                final lastMsg =
                    messages.isNotEmpty ? (messages.last['text'] ?? '') : '';

                return Dismissible(
                  key: Key(id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => onDeleteSession(id),
                  child: GestureDetector(
                    onTap: () {
                      // Extract vehicle info from the first message that has it
                      String? vehicleBrand;
                      String? vehicleModel;

                      for (var msg in messages) {
                        if (msg.containsKey('brand') ||
                            msg.containsKey('model')) {
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
                    child: _historyTile(firstMsg, lastMsg, _formatDate(id)),
                  ),
                );
              },
            ),
    );
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
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(date,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
