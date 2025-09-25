class ChatSession {
  final String id;
  final String title;
  final List<Map<String, dynamic>> messages;
  ChatSession({required this.id, required this.title, required this.messages});


  Map<String, dynamic> toJson() =>
      {"id": id, "title": title, "messages": messages};

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json["id"],
        title: json["title"],
        messages: List<Map<String, dynamic>>.from(json["messages"] ?? []),
      );
}
