import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/widgets/custom_textField.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

void main() {
  runApp(const ChatScreen());
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> messages = [
    {"text": "Hello! My car engine is making wierd sounds.", "isSent": true},
    {"text": "....", "isSent": false},
  ];

  final TextEditingController _controller = TextEditingController();

  void sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      messages.add({"text": _controller.text, "isSent": false});
      _controller.clear();

      // Simulating bot reply after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          messages.add({"text": "Thank you! We'll process your request soon.", "isSent": true});
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        
        elevation: 1,
        title: Text("FixiBot", style: AppFonts.montserrathomecardText),
        centerTitle: true,
        leading: IconButton(
                    onPressed: () {
                      Get.back();
                    }, 
                    icon: Image.asset('assets/icons/back.png',
                    width: 30,
                    height:30),
                    ),
        actions: const [Icon(Icons.file_copy_outlined, color: AppColors.mainColor)],
      ),

body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: messages[index]["isSent"]
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: messages[index]["isSent"]
                          ? AppColors.mainColor
                          : AppColors.mainSwatch.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: messages[index]["isSent"]
                            ? const Radius.circular(15)
                            : const Radius.circular(0),
                        bottomRight: messages[index]["isSent"]
                            ? const Radius.circular(0)
                            : const Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      messages[index]["text"],
                      style: TextStyle(
                        color: messages[index]["isSent"]
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _controller,
                    hintText: "Type Here",
                    icon: Icons.camera_alt_rounded,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.mainColor),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),

    );
  }
}








