import 'dart:convert';
import 'dart:io';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:fixibot_app/screens/chatbot/chatviewHistory.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys to store/retrieve persistent data
const String kSessionsKey = "all_chat_sessions";
const String kCurrentSessionKey = "current_session_id";

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final VehicleController vehicleController = Get.find<VehicleController>();
  final SharedPrefsHelper _prefs = SharedPrefsHelper();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final baseUrl = AppConfig.baseUrl;

  // Auth & session
  String? _accessToken;
  String? _tokenType;
  String? _sessionId;

  // UI / chat state
  File? _selectedImage;
  Map<String, dynamic>? _selectedVehicle;
  bool _isProcessing = false;

  /// All sessions are stored here:
  /// key = sessionId, value = list of message maps
  Map<String, List<Map<String, dynamic>>> _allSessions = {};
  String? _activeSessionId;

  @override
  void initState() {
    super.initState();
    vehicleController.fetchUserVehicles();
    _initAuth();
    _loadSessions();
  }

  /* ----------------- Persistent Sessions ------------------ */

  Future<void> _loadSessions() async {
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getString(kSessionsKey);
    final currentId = sp.getString(kCurrentSessionKey);

    if (stored != null) {
      final Map<String, dynamic> decoded = jsonDecode(stored);
      _allSessions = decoded.map(
          (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
    }

    if (currentId != null && _allSessions.containsKey(currentId)) {
      _activeSessionId = currentId;
    } else {
      _startNewLocalSession();
    }
    setState(() {});
  }

  Future<void> _saveSessions() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(kSessionsKey, jsonEncode(_allSessions));
    if (_activeSessionId != null) {
      await sp.setString(kCurrentSessionKey, _activeSessionId!);
    }
  }

  void _startNewLocalSession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _allSessions[newId] = [];
    _activeSessionId = newId;
  }

  Future<void> _startNewChat() async {
    setState(() {
      _startNewLocalSession();
    });
    await _saveSessions();
  }

  // Delete a session
  Future<void> onDelete(String sessionId) async {
    setState(() {
      _allSessions.remove(sessionId);
      if (_activeSessionId == sessionId) {
        if (_allSessions.isEmpty) {
          _startNewLocalSession();
        } else {
          _activeSessionId = _allSessions.keys.first;
        }
      }
    });
    await _saveSessions();
  }

  /* ----------------- Backend Auth/Session ------------------ */

  Future<void> _initAuth() async {
    _accessToken = await _prefs.getString("access_token");
    _tokenType = await _prefs.getString("token_type");
    
    print('🔐 Chatbot Auth Check:');
    print('   Access Token: ${_accessToken != null ? "✅" : "❌"}');
    print('   Token Type: ${_tokenType ?? "NULL"}');
    
    // AUTO-FIX: If token_type is missing but access_token exists (Google user issue)
    if (_accessToken != null && _accessToken!.isNotEmpty && (_tokenType == null || _tokenType!.isEmpty)) {
      print('🛠️ Auto-fixing missing token_type for Google user...');
      await _prefs.saveString('token_type', 'bearer');
      _tokenType = 'bearer';
      print('✅ Auto-fixed: token_type set to "bearer"');
      
      Get.snackbar(
        "Ready!", 
        "Chatbot authentication completed",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    }
    
    if (_accessToken == null || _tokenType == null) {
      Get.snackbar(
        "Authentication Required", 
        "Please login again to use chatbot",
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
      await _debugChatbotAuth();
      return;
    }
    
    await _startServerSession();
  }

  Future<void> _debugChatbotAuth() async {
    final prefs = await SharedPreferences.getInstance();
    
    print('=== CHATBOT AUTH DEBUG ===');
    print('Access Token: ${prefs.getString('access_token') != null ? "✅ EXISTS" : "❌ MISSING"}');
    print('Token Type: ${prefs.getString('token_type') ?? "❌ NULL"}');
    print('User ID: ${prefs.getString('user_id') ?? "❌ NULL"}');
    print('Email: ${prefs.getString('email') ?? "❌ NULL"}');
    
    final hasAccessToken = prefs.getString('access_token') != null;
    final hasTokenType = prefs.getString('token_type') != null;
    final hasUserId = prefs.getString('user_id') != null;
    
    print('Chatbot Ready: ${hasAccessToken && hasTokenType && hasUserId}');
    print('==========================');
    
    if (!hasAccessToken || !hasTokenType) {
      Get.snackbar(
        "Auth Issue", 
        "Missing authentication data for chatbot",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _startServerSession() async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/chat/start"),
        headers: {
          "Content-Type": "application/json",
          "accept": "application/json",
          "Authorization": "$_tokenType $_accessToken",
        },
      );
      if (res.statusCode == 201) {
        final data = json.decode(res.body);
        _sessionId = data["session_id"];
        debugPrint("Server chat session started: $_sessionId");
      }
    } catch (e) {
      debugPrint("Server session error: $e");
    }
  }

  /* ----------------- Per-Vehicle Session Logic ------------------ */

  Future<String?> _getSessionIdForVehicle(String vehicleId) async {
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getString(kSessionsKey);
    if (stored == null) return null;

    final Map<String, dynamic> decoded = jsonDecode(stored);
    for (var entry in decoded.entries) {
      final sessionMessages = List<Map<String, dynamic>>.from(entry.value as List);
      if (sessionMessages.any((m) => m["vehicleId"] == vehicleId)) {
        return entry.key;
      }
    }
    return null;
  }

  Future<String> _createNewSessionForVehicle(String vehicleId) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _allSessions[newId] = [];
    _activeSessionId = newId;
    await _saveSessions();
    return newId;
  }

  Future<void> _activateVehicleSession(String vehicleId) async {
    String? sessionId = await _getSessionIdForVehicle(vehicleId);
    if (sessionId == null) {
      sessionId = await _createNewSessionForVehicle(vehicleId);
    }
    setState(() => _activeSessionId = sessionId);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(kCurrentSessionKey, sessionId);
  }

  // Get correct vehicle icon based on category
  IconData _getVehicleIcon(Map<String, dynamic> vehicle) {
    final category = vehicle['category']?.toString().toLowerCase() ?? '';
    
    switch (category) {
      case 'car':
        return Icons.directions_car;
      case 'motorcycle':
      case 'bike':
        return Icons.motorcycle;
      case 'truck':
        return Icons.local_shipping;
      case 'suv':
        return Icons.airport_shuttle;
      default:
        return Icons.directions_car;
    }
  }

  /* ----------------- Message Handling ------------------ */

  // Future<void> sendMessage() async {
  //   if (_selectedVehicle == null) {
  //     Get.snackbar(
  //       "Select Vehicle",
  //       "Please choose a vehicle",
  //       backgroundColor: Colors.redAccent,
  //       colorText: Colors.white,
  //     );
  //     return;
  //   }
    
  //   final text = _controller.text.trim();
  //   final vehicleId = _selectedVehicle!["_id"];

  //   // Validate input
  //   if (text.isEmpty && _selectedImage == null) {
  //     Get.snackbar(
  //       "Empty Message",
  //       "Please enter a message or select an image",
  //       backgroundColor: Colors.orange,
  //       colorText: Colors.white,
  //     );
  //     return;
  //   }

  //   // Ensure session exists
  //   if (_activeSessionId == null) {
  //     await _activateVehicleSession(vehicleId);
  //   }

  //   // Store user input temporarily
  //   final userText = text;
  //   final userImage = _selectedImage;

  //   // Clear input immediately and show loader
  //   setState(() {
  //     _controller.clear();
  //     _selectedImage = null;
  //     _isProcessing = true;
  //   });

  //   // Add user message locally with image preview
  //   final userMessage = {
  //     "text": userText,
  //     "isSent": true,
  //     "vehicleId": vehicleId,
  //     "brand": _selectedVehicle?['brand'],
  //     "model": _selectedVehicle?['model'],
  //     "timestamp": DateTime.now().toIso8601String(),
  //   };

  //   // Add image path to message if image exists
  //   if (userImage != null) {
  //     userMessage["imagePath"] = userImage.path;
  //     userMessage["hasImage"] = true;
  //   }

  //   setState(() {
  //     _allSessions[_activeSessionId]!.add(userMessage);
  //   });
  //   await _saveSessions();

  //   // Send to backend with enhanced error handling
  //   try {
  //     final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
      
  //     // Add headers
  //     request.headers["Authorization"] = "$_tokenType $_accessToken";
  //     request.headers["Accept"] = "application/json";
  //     request.headers["Content-Type"] = "multipart/form-data";

  //     // Add session and message data
  //     if (_sessionId != null) {
  //       request.fields["session_id"] = _sessionId!;
  //     }
      
  //     // Smart message routing based on content
  //     if (userText.isNotEmpty) {
  //       request.fields["message"] = userText;
  //     } else if (userImage != null) {
  //       // Auto-generate context-aware prompt for image analysis
  //       request.fields["message"] = "Analyze this vehicle image and provide detailed insights about any visible issues, damage, or maintenance needs for my ${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}";
  //     }
      
  //     // Send vehicle data as proper JSON with additional context
  //     final vehicleData = {
  //       ..._selectedVehicle!,
  //       "analysis_context": userImage != null ? "visual_inspection" : "general_query",
  //       "requires_cv_analysis": userImage != null,
  //     };
  //     request.fields["vehicle_json"] = json.encode(vehicleData);

  //     print('📤 Sending chat message:');
  //     print('   Message: ${request.fields["message"]}');
  //     print('   Vehicle: ${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}');
  //     print('   Has Image: ${userImage != null}');
  //     print('   Session ID: $_sessionId');
  //     print('   Requires CV Analysis: ${userImage != null}');

  //     // Add image with proper metadata and CV-specific handling
  //     if (userImage != null) {
  //       print('📸 Adding image to request for CV analysis: ${userImage.path}');
        
  //       final fileExtension = userImage.path.split('.').last.toLowerCase();
  //       final mimeType = _getMimeType(fileExtension);
        
  //       final multipartFile = await http.MultipartFile.fromPath(
  //         'image',
  //         userImage.path,
  //         contentType: MediaType('image', mimeType),
  //         filename: 'vehicle_${_selectedVehicle!['brand']}_${_selectedVehicle!['model']}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
  //       );
  //       request.files.add(multipartFile);
        
  //       final fileSize = userImage.lengthSync();
  //       print('   Image details: ${fileSize ~/ 1024} KB, type: $mimeType');
  //     }

  //     // Send request
  //     print('🚀 Sending request to backend...');
  //     final streamedResponse = await request.send();
  //     final response = await http.Response.fromStream(streamedResponse);

  //     print('📥 Response received:');
  //     print('   Status: ${response.statusCode}');
  //     print('   Body length: ${response.body.length}');

  //     if (response.statusCode == 200) {
  //       try {
  //         final decoded = json.decode(response.body);
  //         print('   Response keys: ${decoded.keys}');
          
  //         // Handle different response formats from CV model
  //         String reply;
  //         if (decoded.containsKey("reply")) {
  //           reply = decoded["reply"];
  //         } else if (decoded.containsKey("analysis_result")) {
  //           reply = decoded["analysis_result"];
  //         } else if (decoded.containsKey("message")) {
  //           reply = decoded["message"];
  //         } else if (decoded.containsKey("response")) {
  //           reply = decoded["response"];
  //         } else if (decoded.containsKey("cv_analysis")) {
  //           reply = _formatCVResponse(decoded["cv_analysis"]);
  //         } else {
  //           reply = "I've processed your request. ${userImage != null ? 'The image analysis is complete.' : 'How can I help you further?'}";
  //         }

  //         // Add bot response to chat
  //         setState(() {
  //           _allSessions[_activeSessionId]!.add({
  //             "text": reply,
  //             "isSent": false,
  //             "timestamp": DateTime.now().toIso8601String(),
  //             "isImageAnalysis": userImage != null,
  //             "cvAnalysis": userImage != null,
  //           });
  //         });
          
  //         await _saveSessions();
          
  //         // Show success for image analysis
  //         if (userImage != null) {
  //           Get.snackbar(
  //             "Image Analysis Complete",
  //             "CV model has processed your vehicle image",
  //             backgroundColor: Colors.green,
  //             colorText: Colors.white,
  //             duration: Duration(seconds: 3),
  //           );
  //         }
          
  //       } catch (e) {
  //         print('❌ JSON parsing error: $e');
  //         _handleErrorResponse("Failed to parse server response: $e");
  //       }
  //     } else if (response.statusCode == 422) {
  //       _handleValidationError(response.body);
  //     } else {
  //       _handleErrorResponse("Server error: ${response.statusCode}\n${response.body}");
  //     }
  //   } catch (e) {
  //     print('❌ Network error: $e');
  //     _handleErrorResponse("Network error: ${e.toString()}");
  //   } finally {
  //     setState(() {
  //       _isProcessing = false;
  //     });
  //   }
  // }

Future<void> sendMessage() async {
  if (_selectedVehicle == null) {
    Get.snackbar(
      "Select Vehicle",
      "Please choose a vehicle",
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
    return;
  }
  
  final text = _controller.text.trim();
  final vehicleId = _selectedVehicle!["_id"];

  // Validate input
  if (text.isEmpty && _selectedImage == null) {
    Get.snackbar(
      "Empty Message",
      "Please enter a message or select an image",
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }

  // Ensure session exists
  if (_activeSessionId == null) {
    await _activateVehicleSession(vehicleId);
  }

  // Store user input temporarily
  final userText = text;
  final userImage = _selectedImage;

  // Clear input immediately and show loader
  setState(() {
    _controller.clear();
    _selectedImage = null;
    _isProcessing = true;
  });

  // Add user message locally with image preview
  final userMessage = {
    "text": userText,
    "isSent": true,
    "vehicleId": vehicleId,
    "brand": _selectedVehicle?['brand'],
    "model": _selectedVehicle?['model'],
    "timestamp": DateTime.now().toIso8601String(),
  };

  // Add image path to message if image exists
  if (userImage != null) {
    userMessage["imagePath"] = userImage.path;
    userMessage["hasImage"] = true;
  }

  setState(() {
    _allSessions[_activeSessionId]!.add(userMessage);
  });
  await _saveSessions();

  // Send to backend with enhanced error handling
  try {
    final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
    
    // Add headers
    request.headers["Authorization"] = "$_tokenType $_accessToken";
    request.headers["Accept"] = "application/json";

    // Add session and message data
    if (_sessionId != null) {
      request.fields["session_id"] = _sessionId!;
    }
    
    // ✅ CRITICAL FIX: Always send message field with proper context
    if (userText.isNotEmpty) {
      request.fields["message"] = userText;
    } else {
      // If only image is sent, provide context for CV model
      request.fields["message"] = "Analyze this vehicle image for any visible issues, damage, or maintenance needs";
    }
    
    // ✅ ENHANCED: Send vehicle data as proper JSON
    request.fields["vehicle_json"] = json.encode(_selectedVehicle);

    print('📤 Sending chat message:');
    print('   Message: ${request.fields["message"]}');
    print('   Vehicle: ${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}');
    print('   Has Image: ${userImage != null}');
    print('   Session ID: $_sessionId');

    // ✅ ENHANCED: Add image with proper field name and handling
    if (userImage != null) {
      print('📸 Adding image to request: ${userImage.path}');
      
      // Get file extension and mime type
      final fileExtension = userImage.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(fileExtension);
      
      // ✅ CRITICAL: Use the exact field name expected by FastAPI - 'image'
      final multipartFile = await http.MultipartFile.fromPath(
        'image', // This MUST be 'image' to match FastAPI parameter
        userImage.path,
        contentType: MediaType('image', mimeType),
        filename: 'vehicle_${_selectedVehicle!['brand']}_${_selectedVehicle!['model']}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
      );
      request.files.add(multipartFile);
      
      final fileSize = userImage.lengthSync();
      print('   Image details: ${fileSize ~/ 1024} KB, type: $mimeType');
      print('   Field name: image');
    }

    // Send request with timeout
    print('🚀 Sending request to backend...');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📥 Response received:');
    print('   Status: ${response.statusCode}');
    print('   Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body);
        print('   Response keys: ${decoded.keys}');
        
        // ✅ ENHANCED: Handle different response formats
        String reply;
        if (decoded.containsKey("reply")) {
          reply = decoded["reply"];
        } else if (decoded.containsKey("message")) {
          reply = decoded["message"];
        } else if (decoded.containsKey("response")) {
          reply = decoded["response"];
        } else if (decoded.containsKey("analysis")) {
          reply = decoded["analysis"];
        } else {
          // If no specific field found, try to get the first string value
          reply = _extractReplyFromResponse(decoded);
        }

        // Add bot response to chat
        setState(() {
          _allSessions[_activeSessionId]!.add({
            "text": reply,
            "isSent": false,
            "timestamp": DateTime.now().toIso8601String(),
            "isImageAnalysis": userImage != null,
            "cvAnalysis": userImage != null,
          });
        });
        
        await _saveSessions();
        
        // Show success for image analysis
        if (userImage != null) {
          Get.snackbar(
            "Image Analysis Complete",
            "FixiBot has processed your vehicle image",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
        }
        
      } catch (e) {
        print('❌ JSON parsing error: $e');
        print('   Raw response: ${response.body}');
        _handleErrorResponse("Failed to parse server response: $e");
      }
    } else if (response.statusCode == 422) {
      // Handle validation errors from FastAPI
      print('❌ FastAPI Validation Error: ${response.body}');
      _handleValidationError(response.body);
    } else if (response.statusCode == 415) {
      _handleErrorResponse("Unsupported media type. The image format may not be supported.");
    } else if (response.statusCode == 413) {
      _handleErrorResponse("Image file too large. Please select a smaller image.");
    } else {
      print('❌ Server error: ${response.statusCode}');
      _handleErrorResponse("Server error: ${response.statusCode}\n${response.body}");
    }
  } catch (e) {
    print('❌ Network error: $e');
    _handleErrorResponse("Network error: ${e.toString()}");
  } finally {
    setState(() {
      _isProcessing = false;
    });
  }
}

// Helper method to extract reply from various response formats
String _extractReplyFromResponse(Map<String, dynamic> response) {
  try {
    // Try to find any string value in the response
    for (var value in response.values) {
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    
    // If no string found, return the entire response as string
    return response.toString();
  } catch (e) {
    return "I've processed your request. How can I help you further?";
  }
}


  String _getMimeType(String fileExtension) {
    switch (fileExtension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg';
    }
  }

  String _formatCVResponse(dynamic cvAnalysis) {
    if (cvAnalysis is String) {
      return cvAnalysis;
    } else if (cvAnalysis is Map) {
      final issues = cvAnalysis['issues'] ?? [];
      final confidence = cvAnalysis['confidence'] ?? 0.0;
      final recommendations = cvAnalysis['recommendations'] ?? [];
      
      String response = "🔍 **Vehicle Image Analysis Complete**\n\n";
      
      if (issues.isNotEmpty) {
        response += "**Detected Issues:**\n";
        for (var issue in issues) {
          response += "• $issue\n";
        }
      } else {
        response += "✅ No major issues detected.\n";
      }
      
      if (recommendations.isNotEmpty) {
        response += "\n**Recommendations:**\n";
        for (var rec in recommendations) {
          response += "• $rec\n";
        }
      }
      
      response += "\n_Confidence: ${(confidence * 100).toStringAsFixed(1)}%_";
      return response;
    }
    
    return "I've analyzed your vehicle image. Please describe any specific concerns you have.";
  }

  void _handleValidationError(String errorBody) {
    try {
      final decoded = json.decode(errorBody);
      final details = decoded['detail'];
      String errorMessage = "Validation error: ";
      
      if (details is List) {
        for (var detail in details) {
          errorMessage += "${detail['msg']} (${detail['loc']}); ";
        }
      } else {
        errorMessage += "Invalid request format";
      }
      
      _handleErrorResponse(errorMessage);
    } catch (e) {
      _handleErrorResponse("Request validation failed: $errorBody");
    }
  }

  void _handleErrorResponse(String error) {
    print('❌ Chat error: $error');
    
    setState(() {
      _allSessions[_activeSessionId]!.add({
        "text": "⚠️ **FixiBot Error**\n\nI encountered an issue while processing your request.\n\n**Error Details:** $error\n\nPlease try again or contact support if the problem persists.",
        "isSent": false,
        "isError": true,
        "timestamp": DateTime.now().toIso8601String(),
      });
    });
    
    Get.snackbar(
      "Processing Error",
      "Failed to process your message",
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 5),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      if (file != null) {
        final imageFile = File(file.path);
        
        // Validate file size (max 5MB)
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          Get.snackbar(
            "File Too Large",
            "Please select an image smaller than 5MB",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }
        
        setState(() => _selectedImage = imageFile);
        
        // Auto-focus on text input after image selection
        FocusScope.of(context).requestFocus(FocusNode());
        Future.delayed(Duration(milliseconds: 100), () {
          FocusScope.of(context).requestFocus(FocusNode());
        });
        
        print('📸 Image selected: ${file.path} (${fileSize ~/ 1024} KB)');
      }
    } catch (e) {
      print('❌ Image picker error: $e');
      Get.snackbar(
        "Error",
        "Failed to pick image: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /* ----------------- UI ------------------ */

  Widget _buildMessageBubble(Map<String, dynamic> m) {
    final isUser = m["isSent"] == true;
    final hasImage = m["hasImage"] == true;
    final isError = m["isError"] == true;
    final isCVAnalysis = m["cvAnalysis"] == true;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError 
            ? Colors.orange.shade100
            : isCVAnalysis
              ? Colors.blue.shade50
              : isUser 
                ? AppColors.mainColor 
                : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          border: isError 
            ? Border.all(color: Colors.orange)
            : isCVAnalysis
              ? Border.all(color: Colors.blue.shade200)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display image if message has one
            if (hasImage && m.containsKey("imagePath"))
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(m["imagePath"]),
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey, size: 40),
                              SizedBox(height: 8),
                              Text("Image not available", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            
            // Display text message
            if (m.containsKey("text") && m["text"].toString().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: hasImage ? 4 : 0),
                child: SelectableText(
                  m["text"],
                  style: TextStyle(
                    color: isError 
                      ? Colors.orange.shade900
                      : isCVAnalysis
                        ? Colors.blue.shade900
                        : isUser 
                          ? Colors.white 
                          : Colors.black87,
                    fontWeight: isError || isCVAnalysis ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            
            // Show analysis type indicator
            if ((isCVAnalysis || m["isImageAnalysis"] == true) && !isUser)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      isCVAnalysis ? Icons.analytics : Icons.photo_library, 
                      size: 12, 
                      color: isCVAnalysis ? Colors.blue : Colors.green
                    ),
                    SizedBox(width: 4),
                    Text(
                      isCVAnalysis ? "CV Analysis" : "Image Analysis",
                      style: TextStyle(
                        fontSize: 10,
                        color: isCVAnalysis ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _activeSessionId != null ? _allSessions[_activeSessionId] ?? [] : [];

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: CustomAppBar(
        title: "FixiBot",
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.secondaryColor),
            onPressed: () {
              Get.to(ChatHistoryScreen(
                sessions: _allSessions,
                onOpenSession: (id) async {
                  setState(() => _activeSessionId = id);
                  final sp = await SharedPreferences.getInstance();
                  await sp.setString(kCurrentSessionKey, id);
                },
                onDeleteSession: (id) => onDelete(id),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_comment, color: AppColors.secondaryColor),
            tooltip: "New Chat",
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              "Select the vehicle to resolve an issue:",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.mainColor,
              ),
            ),
          ),

          // Vehicle chips with correct icons
          Obx(() {
            final vehicles = vehicleController.userVehicles;
            if (vehicles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text("No vehicles added.",
                    style: TextStyle(color: AppColors.mainColor)),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: vehicles.map((v) {
                  final selected = _selectedVehicle != null &&
                      _selectedVehicle!["_id"] == v["_id"];
                  return GestureDetector(
                    onTap: () async {
                      setState(() => _selectedVehicle = Map.from(v));
                      await _activateVehicleSession(v["_id"]);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.mainColor
                            : AppColors.secondaryColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Row(
                        children: [
                          Icon(_getVehicleIcon(v),
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : AppColors.mainColor),
                          const SizedBox(width: 6),
                          Text("${v['brand']} ${v['model']}",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.mainColor,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          // Chat messages with loading indicator
          Expanded(
            child: Column(
              children: [
                // Messages list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
                  ),
                ),
                
                // Loading indicator
                if (_isProcessing)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.mainColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "FixiBot is thinking...",
                          style: TextStyle(
                            color: AppColors.mainColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Chat input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.mainColor.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle chip or Image preview
                        if (_selectedVehicle != null || _selectedImage != null)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 4, top: 8, bottom: 6),
                            child: Row(
                              children: [
                                if (_selectedVehicle != null)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.mainSwatch.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_getVehicleIcon(_selectedVehicle!),
                                            size: 14,
                                            color: AppColors.mainColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.mainColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() => _selectedVehicle = null);
                                            _activeSessionId = null;
                                          },
                                          child: const Icon(Icons.close,
                                              size: 14,
                                              color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_selectedImage != null)
                                  Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.file(
                                          _selectedImage!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => _selectedImage = null);
                                        },
                                        child: const CircleAvatar(
                                          radius: 8,
                                          backgroundColor: Colors.black54,
                                          child: Icon(Icons.close,
                                              size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        // Text input row
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.camera_alt_rounded,
                                  color: AppColors.mainColor),
                              onPressed: _pickImage,
                            ),
                            Flexible(
                              flex: 2,
                              child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Type your message...",
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 8),
                                ),
                                minLines: 1,
                                maxLines: 4,
                              ),
                            ),
                            IconButton(
                              icon: _isProcessing
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.mainColor),
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded,
                                      color: AppColors.mainColor),
                              onPressed: _isProcessing ? null : sendMessage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}















//text based perfect
// import 'dart:convert';
// import 'dart:io';
// import 'package:fixibot_app/constants/appConfig.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:fixibot_app/screens/chatbot/chatviewHistory.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:fixibot_app/screens/auth/controller/google_sign_in_helper.dart';

// /// Keys to store/retrieve persistent data
// const String kSessionsKey = "all_chat_sessions";
// const String kCurrentSessionKey = "current_session_id";

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final VehicleController vehicleController = Get.find<VehicleController>();
//   final SharedPrefsHelper _prefs = SharedPrefsHelper();
//   final TextEditingController _controller = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
// final baseUrl  = AppConfig.baseUrl;


//   // Auth & session
//   String? _accessToken;
//   String? _tokenType;
//   String? _sessionId;

//   // UI / chat state
//   File? _selectedImage;
//   Map<String, dynamic>? _selectedVehicle;
//   bool _isProcessing = false;

//   /// All sessions are stored here:
//   /// key = sessionId, value = list of message maps
//   Map<String, List<Map<String, dynamic>>> _allSessions = {};
//   String? _activeSessionId;

//   @override
//   void initState() {
//     super.initState();
//     vehicleController.fetchUserVehicles();
//     _initAuth();
//     _loadSessions();
//   }

//   /* ----------------- Persistent Sessions ------------------ */

//   Future<void> _loadSessions() async {
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(kSessionsKey);
//     final currentId = sp.getString(kCurrentSessionKey);

//     if (stored != null) {
//       final Map<String, dynamic> decoded = jsonDecode(stored);
//       _allSessions = decoded.map(
//           (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
//     }

//     if (currentId != null && _allSessions.containsKey(currentId)) {
//       _activeSessionId = currentId;
//     } else {
//       _startNewLocalSession();
//     }
//     setState(() {});
//   }

//   Future<void> _saveSessions() async {
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(kSessionsKey, jsonEncode(_allSessions));
//     if (_activeSessionId != null) {
//       await sp.setString(kCurrentSessionKey, _activeSessionId!);
//     }
//   }

//   void _startNewLocalSession() {
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//   }

//   Future<void> _startNewChat() async {
//     setState(() {
//       _startNewLocalSession();
//     });
//     await _saveSessions();
//   }

//   // Delete a session
//   Future<void> onDelete(String sessionId) async {
//     setState(() {
//       _allSessions.remove(sessionId);
//       if (_activeSessionId == sessionId) {
//         if (_allSessions.isEmpty) {
//           _startNewLocalSession();
//         } else {
//           _activeSessionId = _allSessions.keys.first;
//         }
//       }
//     });
//     await _saveSessions();
//   }




//   /* ----------------- Backend Auth/Session ------------------ */

// Future<void> _initAuth() async {
//   _accessToken = await _prefs.getString("access_token");
//   _tokenType = await _prefs.getString("token_type");
  
//   print('🔐 Chatbot Auth Check:');
//   print('   Access Token: ${_accessToken != null ? "✅" : "❌"}');
//   print('   Token Type: ${_tokenType ?? "NULL"}');
  
//   // ✅ AUTO-FIX: If token_type is missing but access_token exists (Google user issue)
//   if (_accessToken != null && _accessToken!.isNotEmpty && (_tokenType == null || _tokenType!.isEmpty)) {
//     print('🛠️ Auto-fixing missing token_type for Google user...');
//     await _prefs.saveString('token_type', 'bearer');
//     _tokenType = 'bearer'; // Update local variable
//     print('✅ Auto-fixed: token_type set to "bearer"');
    
//     Get.snackbar(
//       "Ready!", 
//       "Chatbot authentication completed",
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//       duration: Duration(seconds: 2),
//     );
//   }
  
//   if (_accessToken == null || _tokenType == null) {
//     Get.snackbar(
//       "Authentication Required", 
//       "Please login again to use chatbot",
//       backgroundColor: Colors.redAccent, 
//       colorText: Colors.white,
//       duration: Duration(seconds: 5),
//     );
    
//     // ✅ DEBUG: Show what's missing
//     await debugChatbotAuth();
//     return;
//   }
  
//   await _startServerSession();
// }


// // Future<void> _initAuth() async {
// //   _accessToken = await _prefs.getString("access_token");
// //   _tokenType = await _prefs.getString("token_type");
  
// //   print('🔐 Chatbot Auth Check:');
// //   print('   Access Token: ${_accessToken != null ? "✅" : "❌"}');
// //   print('   Token Type: ${_tokenType ?? "NULL"}');
  
// //   if (_accessToken == null || _tokenType == null) {
// //     Get.snackbar(
// //       "Authentication Required", 
// //       "Please login again to use chatbot",
// //       backgroundColor: Colors.redAccent, 
// //       colorText: Colors.white,
// //       duration: Duration(seconds: 5),
// //     );
    
// //     // ✅ DEBUG: Show what's missing
// //     await debugChatbotAuth();
// //     return;
// //   }
  
// //   await _startServerSession();
// // }


// // Add this to your GoogleSignInController or any controller
// Future<void> debugChatbotAuth() async {
//   final prefs = await SharedPreferences.getInstance();
  
//   print('=== CHATBOT AUTH DEBUG ===');
//   print('Access Token: ${prefs.getString('access_token') != null ? "✅ EXISTS" : "❌ MISSING"}');
//   print('Token Type: ${prefs.getString('token_type') ?? "❌ NULL"}');
//   print('User ID: ${prefs.getString('user_id') ?? "❌ NULL"}');
//   print('Email: ${prefs.getString('email') ?? "❌ NULL"}');
  
//   // Check if chatbot requirements are met
//   final hasAccessToken = prefs.getString('access_token') != null;
//   final hasTokenType = prefs.getString('token_type') != null;
//   final hasUserId = prefs.getString('user_id') != null;
  
//   print('Chatbot Ready: ${hasAccessToken && hasTokenType && hasUserId}');
//   print('==========================');
  
//   // Show user-friendly message
//   if (!hasAccessToken || !hasTokenType) {
//     Get.snackbar(
//       "Auth Issue", 
//       "Missing authentication data for chatbot",
//       backgroundColor: Colors.orange,
//       colorText: Colors.white,
//     );
//   }
// }
//   // Future<void> _initAuth() async {
//   //   _accessToken = await _prefs.getString("access_token");
//   //   _tokenType = await _prefs.getString("token_type");
//   //   if (_accessToken == null || _tokenType == null) {
//   //     Get.snackbar("Error", "Authentication required",
//   //         backgroundColor: Colors.redAccent, colorText: Colors.white);
//   //     return;
//   //   }
//   //   await _startServerSession();
//   // }

//   Future<void> _startServerSession() async {
//     try {
//       final res = await http.post(
//         Uri.parse("$baseUrl/chat/start"),
//         headers: {
//           "Content-Type": "application/json",
//           "accept": "application/json",
//           "Authorization": "$_tokenType $_accessToken",
//         },
//       );
//       if (res.statusCode == 201) {
//         final data = json.decode(res.body);
//         _sessionId = data["session_id"];
//         debugPrint("Server chat session started: $_sessionId");
//       }
//     } catch (e) {
//       debugPrint("Server session error: $e");
//     }
//   }

//   /* ----------------- Per-Vehicle Session Logic ------------------ */

//   Future<String?> _getSessionIdForVehicle(String vehicleId) async {
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(kSessionsKey);
//     if (stored == null) return null;

//     final Map<String, dynamic> decoded = jsonDecode(stored);
//     for (var entry in decoded.entries) {
//       final sessionMessages =
//           List<Map<String, dynamic>>.from(entry.value as List);
//       if (sessionMessages.any((m) => m["vehicleId"] == vehicleId)) {
//         return entry.key;
//       }
//     }
//     return null;
//   }

//   Future<String> _createNewSessionForVehicle(String vehicleId) async {
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//     await _saveSessions();
//     return newId;
//   }

//   Future<void> _activateVehicleSession(String vehicleId) async {
//     String? sessionId = await _getSessionIdForVehicle(vehicleId);
//     if (sessionId == null) {
//       sessionId = await _createNewSessionForVehicle(vehicleId);
//     }
//     setState(() => _activeSessionId = sessionId);
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(kCurrentSessionKey, sessionId);
//   }

//   // FIX 1: Get correct vehicle icon based on category
//   IconData _getVehicleIcon(Map<String, dynamic> vehicle) {
//     final category = vehicle['category']?.toString().toLowerCase() ?? '';
    
//     switch (category) {
//       case 'car':
//         return Icons.directions_car;
//       case 'motorcycle':
//       case 'bike':
//         return Icons.motorcycle;
//       case 'truck':
//         return Icons.local_shipping;
//       case 'suv':
//         return Icons.airport_shuttle;
//       default:
//         return Icons.directions_car;
//     }
//   }

//   /* ----------------- Message Handling ------------------ */


// /* ----------------- Enhanced Message Handling ------------------ */

// Future<void> sendMessage() async {
//   if (_selectedVehicle == null) {
//     Get.snackbar(
//       "Select Vehicle",
//       "Please choose a vehicle",
//       backgroundColor: Colors.redAccent,
//       colorText: Colors.white,
//     );
//     return;
//   }
  
//   final text = _controller.text.trim();
//   final vehicleId = _selectedVehicle!["_id"];

//   // Validate input
//   if (text.isEmpty && _selectedImage == null) {
//     Get.snackbar(
//       "Empty Message",
//       "Please enter a message or select an image",
//       backgroundColor: Colors.orange,
//       colorText: Colors.white,
//     );
//     return;
//   }

//   // Ensure session exists
//   if (_activeSessionId == null) {
//     await _activateVehicleSession(vehicleId);
//   }

//   // Store user input temporarily
//   final userText = text;
//   final userImage = _selectedImage;

//   // Clear input immediately and show loader
//   setState(() {
//     _controller.clear();
//     _selectedImage = null;
//     _isProcessing = true;
//   });

//   // Add user message locally with image preview
//   final userMessage = {
//     "text": userText,
//     "isSent": true,
//     "vehicleId": vehicleId,
//     "brand": _selectedVehicle?['brand'],
//     "model": _selectedVehicle?['model'],
//     "timestamp": DateTime.now().toIso8601String(),
//   };

//   // Add image path to message if image exists
//   if (userImage != null) {
//     userMessage["imagePath"] = userImage.path;
//     userMessage["hasImage"] = true;
//   }

//   setState(() {
//     _allSessions[_activeSessionId]!.add(userMessage);
//   });
//   await _saveSessions();

//   // Send to backend with enhanced error handling
//   try {
//     final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
    
//     // Add headers
//     request.headers["Authorization"] = "$_tokenType $_accessToken";
//     request.headers["Accept"] = "application/json";

//     // Add session and message data
//     if (_sessionId != null) {
//       request.fields["session_id"] = _sessionId!;
//     }
    
//     // ✅ CRITICAL FIX: Always send message field, even if empty with image
//     request.fields["message"] = userText.isNotEmpty ? userText : "Analyze this vehicle image";
    
//     // ✅ ENHANCED: Send vehicle data as proper JSON
//     request.fields["vehicle_json"] = json.encode(_selectedVehicle);

//     print('📤 Sending chat message:');
//     print('   Message: ${userText.isNotEmpty ? userText : "Image only"}');
//     print('   Vehicle: ${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}');
//     print('   Has Image: ${userImage != null}');
//     print('   Session ID: $_sessionId');

//     // ✅ ENHANCED: Add image with proper metadata
//     if (userImage != null) {
//       print('📸 Adding image to request: ${userImage.path}');
      
//       // Get file extension and mime type
//       final fileExtension = userImage.path.split('.').last.toLowerCase();
//       final mimeType = _getMimeType(fileExtension);
      
//       final multipartFile = await http.MultipartFile.fromPath(
//         'image', // ✅ Field name should match backend expectation
//         userImage.path,
//         contentType: MediaType('image', mimeType),
//         filename: 'vehicle_image_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
//       );
//       request.files.add(multipartFile);
//       print('   Image details: ${userImage.lengthSync()} bytes, type: $mimeType');
//     }

//     // Send request with timeout
//     final response = await request.send().timeout(Duration(seconds: 60));
//     final body = await response.stream.bytesToString();

//     print('📥 Response received:');
//     print('   Status: ${response.statusCode}');
//     print('   Body: $body');

//     if (response.statusCode == 200) {
//       try {
//         final decoded = json.decode(body);
//         final reply = decoded["reply"] ??
//             decoded["message"] ??
//             decoded["response"] ??
//             "I've analyzed your vehicle. How can I help you further?";

//         // Add bot response to chat
//         setState(() {
//           _allSessions[_activeSessionId]!.add({
//             "text": reply,
//             "isSent": false,
//             "timestamp": DateTime.now().toIso8601String(),
//             "isImageAnalysis": userImage != null, // Mark as image analysis response
//           });
//         });
        
//         await _saveSessions();
        
//         // Show success for image analysis
//         if (userImage != null) {
//           Get.snackbar(
//             "Image Analyzed",
//             "FixiBot has processed your vehicle image",
//             backgroundColor: Colors.green,
//             colorText: Colors.white,
//             duration: Duration(seconds: 2),
//           );
//         }
        
//       } catch (e) {
//         print('❌ JSON parsing error: $e');
//         _handleErrorResponse("Failed to parse server response");
//       }
//     } else {
//       _handleErrorResponse("Server error: ${response.statusCode}\n$body");
//     }
//   } catch (e) {
//     print('❌ Network error: $e');
//     _handleErrorResponse("Network error: ${e.toString()}");
//   } finally {
//     // Stop loading regardless of success/error
//     setState(() {
//       _isProcessing = false;
//     });
//   }
// }

// // Helper method to get MIME type
// String _getMimeType(String fileExtension) {
//   switch (fileExtension) {
//     case 'jpg':
//     case 'jpeg':
//       return 'jpeg';
//     case 'png':
//       return 'png';
//     case 'gif':
//       return 'gif';
//     case 'webp':
//       return 'webp';
//     default:
//       return 'jpeg';
//   }
// }

// // Enhanced error handling
// void _handleErrorResponse(String error) {
//   print('❌ Chat error: $error');
  
//   // Add error message to chat
//   setState(() {
//     _allSessions[_activeSessionId]!.add({
//       "text": "⚠️ Sorry, I encountered an error. Please try again.\n\nError: $error",
//       "isSent": false,
//       "isError": true,
//       "timestamp": DateTime.now().toIso8601String(),
//     });
//   });
  
//   Get.snackbar(
//     "Error",
//     "Failed to send message",
//     backgroundColor: Colors.red,
//     colorText: Colors.white,
//     duration: Duration(seconds: 3),
//   );
// }
  
// Future<void> _pickImage() async {
//   try {
//     final XFile? file = await _picker.pickImage(
//       source: ImageSource.gallery, 
//       imageQuality: 85,
//       maxWidth: 1200,
//       maxHeight: 1200,
//     );
    
//     if (file != null) {
//       final imageFile = File(file.path);
      
//       // Validate file size (max 5MB)
//       final fileSize = await imageFile.length();
//       if (fileSize > 5 * 1024 * 1024) {
//         Get.snackbar(
//           "File Too Large",
//           "Please select an image smaller than 5MB",
//           backgroundColor: Colors.orange,
//           colorText: Colors.white,
//         );
//         return;
//       }
      
//       setState(() => _selectedImage = imageFile);
      
//       // Auto-focus on text input after image selection
//       FocusScope.of(context).requestFocus(FocusNode());
//       Future.delayed(Duration(milliseconds: 100), () {
//         FocusScope.of(context).requestFocus(FocusNode());
//       });
      
//       print('📸 Image selected: ${file.path} (${fileSize ~/ 1024} KB)');
//     }
//   } catch (e) {
//     print('❌ Image picker error: $e');
//     Get.snackbar(
//       "Error",
//       "Failed to pick image: ${e.toString()}",
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//     );
//   }
// }


//   /* ----------------- UI ------------------ */

//   @override
//   Widget build(BuildContext context) {
//     final messages =
//         _activeSessionId != null ? _allSessions[_activeSessionId] ?? [] : [];

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: CustomAppBar(
//         title: "FixiBot",
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.history, color: AppColors.secondaryColor),
//             onPressed: () {
//               Get.to(ChatHistoryScreen(
//                 sessions: _allSessions,
//                 onOpenSession: (id) async {
//                   setState(() => _activeSessionId = id);
//                   final sp = await SharedPreferences.getInstance();
//                   await sp.setString(kCurrentSessionKey, id);
//                 },
//                 onDeleteSession: (id) => onDelete(id),
//               ));
//             },
//           ),
//           IconButton(
//             icon:
//                 const Icon(Icons.add_comment, color: AppColors.secondaryColor),
//             tooltip: "New Chat",
//             onPressed: _startNewChat,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child: Text(
//               "Select the vehicle to resolve an issue:",
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.mainColor,
//               ),
//             ),
//           ),

//           // FIX 1: Vehicle chips with correct icons
//           Obx(() {
//             final vehicles = vehicleController.userVehicles;
//             if (vehicles.isEmpty) {
//               return const Padding(
//                 padding: EdgeInsets.all(12.0),
//                 child: Text("No vehicles added.",
//                     style: TextStyle(color: AppColors.mainColor)),
//               );
//             }
//             return SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//               child: Row(
//                 children: vehicles.map((v) {
//                   final selected = _selectedVehicle != null &&
//                       _selectedVehicle!["_id"] == v["_id"];
//                   return GestureDetector(
//                     onTap: () async {
//                       setState(() => _selectedVehicle = Map.from(v));
//                       await _activateVehicleSession(v["_id"]);
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(right: 8),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 14, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: selected
//                             ? AppColors.mainColor
//                             : AppColors.secondaryColor,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: Colors.white),
//                       ),
//                       child: Row(
//                         children: [
//                           // FIX 1: Use correct vehicle icon
//                           Icon(_getVehicleIcon(v),
//                               size: 16,
//                               color: selected
//                                   ? Colors.white
//                                   : AppColors.mainColor),
//                           const SizedBox(width: 6),
//                           Text("${v['brand']} ${v['model']}",
//                               style: TextStyle(
//                                   fontSize: 12,
//                                   color: selected
//                                       ? Colors.white
//                                       : AppColors.mainColor,
//                                   fontWeight: FontWeight.w500)),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             );
//           }),

//           // Chat messages with FIX 2: Better loading indicator
//           Expanded(
//             child: Column(
//               children: [
//                 // Messages list
//                 Expanded(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(10),
//                     itemCount: messages.length,
//                     // itemBuilder: (_, i) {
//                     //   final m = messages[i];
//                     //   final isUser = m["isSent"] == true;
//                     //   return Align(
//                     //     alignment:
//                     //         isUser ? Alignment.centerRight : Alignment.centerLeft,
//                     //     child: Container(
//                     //       margin: const EdgeInsets.symmetric(vertical: 4),
//                     //       padding: const EdgeInsets.all(10),
//                     //       decoration: BoxDecoration(
//                     //         color:
//                     //             isUser ? AppColors.mainColor : Colors.grey.shade300,
//                     //         borderRadius: BorderRadius.circular(12),
//                     //       ),
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           if (m.containsKey("imagePath"))
//                     //             ClipRRect(
//                     //               borderRadius: BorderRadius.circular(8),
//                     //               child: Image.file(
//                     //                 File(m["imagePath"]),
//                     //                 width: 150,
//                     //                 height: 150,
//                     //                 fit: BoxFit.cover,
//                     //               ),
//                     //             ),
//                     //           if (m.containsKey("text"))
//                     //             Padding(
//                     //               padding: const EdgeInsets.only(top: 6),
//                     //               child: Text(
//                     //                 m["text"],
//                     //                 style: TextStyle(
//                     //                     color:
//                     //                         isUser ? Colors.white : Colors.black87),
//                     //               ),
//                     //             ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   );
//                     // },
//                     // In your ListView.builder, replace the itemBuilder with this enhanced version:
// itemBuilder: (_, i) {
//   final m = messages[i];
//   final isUser = m["isSent"] == true;
//   final hasImage = m["hasImage"] == true;
//   final isError = m["isError"] == true;
  
//   return Align(
//     alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//     child: Container(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: isError 
//           ? Colors.orange.shade100
//           : isUser 
//             ? AppColors.mainColor 
//             : Colors.grey.shade300,
//         borderRadius: BorderRadius.circular(12),
//         border: isError 
//           ? Border.all(color: Colors.orange)
//           : null,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Display image if message has one
//           if (hasImage && m.containsKey("imagePath"))
//             Column(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.file(
//                     File(m["imagePath"]),
//                     width: 200,
//                     height: 150,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         width: 200,
//                         height: 150,
//                         color: Colors.grey.shade200,
//                         child: Icon(Icons.broken_image, color: Colors.grey),
//                       );
//                     },
//                   ),
//                 ),
//                 SizedBox(height: 8),
//               ],
//             ),
          
//           // Display text message
//           if (m.containsKey("text") && m["text"].toString().isNotEmpty)
//             Padding(
//               padding: EdgeInsets.only(top: hasImage ? 4 : 0),
//               child: Text(
//                 m["text"],
//                 style: TextStyle(
//                   color: isError 
//                     ? Colors.orange.shade900
//                     : isUser 
//                       ? Colors.white 
//                       : Colors.black87,
//                   fontWeight: isError ? FontWeight.w600 : FontWeight.normal,
//                 ),
//               ),
//             ),
          
//           // Show image analysis indicator
//           if (m["isImageAnalysis"] == true && !isUser)
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Row(
//                 children: [
//                   Icon(Icons.photo_library, size: 12, color: Colors.green),
//                   SizedBox(width: 4),
//                   Text(
//                     "Image Analysis",
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: Colors.green,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     ),
//   );
// }
//                   ),
//                 ),
                
//                 // FIX 2: Improved loading indicator - appears only when processing
//                 if (_isProcessing)
//                   Container(
//                     padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//                     margin: const EdgeInsets.only(bottom: 10),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black12,
//                           blurRadius: 4,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                                 AppColors.mainColor),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Text(
//                           "FixiBot is thinking...",
//                           style: TextStyle(
//                             color: AppColors.mainColor,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           // Chat input
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Expanded(
//                   child: Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: AppColors.mainColor.withOpacity(0.4),
//                       ),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Vehicle chip or Image preview
//                         if (_selectedVehicle != null || _selectedImage != null)
//                           Padding(
//                             padding: const EdgeInsets.only(
//                                 left: 4, top: 8, bottom: 6),
//                             child: Row(
//                               children: [
//                                 if (_selectedVehicle != null)
//                                   Container(
//                                     margin: const EdgeInsets.only(right: 8),
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 10, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       color: AppColors.mainSwatch.shade100,
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         // FIX 1: Use correct vehicle icon in selected chip too
//                                         Icon(_getVehicleIcon(_selectedVehicle!),
//                                             size: 14,
//                                             color: AppColors.mainColor),
//                                         const SizedBox(width: 4),
//                                         Text(
//                                           "${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}",
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             color: AppColors.mainColor,
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 4),
//                                         GestureDetector(
//                                           onTap: () {
//                                             setState(
//                                                 () => _selectedVehicle = null);
//                                             _activeSessionId = null;
//                                           },
//                                           child: const Icon(Icons.close,
//                                               size: 14,
//                                               color: Colors.redAccent),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 if (_selectedImage != null)
//                                   Stack(
//                                     alignment: Alignment.topRight,
//                                     children: [
//                                       ClipRRect(
//                                         borderRadius: BorderRadius.circular(6),
//                                         child: Image.file(
//                                           _selectedImage!,
//                                           width: 50,
//                                           height: 50,
//                                           fit: BoxFit.cover,
//                                         ),
//                                       ),
//                                       GestureDetector(
//                                         onTap: () {
//                                           setState(() => _selectedImage = null);
//                                         },
//                                         child: const CircleAvatar(
//                                           radius: 8,
//                                           backgroundColor: Colors.black54,
//                                           child: Icon(Icons.close,
//                                               size: 12, color: Colors.white),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                               ],
//                             ),
//                           ),
//                         // Text input row
//                         Row(
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.camera_alt_rounded,
//                                   color: AppColors.mainColor),
//                               onPressed: _pickImage,
//                             ),
//                             Flexible(
//                               flex: 2,
//                               child: TextField(
//                                 controller: _controller,
//                                 decoration: const InputDecoration(
//                                   border: InputBorder.none,
//                                   hintText: "Type your message...",
//                                   isDense: true,
//                                   contentPadding: EdgeInsets.symmetric(
//                                       vertical: 8, horizontal: 8),
//                                 ),
//                                 minLines: 1,
//                                 maxLines: 4,
//                               ),
//                             ),
//                             IconButton(
//                               icon: _isProcessing
//                                   ? SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         valueColor: AlwaysStoppedAnimation<Color>(
//                                             AppColors.mainColor),
//                                       ),
//                                     )
//                                   : const Icon(Icons.send_rounded,
//                                       color: AppColors.mainColor),
//                               onPressed: _isProcessing ? null : sendMessage,
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }



