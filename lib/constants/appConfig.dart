import 'package:http/http.dart' as http;

class AppConfig {
  static List<String> servers = [
    "https://zoogloeal-byron-unruled.ngrok-free.dev",
    "https://chalky-anjelica-bovinely.ngrok-free.dev",
  ];

  static String? _currentBaseUrl;

  static String get baseUrl => _currentBaseUrl ?? servers.first;

  static Future<void> initialize() async {
    for (String server in servers) {
      if (await _checkServerHealth(server)) {
        _currentBaseUrl = server;
        print('✅ Using server: $server');
        return;
      }
    }
    print('❌ No working servers found');
  }

  static Future<bool> _checkServerHealth(String url) async {
    try {
      final response = await http.get(Uri.parse('$url/health/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// class AppConfig {
 
//   // static const String baseUrl = "https://zoogloeal-byron-unruled.ngrok-free.dev";
// static const String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";
// }