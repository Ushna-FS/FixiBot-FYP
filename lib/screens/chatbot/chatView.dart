
//UI+audio+all languages

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:fixibot_app/screens/chatbot/chatHistoryParent.dart';
import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 🔥 Voice & Permission Imports
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Keys to store/retrieve persistent data - NOW USER-SPECIFIC
String getSessionsKey(String userId) => "all_chat_sessions_$userId";
String getCurrentSessionKey(String userId) => "current_session_id_$userId";
String getSessionLanguageKey(String sessionId) => "session_language_$sessionId";

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
  
  // 🔥 Voice & Language State
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  String? _lastSpokenText;
  
  // Language Mapping (Display Name -> Locale ID)
  final Map<String, String> _languages = {
    'English': 'en-US',
    'Urdu': 'ur-PK',
    'Hindi': 'hi-IN',
    'Punjabi': 'pa-PK',
    'Sindhi': 'sd-PK',
  };
  String _selectedLanguage = 'English';

  final baseUrl = AppConfig.baseUrl;

  // Auth & session
  String? _accessToken;
  String? _tokenType;
  String? _sessionId;
  String? _currentUserId;

  // UI / chat state
  File? _selectedImage;
  Map<String, dynamic>? _selectedVehicle;
  bool _isProcessing = false;
  bool _showLanguageDialog = true;
  bool _isLanguageDialogOpen = false; // 🔥 NEW: Track if dialog is open

  /// All sessions are stored here
  Map<String, List<Map<String, dynamic>>> _allSessions = {};
  String? _activeSessionId;
  
  void _checkAvailableLocales() async {
    bool available = await _speech.initialize();
    if (available) {
      var locales = await _speech.locales();
      print("\n=== AVAILABLE SPEECH LOCALES ===");
      for (var locale in locales) {
        print("Name: ${locale.name}, ID: ${locale.localeId}");
      }
      print("================================\n");
    } else {
      print("Speech recognition not available");
    }
  }
  
  @override
  void initState() {
    super.initState();
    _initializeChatScreen();
    _initVoiceFeatures();
    _checkAvailableLocales();
    _checkForStuckState();
  }

  // 🔥 FIXED: Cleanup TTS resources with proper empty handlers
  void _cleanupTTS() {
    try {
      // Set handlers to empty functions instead of null
      _flutterTts.setCompletionHandler(() {});
      _flutterTts.setCancelHandler(() {});
      _flutterTts.setStartHandler(() {});
      _flutterTts.setErrorHandler((msg) {});
      _flutterTts.setPauseHandler(() {});
      _flutterTts.setContinueHandler(() {});
      
      _flutterTts.stop();
      print('🧹 TTS resources cleaned up');
    } catch (e) {
      print('⚠️ TTS cleanup error: $e');
    }
  }

  @override
  void dispose() {
    _cleanupTTS();
    _flutterTts.stop();
    _speech.cancel();
    super.dispose();
  }

  // 🔥 FIXED: Validate session - ALWAYS START FRESH
  bool _validateSession() {
    // 🔥 CRITICAL FIX: Always start fresh session when chat is opened
    if (_activeSessionId == null) {
      print('🆕 Starting fresh session (no active session)');
      _startFreshSession();
      return false;
    }
    
    if (_allSessions[_activeSessionId] == null) {
      print('🆕 Starting fresh session (session data missing)');
      _startFreshSession();
      return false;
    }
    
    return true;
  }

  // 🔥 NEW: Add timeout for stuck processing state
  void _checkForStuckState() {
    if (_isProcessing) {
      Future.delayed(Duration(seconds: 30), () {
        if (mounted && _isProcessing) {
          print('⚠️ Processing state stuck for 30s, resetting...');
          setState(() {
            _isProcessing = false;
          });
          Get.snackbar(
            "Connection Timeout",
            "Resetting chat session...",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      });
    }
  }

  // 🔥 Initialize STT and TTS
  void _initVoiceFeatures() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    // Default setup
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    // TTS Handlers
    _flutterTts.setCompletionHandler(() {
      print('✅ TTS Completed');
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
        _lastSpokenText = null;
      });
    });

    _flutterTts.setCancelHandler(() {
      print('⏹️ TTS Cancelled');
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    });

    _flutterTts.setStartHandler(() {
      print('▶️ TTS Started');
      setState(() {
        _isSpeaking = true;
        _isPaused = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      print('❌ TTS Error: $msg');
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    });

    _flutterTts.setPauseHandler(() {
      print('⏸️ TTS Paused');
      setState(() {
        _isSpeaking = false;
        _isPaused = true;
      });
    });

    _flutterTts.setContinueHandler(() {
      print('▶️ TTS Continued');
      setState(() {
        _isSpeaking = true;
        _isPaused = false;
      });
    });
  }

  // 🔥 Save language preference for session
  Future<void> _saveSessionLanguage(String sessionId, String language) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(getSessionLanguageKey(sessionId), language);
    print('💾 Saved language "$language" for session: $sessionId');
  }

  // 🔥 Load language preference for session
  Future<String?> _loadSessionLanguage(String sessionId) async {
    final sp = await SharedPreferences.getInstance();
    final language = sp.getString(getSessionLanguageKey(sessionId));
    if (language != null) {
      print('📥 Loaded language "$language" for session: $sessionId');
    }
    return language;
  }

  // 🔥 Handle Language Change (Update TTS Accent)
void _onLanguageChanged(String lang) async {
  print('🌐 Language change requested: $lang');
  print('   Current language: $_selectedLanguage');
  print('   Locale mapping: ${_languages[lang] ?? "en-US"}');
  
  setState(() {
    _selectedLanguage = lang;
  });
  
  // Save language preference for current session
  if (_activeSessionId != null) {
    await _saveSessionLanguage(_activeSessionId!, lang);
    print('💾 Saved language preference for session $_activeSessionId');
  }
  
  String localeId = _languages[lang] ?? 'en-US';
  
  // Check if the language is actually available on the device
  bool isAvailable = await _flutterTts.isLanguageAvailable(localeId);
  
  print('🔍 TTS Language Check:');
  print('   Requested locale: $localeId');
  print('   Available on device: $isAvailable');
  
  if (isAvailable) {
    await _flutterTts.setLanguage(localeId);
    print("🗣️ TTS Language switched to: $lang ($localeId)");
    
    // Test TTS
    await _flutterTts.speak("Language set to $lang");
  } else {
    print("⚠️ TTS language not available: $localeId");
    Get.snackbar(
      "Voice Not Supported", 
      "Your device does not have a text-to-speech voice for $lang. Using English instead.",
      backgroundColor: Colors.orange,
      colorText: Colors.white
    );
    await _flutterTts.setLanguage("en-US");
  }
  
  // Show confirmation
  Get.snackbar(
    "Language Set",
    "Chatbot will respond in $lang",
    backgroundColor: Colors.green,
    colorText: Colors.white,
    duration: Duration(seconds: 2),
  );
}

  // // 🔥 Handle Language Change (Update TTS Accent)
  // void _onLanguageChanged(String lang) async {
  //   setState(() {
  //     _selectedLanguage = lang;
  //   });
    
  //   // Save language preference for current session
  //   if (_activeSessionId != null) {
  //     await _saveSessionLanguage(_activeSessionId!, lang);
  //   }
    
  //   String localeId = _languages[lang] ?? 'en-US';
    
  //   // Check if the language is actually available on the device
  //   bool isAvailable = await _flutterTts.isLanguageAvailable(localeId);
    
  //   if (isAvailable) {
  //     await _flutterTts.setLanguage(localeId);
  //     print("🗣️ Language switched to: $lang ($localeId)");
  //   } else {
  //     Get.snackbar(
  //       "Voice Not Supported", 
  //       "Your device does not have a text-to-speech voice for $lang.",
  //       backgroundColor: Colors.orange,
  //       colorText: Colors.white
  //     );
  //     await _flutterTts.setLanguage("en-US");
  //   }
  // }

  // 🔥 Start Listening (Mic Button)
  void _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        Get.snackbar("Permission Denied", "Microphone access is required.");
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (status) => print('STT Status: $status'),
        onError: (val) => print('STT Error: $val'),
      );

      if (available) {
        setState(() => _isListening = true);
        String localeId = _languages[_selectedLanguage] ?? 'en-US';
        
        _speech.listen(
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
            });
          },
          localeId: localeId,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // 🔥 Simplified Text-to-Speech Logic
  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      String cleanText = text.replaceAll('*', '').replaceAll('#', '');
      _lastSpokenText = cleanText;
      
      await _flutterTts.stop();
      await _flutterTts.speak(cleanText);
      
      setState(() {
        _isSpeaking = true;
        _isPaused = false;
      });
      
      print('🔊 Speaking: ${cleanText.substring(0, min(50, cleanText.length))}...');
    }
  }

  Future<void> _initializeChatScreen() async {
    try {
      print('🔄 Initializing chat screen...');
      
      // Reset states
      setState(() {
        _isProcessing = false;
        _isSpeaking = false;
        _isPaused = false;
        _isListening = false;
        _isLanguageDialogOpen = false; // 🔥 Reset dialog state
      });
      
      await vehicleController.fetchUserVehicles();
      await _initAuth();
      
      // 🔥 CRITICAL CHANGE: Don't load old sessions, always start fresh
      print('🆕 Always starting fresh session when chat is opened');
      _startFreshSession();
      
    } catch (e) {
      print('❌ Error initializing chat screen: $e');
      _startFreshSession();
    }
  }

  // 🔥 SIMPLIFIED: Pause speaking
  void _pauseSpeaking() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
        _isPaused = true;
      });
    }
  }

  // 🔥 SIMPLIFIED: Resume speaking 
  void _resumeSpeaking() async {
    if (_isPaused && _lastSpokenText != null) {
      await _speak(_lastSpokenText!);
    }
  }
  
  // 🔥 Stop speaking (completely)
  void _stopSpeaking() async {
    await _flutterTts.stop();
  }

  /* ----------------- User-Specific Session Management ------------------ */

  Future<void> _loadSessions() async {
    if (_currentUserId == null) return;
    
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getString(getSessionsKey(_currentUserId!));

    if (stored != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(stored);
        _allSessions = decoded.map(
            (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
        print('📥 Loaded ${_allSessions.length} sessions for user: $_currentUserId');
      } catch (e) {
        print('❌ Error loading sessions: $e');
        _allSessions = {};
      }
    } else {
      _allSessions = {};
    }
  }

  Future<void> _saveSessions() async {
    if (_currentUserId == null) return;
    
    final sp = await SharedPreferences.getInstance();
    await sp.setString(getSessionsKey(_currentUserId!), jsonEncode(_allSessions));
    if (_activeSessionId != null) {
      await sp.setString(getCurrentSessionKey(_currentUserId!), _activeSessionId!);
    }
    print('💾 Saved ${_allSessions.length} sessions for user: $_currentUserId');
  }

  void _startFreshSession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _allSessions[newId] = []; // 🔥 Start with empty session
      _activeSessionId = newId;
      _selectedVehicle = null; 
      _selectedImage = null; 
      _showLanguageDialog = true;
      _isLanguageDialogOpen = false; // 🔥 Reset dialog state
    });
    print('🆕 Started fresh session: $newId for user: $_currentUserId');
    
    // 🔥 Show language dialog immediately for new session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showLanguageDialog && !_isLanguageDialogOpen) {
        _showLanguageSelectionDialog();
      }
    });
  }



  // 🔥 FIXED: Show language selection dialog with LayoutBuilder for responsiveness
void _showLanguageSelectionDialog() {
  if (_isLanguageDialogOpen) {
    print('⚠️ Language dialog already open, skipping...');
    return;
  }
  
  setState(() {
    _isLanguageDialogOpen = true;
  });
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 🔥 USE CONSTRAINTS FOR RESPONSIVENESS
              final maxWidth = constraints.maxWidth;
              final maxHeight = constraints.maxHeight;
              
              // 🔥 DETERMINE DEVICE TYPE BASED ON WIDTH
              bool isPhone = maxWidth < 600;
              bool isTablet = maxWidth >= 600 && maxWidth < 900;
              bool isDesktop = maxWidth >= 900;
              
              // 🔥 ADAPTIVE VALUES
              double dialogPadding = isPhone ? 16.0 : 
                                   isTablet ? 24.0 : 
                                   32.0;
              
              double titleFontSize = isPhone ? 18.0 : 
                                   isTablet ? 22.0 : 
                                   26.0;
              
              double contentFontSize = isPhone ? 14.0 : 
                                     isTablet ? 16.0 : 
                                     18.0;
              
              double buttonHeight = isPhone ? 48.0 : 
                                  isTablet ? 56.0 : 
                                  64.0;
              
              double buttonFontSize = isPhone ? 15.0 : 
                                    isTablet ? 17.0 : 
                                    19.0;
              
              double iconSize = isPhone ? 22.0 : 
                              isTablet ? 26.0 : 
                              30.0;
              
              double spacing = isPhone ? 8.0 : 
                             isTablet ? 12.0 : 
                             16.0;
              
              return Container(
                constraints: BoxConstraints(
                  maxWidth: isPhone ? maxWidth * 0.9 :
                           isTablet ? maxWidth * 0.8 :
                           maxWidth * 0.6,
                  maxHeight: maxHeight * 0.8,
                ),
                padding: EdgeInsets.all(dialogPadding),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🔥 TITLE ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.language, 
                            color: AppColors.mainColor,
                            size: iconSize,
                          ),
                          SizedBox(width: spacing),
                          Flexible(
                            child: Text(
                              "Select Language",
                              style: TextStyle(
                                color: AppColors.mainColor,
                                fontWeight: FontWeight.bold,
                                fontSize: titleFontSize,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: spacing * 2),
                      
                      // 🔥 DESCRIPTION
                      Text(
                        "Choose your preferred language for this chat session. "
                        "This will be used for both voice input and chatbot responses.",
                        style: TextStyle(
                          fontSize: contentFontSize,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: spacing * 2),
                      
                      // 🔥 LANGUAGE BUTTONS GRID (FOR TABLETS/DESKTOPS)
                      if (isTablet || isDesktop)
                        GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: isTablet ? 2 : 3,
                          childAspectRatio: 3.0,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          children: _languages.keys.map((language) {
                            return _buildLanguageButton(
                              language: language,
                              buttonHeight: buttonHeight,
                              buttonFontSize: buttonFontSize,
                              isPhone: isPhone,
                            );
                          }).toList(),
                        )
                      else
                      // 🔥 LANGUAGE BUTTONS COLUMN (FOR PHONES)
                        Column(
                          children: _languages.keys.map((language) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: spacing),
                              child: _buildLanguageButton(
                                language: language,
                                buttonHeight: buttonHeight,
                                buttonFontSize: buttonFontSize,
                                isPhone: isPhone,
                              ),
                            );
                          }).toList(),
                        ),
                      
                      SizedBox(height: spacing * 2),
                      
                      // 🔥 INFO BOX
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(spacing),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline, 
                              size: iconSize * 0.7, 
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: spacing),
                            Expanded(
                              child: Text(
                                "You can change language anytime from settings",
                                style: TextStyle(
                                  fontSize: contentFontSize * 0.85,
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  ).then((value) {
    setState(() {
      _isLanguageDialogOpen = false;
    });
  });
}

// 🔥 HELPER METHOD: Build responsive language button
Widget _buildLanguageButton({
  required String language,
  required double buttonHeight,
  required double buttonFontSize,
  required bool isPhone,
}) {
  return SizedBox(
    width: double.infinity,
    height: buttonHeight,
    child: ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
        setState(() {
          _isLanguageDialogOpen = false;
          _showLanguageDialog = false;
        });
        if (_activeSessionId != null) {
    _saveSessionLanguage(_activeSessionId!, language);
  }
        _onLanguageChanged(language);
        
        Get.snackbar(
          "Language Set",
          "Chatbot will respond in $language",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedLanguage == language 
            ? AppColors.mainColor 
            : AppColors.secondaryColor,
        foregroundColor: _selectedLanguage == language 
            ? Colors.white 
            : AppColors.mainColor,
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 12 : 20,
          vertical: isPhone ? 10 : 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isPhone ? 8 : 12),
        ),
        elevation: 2,
      ),
      child: Text(
        language,
        style: TextStyle(
          fontSize: buttonFontSize,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}


  // // 🔥 FIXED: Show language selection dialog with proper state management
  // void _showLanguageSelectionDialog() {
  //   if (_isLanguageDialogOpen) {
  //     print('⚠️ Language dialog already open, skipping...');
  //     return;
  //   }
    
  //   setState(() {
  //     _isLanguageDialogOpen = true;
  //   });
    
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       return WillPopScope(
  //         onWillPop: () async {
  //           // Prevent closing by back button - user must select language
  //           return false;
  //         },
  //         child: AlertDialog(
  //           title: Row(
  //             children: [
  //               Icon(Icons.language, color: AppColors.mainColor),
  //               SizedBox(width: 10),
  //               Text(
  //                 "Select Language",
  //                 style: TextStyle(
  //                   color: AppColors.mainColor,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           content: Text(
  //             "Choose your preferred language for this chat session. "
  //             "This will be used for both voice input and chatbot responses.",
  //             style: TextStyle(fontSize: 14),
  //           ),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(15),
  //           ),
  //           backgroundColor: Colors.white,
  //           actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //           actions: [
  //             Column(
  //               children: [
  //                 // Language options as buttons
  //                 ..._languages.keys.map((language) {
  //                   return Padding(
  //                     padding: const EdgeInsets.symmetric(vertical: 4.0),
  //                     child: SizedBox(
  //                       width: double.infinity,
  //                       child: ElevatedButton(
  //                         onPressed: () {
  //                           // 🔥 CRITICAL: Close dialog first, then change language
  //                           Navigator.of(context).pop();
  //                           setState(() {
  //                             _isLanguageDialogOpen = false;
  //                             _showLanguageDialog = false;
  //                           });
  //                           _onLanguageChanged(language);
                            
  //                           Get.snackbar(
  //                             "Language Set",
  //                             "Chatbot will respond in $language",
  //                             backgroundColor: Colors.green,
  //                             colorText: Colors.white,
  //                             duration: Duration(seconds: 2),
  //                           );
  //                         },
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: _selectedLanguage == language 
  //                               ? AppColors.mainColor 
  //                               : AppColors.secondaryColor,
  //                           foregroundColor: _selectedLanguage == language 
  //                               ? Colors.white 
  //                               : AppColors.mainColor,
  //                           padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(10),
  //                           ),
  //                           elevation: 2,
  //                         ),
  //                         child: Text(
  //                           language,
  //                           style: TextStyle(
  //                             fontSize: 16,
  //                             fontWeight: FontWeight.w500,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   );
  //                 }).toList(),
                  
  //                 SizedBox(height: 10),
                  
  //                 // Language indicator chip
  //                 Container(
  //                   padding: EdgeInsets.all(10),
  //                   decoration: BoxDecoration(
  //                     color: Colors.grey.shade100,
  //                     borderRadius: BorderRadius.circular(10),
  //                     border: Border.all(color: Colors.grey.shade300),
  //                   ),
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       Icon(Icons.info_outline, size: 16, color: Colors.grey),
  //                       SizedBox(width: 8),
  //                       Flexible(
  //                         child: Text(
  //                           "You can change language anytime from settings",
  //                           style: TextStyle(
  //                             fontSize: 12,
  //                             color: Colors.grey.shade700,
  //                           ),
  //                           textAlign: TextAlign.center,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   ).then((value) {
  //     // 🔥 Dialog closed callback
  //     setState(() {
  //       _isLanguageDialogOpen = false;
  //     });
  //   });
  // }

  // 🔥 NEW: Change language button in app bar
  Widget _buildLanguageChangeButton() {
    return IconButton(
      icon: Stack(
        children: [
          Icon(Icons.language, color: AppColors.secondaryColor),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: BoxConstraints(
                minWidth: 12,
                minHeight: 12,
              ),
              child: Text(
                _selectedLanguage.substring(0, 1),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      tooltip: "Change Language ($_selectedLanguage)",
      onPressed: () {
        _showLanguageSelectionDialog();
      },
    );
  }

  void _startNewLocalSession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _allSessions[newId] = [];
    _activeSessionId = newId;
  }

  // 🔥 FIXED: Start new chat with proper cleanup
  Future<void> _startNewChat() async {
    _cleanupTTS();
    
    setState(() {
      _startNewLocalSession();
      _selectedVehicle = null; 
      _selectedImage = null;
      _isSpeaking = false;
      _isPaused = false;
      _isListening = false;
      _lastSpokenText = null;
      _showLanguageDialog = true;
      _isLanguageDialogOpen = false;
    });
    
    await _saveSessions();
    
    // Show language dialog for new chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showLanguageDialog && !_isLanguageDialogOpen) {
        _showLanguageSelectionDialog();
      }
    });
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
    
    try {
      if (Get.isRegistered<ChatManagerProvider>()) {
        final chatManager = Get.find<ChatManagerProvider>();
        if (chatManager.sessionExists(sessionId)) {
          chatManager.deleteSession(sessionId);
          print('✅ Session deleted from ChatManagerProvider: $sessionId');
        }
      }
    } catch (e) {
      print('❌ Error deleting from ChatManagerProvider: $e');
    }
  }

  /* ----------------- Backend Auth/Session ------------------ */

  Future<void> _initAuth() async {
    try {
      print('🔄 Starting authentication initialization...');
      
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _tokenType = prefs.getString('token_type');
      _currentUserId = prefs.getString('user_id');
      
      print('🔐 Chatbot Auth Check:');
      print('   User ID: ${_currentUserId ?? "❌ NULL"}');
      print('   Access Token: ${_accessToken != null ? "✅ EXISTS" : "❌ MISSING"}');
      print('   Token Type: ${_tokenType ?? "❌ NULL"}');
      
      bool needsFix = false;
      
      if (_accessToken != null && _accessToken!.isNotEmpty && (_tokenType == null || _tokenType!.isEmpty)) {
        print('🛠️ Auto-fixing missing token_type for Google user...');
        await prefs.setString('token_type', 'bearer');
        _tokenType = 'bearer';
        needsFix = true;
        print('✅ Fixed: token_type set to "bearer"');
      }
      
      if (_accessToken != null && _accessToken!.isEmpty) {
        print('🛠️ Auto-fixing empty access_token...');
        _accessToken = null;
        needsFix = true;
        print('✅ Fixed: cleared empty access_token');
      }
      
      if (_currentUserId != null && (_accessToken == null || _tokenType == null)) {
        print('🛠️ User ID exists but auth tokens missing');
        final userEmail = prefs.getString('email');
        if (userEmail != null) {
          print('   Found user email: $userEmail - but tokens are missing');
          needsFix = true;
        }
      }
      
      if (needsFix) {
        Get.snackbar(
          "Authentication Updated", 
          "Chatbot is now ready to use!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      }
      
      final hasValidAuth = _accessToken != null && 
                          _accessToken!.isNotEmpty && 
                          _tokenType != null && 
                          _tokenType!.isNotEmpty &&
                          _currentUserId != null;
      
      if (!hasValidAuth) {
        print('❌ INCOMPLETE AUTHENTICATION DATA:');
        print('   Access Token: ${_accessToken ?? "NULL"}');
        print('   Token Type: ${_tokenType ?? "NULL"}');
        print('   User ID: ${_currentUserId ?? "NULL"}');
        
        String errorMessage = "Missing authentication data:\n";
        if (_accessToken == null) errorMessage += "• Access Token\n";
        if (_tokenType == null) errorMessage += "• Token Type\n";
        if (_currentUserId == null) errorMessage += "• User ID\n";
        
        Get.snackbar(
          "Authentication Required", 
          errorMessage,
          backgroundColor: Colors.redAccent, 
          colorText: Colors.white,
          duration: Duration(seconds: 8),
          isDismissible: true,
        );
        
        await _deepDebugAuth();
        return;
      }
      
      print('✅ Authentication validated successfully');
      print('   Final Auth Header: "$_tokenType $_accessToken"');
      
      await _startServerSession();
      
    } catch (e) {
      print('❌ CRITICAL ERROR in _initAuth: $e');
      Get.snackbar(
        "Authentication Error", 
        "Failed to initialize authentication: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    }
  }

  /// 🔥 NEW: Deep authentication debugging
  Future<void> _deepDebugAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      print('\n=== 🔍 DEEP AUTH DEBUG ===');
      
      final allKeys = prefs.getKeys();
      final authKeys = allKeys.where((key) => 
        key.contains('token') || 
        key.contains('user') || 
        key.contains('auth') || 
        key.contains('email') ||
        key.contains('login')
      ).toList();
      
      print('📋 Found auth-related keys: $authKeys');
      
      for (final key in authKeys) {
        final value = prefs.get(key);
        print('   $key: $value');
      }
      
      final accessToken = prefs.getString('access_token');
      final tokenType = prefs.getString('token_type') ?? 'bearer';
      final authHeader = "$tokenType $accessToken";
      
      print('🔑 Authorization Header: "$authHeader"');
      print('📏 Header Length: ${authHeader.length}');
      
      if (accessToken != null) {
        final parts = accessToken.split('.');
        if (parts.length == 3) {
          print('✅ Access Token appears to be valid JWT');
        } else {
          print('⚠️ Access Token does not look like standard JWT');
        }
      }
      
      print('=== END DEEP DEBUG ===\n');
      
    } catch (e) {
      print('❌ Error in deep debug: $e');
    }
  }

  /// 🔥 NEW: Manual authentication fix for users
  Future<void> _manualAuthFix() async {
    try {
      print('🛠️ Starting manual authentication fix...');
      
      final prefs = await SharedPreferences.getInstance();
      
      final currentAccessToken = prefs.getString('access_token');
      final currentTokenType = prefs.getString('token_type');
      final currentUserId = prefs.getString('user_id');
      final userEmail = prefs.getString('email');
      
      print('📊 Current State:');
      print('   Access Token: ${currentAccessToken != null ? "EXISTS" : "NULL"}');
      print('   Token Type: ${currentTokenType ?? "NULL"}');
      print('   User ID: ${currentUserId ?? "NULL"}');
      print('   Email: ${userEmail ?? "NULL"}');
      
      bool fixedSomething = false;
      
      if (currentAccessToken != null && currentAccessToken.isNotEmpty && 
          (currentTokenType == null || currentTokenType.isEmpty)) {
        await prefs.setString('token_type', 'bearer');
        print('✅ Fixed: Set token_type to "bearer"');
        fixedSomething = true;
      }
      
      if (userEmail != null && currentAccessToken == null) {
        print('⚠️ User email found but no access token - user may be logged out');
        Get.snackbar(
          "Login Required",
          "Please log in again to use the chatbot",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
      
      if (fixedSomething) {
        _accessToken = prefs.getString('access_token');
        _tokenType = prefs.getString('token_type');
        _currentUserId = prefs.getString('user_id');
        
        Get.snackbar(
          "Authentication Fixed",
          "Try using the chatbot now",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        await _startServerSession();
      } else {
        Get.snackbar(
          "No Fix Needed",
          "Authentication data looks correct",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }
      
    } catch (e) {
      print('❌ Error in manual auth fix: $e');
      Get.snackbar(
        "Fix Failed",
        "Please try logging out and back in",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _startServerSession() async {
    try {
      print('🚀 Starting server chat session...');
      
      if (_accessToken == null || _tokenType == null) {
        print('❌ Cannot start server session: Missing auth tokens');
        return;
      }
      
      final authHeader = "$_tokenType $_accessToken";
      print('   Using Auth Header: $authHeader');
      
      final response = await http.post(
        Uri.parse("$baseUrl/chat/start"),
        headers: {
          "Content-Type": "application/json",
          "accept": "application/json",
          "Authorization": authHeader,
        },
      ).timeout(Duration(seconds: 10));
      
      print('📡 Server session response: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _sessionId = data["session_id"];
        print("✅ Server chat session started: $_sessionId");
      } else {
        print("❌ Server session failed: ${response.statusCode} - ${response.body}");
        
        if (response.statusCode == 401) {
          Get.snackbar(
            "Session Expired",
            "Please log in again",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } else if (response.statusCode == 403) {
          Get.snackbar(
            "Access Denied",
            "You don't have permission to use chatbot",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print("❌ Server session error: $e");
      Get.snackbar(
        "Connection Issue",
        "Could not start chat session. Please check your connection.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  /* ----------------- Per-Vehicle Session Logic ------------------ */

  Future<String?> _getSessionIdForVehicle(String vehicleId) async {
    if (_currentUserId == null) return null;
    
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getString(getSessionsKey(_currentUserId!));
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
    // 🔥 FIX: Always create new session when vehicle is selected
    final sessionId = await _createNewSessionForVehicle(vehicleId);
    setState(() => _activeSessionId = sessionId);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(getCurrentSessionKey(_currentUserId!), sessionId);
    
    // Show language dialog for new vehicle session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showLanguageDialog && !_isLanguageDialogOpen) {
        _showLanguageSelectionDialog();
      }
    });
  }

  // 🔥 VEHICLE CATEGORY ICON METHOD (UPDATED)
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
      case 'bus':
        return Icons.directions_bus;
      case 'electric':
        return Icons.electric_car;
      default:
        return Icons.directions_car;
    }
  }

  Future<void> _saveToChatManager(String sessionId, Map<String, dynamic> message, String chatTitle) async {
    try {
      if (!Get.isRegistered<ChatManagerProvider>()) {
        print('❌ ChatManagerProvider not registered');
        return;
      }

      final chatManager = Get.find<ChatManagerProvider>();
      
      if (!chatManager.isInitialized) {
        print('❌ ChatManagerProvider not initialized, trying to initialize...');
        
        final userId = await _prefs.getCurrentUserId();
        if (userId != null) {
          await chatManager.initializeForUser(userId);
          print('✅ ChatManagerProvider initialized in chat screen');
        } else {
          print('❌ No user ID found for ChatManagerProvider initialization');
          return;
        }
      }

      final enhancedMessage = Map<String, dynamic>.from(message);
      if (message.containsKey('text') && message['text'] is String) {
        enhancedMessage['formattedText'] = _formatMessageForDisplay(message['text']);
      }

      if (!chatManager.sessionExists(sessionId)) {
        chatManager.createSession(
          id: sessionId,
          title: chatTitle,
          firstMessage: enhancedMessage['formattedText']?.toString() ?? enhancedMessage['text']?.toString() ?? 'New chat',
        );
        print('✅ Created new session in ChatManagerProvider: $sessionId');
      } else {
        chatManager.addMessageToSession(sessionId, enhancedMessage);
        print('✅ Added message to existing session in ChatManagerProvider: $sessionId');
      }

    } catch (e) {
      print('❌ Error saving to ChatManagerProvider: $e');
    }
  }

  /* ----------------- FIXED IMAGE HANDLING LOGIC ------------------ */
  
  Future<void> sendMessage() async {
    if (_isProcessing) {
      print('⚠️ Already processing, ignoring duplicate send');
      return;
    }
    
    if (!_validateSession()) {
     _startFreshSession();
      Get.snackbar(
        "Session Issue",
        "Starting new chat session...",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }
    
    if (_isSpeaking || _isPaused) {
      _stopSpeaking();
    }
    
    if (_accessToken == null || _tokenType == null) {
      Get.snackbar(
        "Authentication Missing",
        "Please log in again to use chatbot",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      await _initAuth();
      return;
    }
    
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

    if (text.isEmpty && _selectedImage == null) {
      Get.snackbar(
        "Empty Message",
        "Please enter a message or select an image",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (_activeSessionId == null) {
      await _activateVehicleSession(vehicleId);
    }

    final userText = text;
    final userImage = _selectedImage;

    setState(() {
      _controller.clear();
      _selectedImage = null;
      _isProcessing = true;
      _isListening = false;
    });
    _speech.stop();

    final userMessage = {
      "text": userText,
      "formattedText": _formatMessageForDisplay(userText), 
      "isSent": true,
      "vehicleId": vehicleId,
      "brand": _selectedVehicle?['brand'],
      "model": _selectedVehicle?['model'],
      "category": _selectedVehicle?['category'],
      "timestamp": DateTime.now().toIso8601String(),
    };

    if (userImage != null) {
      userMessage["imagePath"] = userImage.path;
      userMessage["hasImage"] = true;
      userMessage["imageSize"] = await userImage.length();
      print('📸 Image attached: ${userImage.path}');
    }

    setState(() {
      _allSessions[_activeSessionId]!.add(userMessage);
    });
    await _saveSessions();
    await _saveToChatManager(_activeSessionId!, userMessage, 'New Chat');

    try {
      final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
      
      final authHeader = "$_tokenType $_accessToken";
      request.headers["Authorization"] = authHeader;
      request.headers["Accept"] = "application/json";

      if (_sessionId != null) {
        request.fields["session_id"] = _sessionId!;
      }
      
      if (userText.isNotEmpty) {
        request.fields["message"] = userText;
      } else if (userImage != null) {
        request.fields["message"] = "Analyze this vehicle image for any visible issues, damage, or maintenance needs";
      }
      
      request.fields["language"] = _selectedLanguage;
      request.fields["vehicle_json"] = json.encode(_selectedVehicle);

      print('📤 Sending chat message:');
      print('   Message: ${request.fields["message"]}');
      print('   Vehicle: ${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}');
      print('   Language: $_selectedLanguage');
      print('   Has Image: ${userImage != null}');

      if (userImage != null) {
        print('📸 Adding image to request: ${userImage.path}');
        
        final fileExtension = userImage.path.split('.').last.toLowerCase();
        final mimeType = _getMimeType(fileExtension);
        
        final multipartFile = await http.MultipartFile.fromPath(
          'image',
          userImage.path,
          contentType: MediaType('image', mimeType),
          filename: 'vehicle_${_selectedVehicle!['brand']}_${_selectedVehicle!['model']}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
        );
        request.files.add(multipartFile);
        
        final fileSize = await userImage.length();
        print('   Image details: ${fileSize ~/ 1024} KB, type: $mimeType, field: image');
      }

      print('🚀 Sending request to backend...');
      final streamedResponse = await request.send().timeout(Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response received:');
      print('   Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('   Error body: ${response.body}');
      }

      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          print('✅ Success response received');
          
          String reply;
          if (decoded.containsKey("response")) {
            reply = decoded["response"]; 
          } else if (decoded.containsKey("reply")) {
            reply = decoded["reply"];
          } else if (decoded.containsKey("message")) {
            reply = decoded["message"];
          } else if (decoded.containsKey("analysis")) {
            reply = decoded["analysis"];
          } else {
            reply = _extractReplyFromResponse(decoded);
          }

          final botMessage = {
            "text": reply,
            "formattedText": _formatMessageForDisplay(reply),
            "isSent": false,
            "timestamp": DateTime.now().toIso8601String(),
            "isImageAnalysis": userImage != null,
            "cvAnalysis": userImage != null,
          };

          setState(() {
            _allSessions[_activeSessionId]!.add(botMessage);
          });
          await _saveSessions();
          await _saveToChatManager(_activeSessionId!, botMessage, decoded["chat_title"] ?? 'New Chat');

          await _speak(reply);

          if (userImage != null) {
            Get.snackbar(
              "✅ Image Analysis Complete",
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
      } else if (response.statusCode == 401) {
        _handleErrorResponse("Authentication failed. Please log in again.");
        await _initAuth();
      } else if (response.statusCode == 422) {
        print('❌ FastAPI Validation Error: ${response.body}');
        _handleValidationError(response.body);
      } else if (response.statusCode == 415) {
        _handleErrorResponse("Unsupported media type. The image format may not be supported.");
      } else if (response.statusCode == 413) {
        _handleErrorResponse("Image file too large. Please select a smaller image (max 5MB).");
      } else {
        print('❌ Server error: ${response.statusCode}');
        _handleErrorResponse("Server error: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      print('❌ Network error: $e');
      _handleErrorResponse("Network error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // 🔥 FIXED: Improved image picker with better error handling
  Future<void> _pickImage() async {
    try {
      print('📸 Opening image picker...');
      
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          Get.snackbar(
            "Permission Required",
            "Storage access is needed to select images",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }
      }

      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      if (file != null) {
        final imageFile = File(file.path);
        
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
        
        if (!await imageFile.exists()) {
          Get.snackbar(
            "Error",
            "Selected image file no longer exists",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
        
        setState(() => _selectedImage = imageFile);
        
        FocusScope.of(context).unfocus();
        Future.delayed(Duration(milliseconds: 100), () {
          FocusScope.of(context).requestFocus(FocusNode());
        });
        
        print('✅ Image selected: ${file.path} (${fileSize ~/ 1024} KB)');
        
        Get.snackbar(
          "Image Selected",
          "Tap send to analyze the image",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      } else {
        print('🔄 Image selection cancelled');
      }
    } catch (e) {
      print('❌ Image picker error: $e');
      Get.snackbar(
        "Error Selecting Image",
        "Please try again or select a different image",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }

  String _formatMessageForDisplay(String text) {
    if (text.isEmpty) return '';
    
    String formattedText = text;
    formattedText = formattedText.replaceAll('**', '');
    
    if (formattedText.contains('###')) {
      formattedText = formattedText.replaceAll('###', '• ');
    }
    
    return formattedText;
  }

  String _extractReplyFromResponse(Map<String, dynamic> response) {
    try {
      for (var value in response.values) {
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
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
        "formattedText": _formatMessageForDisplay("⚠️ FixiBot Error\n\nI encountered an issue while processing your request.\n\nError Details: $error\n\nPlease try again or contact support if the problem persists."),
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

  // 🔥 FIXED: Message Bubble with simple audio controls
  Widget _buildMessageBubble(Map<String, dynamic> m) {
    final isUser = m["isSent"] == true;
    final hasImage = m["hasImage"] == true;
    final isError = m["isError"] == true;
    final isCVAnalysis = m["cvAnalysis"] == true;
    final messageText = m["formattedText"]?.toString() ?? m["text"]?.toString() ?? '';
    final cleanMessageText = messageText.replaceAll('*', '').replaceAll('#', '');
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
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
            if (hasImage && m.containsKey("imagePath"))
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FutureBuilder<bool>(
                        future: File(m["imagePath"]).exists(),
                        builder: (context, snapshot) {
                          if (snapshot.data == true) {
                            return Image.file(
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
                            );
                          } else {
                            return Container(
                              width: 200,
                              height: 150,
                              color: Colors.grey.shade200,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                                  SizedBox(height: 8),
                                  Text("Image file not found", style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            
            if (messageText.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: hasImage ? 4 : 0),
                child: _buildRichTextMessage(
                  messageText,
                  isUser: isUser,
                  isError: isError,
                  isCVAnalysis: isCVAnalysis,
                ),
              ),
            
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

            if (!isUser && !isError && messageText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isSpeaking || _lastSpokenText != cleanMessageText)
                      GestureDetector(
                        onTap: () => _speak(messageText),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    
                    if (_isSpeaking && _lastSpokenText == cleanMessageText)
                      GestureDetector(
                        onTap: _pauseSpeaking,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.pause_rounded,
                            size: 16,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    
                    if (_isPaused && _lastSpokenText == cleanMessageText)
                      GestureDetector(
                        onTap: _resumeSpeaking,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    
                    if ((_isSpeaking || _isPaused) && _lastSpokenText == cleanMessageText)
                      GestureDetector(
                        onTap: _stopSpeaking,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.stop_rounded,
                            size: 16,
                            color: Colors.red.shade800,
                          ),
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

  Widget _buildRichTextMessage(String text, {bool isUser = false, bool isError = false, bool isCVAnalysis = false}) {
    final textColor = isError 
      ? Colors.orange.shade900
      : isCVAnalysis
        ? Colors.blue.shade900
        : isUser 
          ? Colors.white 
          : Colors.black87;

    final baseStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      fontWeight: isError || isCVAnalysis ? FontWeight.w600 : FontWeight.normal,
      height: 1.4,
    );

    final boldStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      height: 1.4,
    );

    if (text.contains('•')) {
      return _buildBulletPoints(text, textColor: textColor, baseStyle: baseStyle, boldStyle: boldStyle);
    }

    return Text(text, style: baseStyle);
  }

  Widget _buildBulletPoints(String text, {required Color textColor, required TextStyle baseStyle, required TextStyle boldStyle}) {
    final lines = text.split('\n');
    final List<Widget> bulletWidgets = [];

    for (final line in lines) {
      if (line.trim().startsWith('•')) {
        final bulletText = line.replaceFirst('•', '').trim();

        bulletWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, right: 8.0),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: textColor,
                  ),
                ),
                Expanded(
                  child: Text(bulletText, style: baseStyle),
                ),
              ],
            ),
          ),
        );
      } else if (line.trim().isNotEmpty) {
        bulletWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(line, style: baseStyle),
          ),
        );
      } else {
        bulletWidgets.add(const SizedBox(height: 4.0));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bulletWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 ALWAYS START FRESH WHEN CHAT IS OPENED
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showLanguageDialog && !_isLanguageDialogOpen && _activeSessionId != null) {
        _showLanguageSelectionDialog();
      }
    });
    
    final messages = _allSessions[_activeSessionId] ?? [];

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: CustomAppBar(
        title: "FixiBot",
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.secondaryColor),
            tooltip: "Reset Chat Session",
            onPressed: () {
              _cleanupTTS();
              _startFreshSession();
              Get.snackbar(
                "Session Reset",
                "Chat session has been reset",
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
          ),
          _buildLanguageChangeButton(),
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.secondaryColor),
            onPressed: () {
              Get.to(ChatHistoryParentWidget());
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_comment, color: AppColors.secondaryColor),
            tooltip: "New Chat",
            onPressed: _startNewChat,
          ),
          IconButton(
            icon: const Icon(Icons.build, color: AppColors.secondaryColor),
            tooltip: "Fix Authentication",
            onPressed: _manualAuthFix,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              "Select the vehicle to resolve an issue:",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.mainColor,
              ),
            ),
          ),

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

          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.mainColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate, size: 14, color: AppColors.mainColor),
                SizedBox(width: 6),
                Text(
                  "Chatting in $_selectedLanguage",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mainColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isSpeaking) ...[
                  SizedBox(width: 8),
                  Icon(Icons.volume_up, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    "Speaking...",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                    ),
                  ),
                ] else if (_isPaused) ...[
                  SizedBox(width: 8),
                  Icon(Icons.pause, size: 12, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    "Paused",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                    ),
                  ),
                ]
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
                  ),
                ),
                
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
                          _selectedImage != null ? 
                            "Analyzing image with FixiBot..." : 
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
                        color: _isListening ? Colors.red : 
                              _selectedImage != null ? Colors.green : 
                              AppColors.mainColor.withOpacity(0.4),
                        width: _isListening || _selectedImage != null ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.green),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.file(
                                            _selectedImage!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => _selectedImage = null);
                                        },
                                        child: const CircleAvatar(
                                          radius: 8,
                                          backgroundColor: Colors.red,
                                          child: Icon(Icons.close,
                                              size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            IconButton(
                              icon: Stack(
                                children: [
                                  Icon(Icons.camera_alt_rounded,
                                      color: AppColors.mainColor),
                                  if (_selectedImage != null)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.check, size: 10, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                              onPressed: _pickImage,
                              tooltip: "Add Image",
                            ),
                            Flexible(
                              flex: 2,
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: _isListening ? "Listening..." : 
                                          _selectedImage != null ? "Describe image or tap send..." : 
                                          "Type or speak...",
                                  hintStyle: TextStyle(
                                    color: _isListening ? Colors.red : 
                                          _selectedImage != null ? Colors.green : 
                                          Colors.grey
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 8),
                                ),
                                minLines: 1,
                                maxLines: 4,
                              ),
                            ),
                            GestureDetector(
                              onTap: _listen,
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                                  color: _isListening ? Colors.red : AppColors.mainColor,
                                ),
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
                                  : Icon(Icons.send_rounded,
                                      color: _selectedImage != null ? Colors.green : AppColors.mainColor),
                              onPressed: _isProcessing ? null : sendMessage,
                              tooltip: _selectedImage != null ? "Send Image for Analysis" : "Send Message",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


















// /////PREVVVV-dialog+play pause
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
// import 'package:fixibot_app/constants/appConfig.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:fixibot_app/screens/chatbot/chatHistoryParent.dart';
// import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// // 🔥 Voice & Permission Imports
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:permission_handler/permission_handler.dart';

// /// Keys to store/retrieve persistent data - NOW USER-SPECIFIC
// String getSessionsKey(String userId) => "all_chat_sessions_$userId";
// String getCurrentSessionKey(String userId) => "current_session_id_$userId";
// String getSessionLanguageKey(String sessionId) => "session_language_$sessionId";

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
  
//   // 🔥 Voice & Language State
//   late stt.SpeechToText _speech;
//   late FlutterTts _flutterTts;
//   bool _isListening = false;
//   bool _isSpeaking = false;
//   bool _isPaused = false; // 🔥 NEW: Track pause state
//   String? _lastSpokenText; // 🔥 NEW: Track last spoken text
  
//   // Language Mapping (Display Name -> Locale ID)
//   final Map<String, String> _languages = {
//     'English': 'en-US',
//     'Urdu': 'ur-PK',
//     'Hindi': 'hi-IN',
//     'Punjabi': 'pa-PK',
//     'Sindhi': 'sd-PK',  // Sindhi (Pakistan)
//   };
//   String _selectedLanguage = 'English'; // Default

//   final baseUrl = AppConfig.baseUrl;

//   // Auth & session
//   String? _accessToken;
//   String? _tokenType;
//   String? _sessionId;
//   String? _currentUserId;

//   // UI / chat state
//   File? _selectedImage;
//   Map<String, dynamic>? _selectedVehicle;
//   bool _isProcessing = false;
//   bool _showLanguageDialog = true; // 🔥 NEW: Control dialog visibility

//   /// All sessions are stored here
//   Map<String, List<Map<String, dynamic>>> _allSessions = {};
//   String? _activeSessionId;
  
//   void _checkAvailableLocales() async {
//     bool available = await _speech.initialize();
//     if (available) {
//       var locales = await _speech.locales();
//       print("\n=== AVAILABLE SPEECH LOCALES ===");
//       for (var locale in locales) {
//         print("Name: ${locale.name}, ID: ${locale.localeId}");
//       }
//       print("================================\n");
//     } else {
//       print("Speech recognition not available");
//     }
//   }
  
//   @override
//   void initState() {
//     super.initState();
//     _initializeChatScreen();
//     _initVoiceFeatures(); // 🔥 Initialize Voice
//     _checkAvailableLocales();
//   }

//   @override
//   void dispose() {
//     _flutterTts.stop();
//     _speech.cancel();
//     super.dispose();
//   }

//   // 🔥 Initialize STT and TTS
//   void _initVoiceFeatures() async {
//     _speech = stt.SpeechToText();
//     _flutterTts = FlutterTts();

//     // Default setup
//     await _flutterTts.setLanguage("en-US");
//     await _flutterTts.setPitch(1.0);
//     await _flutterTts.setSpeechRate(0.5);


//    // In _initVoiceFeatures() method:
// _flutterTts.setCompletionHandler(() {
//   print('✅ TTS Completed');
//   setState(() {
//     _isSpeaking = false;
//     _isPaused = false;
//     _lastSpokenText = null;
//   });
// });

// _flutterTts.setCancelHandler(() {
//   print('⏹️ TTS Cancelled');
//   setState(() {
//     _isSpeaking = false;
//     _isPaused = false;
//   });
// });

//     // 🔥 FIXED: Proper TTS handlers
//     _flutterTts.setStartHandler(() {
//       print('▶️ TTS Started');
//       setState(() {
//         _isSpeaking = true;
//         _isPaused = false;
//       });
//     });

//     _flutterTts.setErrorHandler((msg) {
//       print('❌ TTS Error: $msg');
//       setState(() {
//         _isSpeaking = false;
//         _isPaused = false;
//       });
//     });

//     _flutterTts.setPauseHandler(() {
//       print('⏸️ TTS Paused');
//       setState(() {
//         _isSpeaking = false;
//         _isPaused = true;
//       });
//     });

//     _flutterTts.setContinueHandler(() {
//       print('▶️ TTS Continued');
//       setState(() {
//         _isSpeaking = true;
//         _isPaused = false;
//       });
//     });

//   }

//   // 🔥 NEW: Save language preference for session
//   Future<void> _saveSessionLanguage(String sessionId, String language) async {
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(getSessionLanguageKey(sessionId), language);
//     print('💾 Saved language "$language" for session: $sessionId');
//   }

//   // 🔥 NEW: Load language preference for session
//   Future<String?> _loadSessionLanguage(String sessionId) async {
//     final sp = await SharedPreferences.getInstance();
//     final language = sp.getString(getSessionLanguageKey(sessionId));
//     if (language != null) {
//       print('📥 Loaded language "$language" for session: $sessionId');
//     }
//     return language;
//   }

//   // 🔥 Handle Language Change (Update TTS Accent)
//   void _onLanguageChanged(String lang) async {
//     setState(() {
//       _selectedLanguage = lang;
//     });
    
//     // Save language preference for current session
//     if (_activeSessionId != null) {
//       await _saveSessionLanguage(_activeSessionId!, lang);
//     }
    
//     String localeId = _languages[lang] ?? 'en-US';
    
//     // Check if the language is actually available on the device
//     bool isAvailable = await _flutterTts.isLanguageAvailable(localeId);
    
//     if (isAvailable) {
//       await _flutterTts.setLanguage(localeId);
//       print("🗣️ Language switched to: $lang ($localeId)");
//     } else {
//       Get.snackbar(
//         "Voice Not Supported", 
//         "Your device does not have a text-to-speech voice for $lang.",
//         backgroundColor: Colors.orange,
//         colorText: Colors.white
//       );
//       // Fallback to English or keep previous
//       await _flutterTts.setLanguage("en-US");
//     }
//   }

//   // 🔥 Start Listening (Mic Button)
//   void _listen() async {
//     if (!_isListening) {
//       // Request microphone permission
//       var status = await Permission.microphone.request();
//       if (status != PermissionStatus.granted) {
//         Get.snackbar("Permission Denied", "Microphone access is required.");
//         return;
//       }

//       bool available = await _speech.initialize(
//         onStatus: (status) => print('STT Status: $status'),
//         onError: (val) => print('STT Error: $val'),
//       );

//       if (available) {
//         setState(() => _isListening = true);
//         String localeId = _languages[_selectedLanguage] ?? 'en-US';
        
//         _speech.listen(
//           onResult: (val) {
//             setState(() {
//               _controller.text = val.recognizedWords;
//             });
//           },
//           localeId: localeId, // 🔥 Critical: Listen in selected language
//         );
//       }
//     } else {
//       setState(() => _isListening = false);
//       _speech.stop();
//     }
//   }


// // 🔥 Simplified Text-to-Speech Logic
// Future<void> _speak(String text) async {
//   if (text.isNotEmpty) {
//     // Clean text before speaking
//     String cleanText = text.replaceAll('*', '').replaceAll('#', '');
//     _lastSpokenText = cleanText;
    
//     // Stop any ongoing speech
//     await _flutterTts.stop();
    
//     // Start speaking
//     await _flutterTts.speak(cleanText);
    
//     // Update state
//     setState(() {
//       _isSpeaking = true;
//       _isPaused = false;
//     });
    
//     print('🔊 Speaking: ${cleanText.substring(0, min(50, cleanText.length))}...');
//   }
// }



//   Future<void> _initializeChatScreen() async {
//     await vehicleController.fetchUserVehicles();
//     await _initAuth();
//     _startFreshSession();
//   }

//   // 🔥 Pause speaking
//  // 🔥 SIMPLIFIED: Pause speaking
// void _pauseSpeaking() async {
//   if (_isSpeaking) {
//     await _flutterTts.stop(); // Just stop instead of pause
//     setState(() {
//       _isSpeaking = false;
//       _isPaused = true;
//     });
//   }
// }

// // 🔥 SIMPLIFIED: Resume speaking 
// void _resumeSpeaking() async {
//   if (_isPaused && _lastSpokenText != null) {
//     await _speak(_lastSpokenText!); // Use existing _speak method
//   }
// }

  
//   // 🔥 Stop speaking (completely)
//   void _stopSpeaking() async {
//     await _flutterTts.stop();
//     // State will be updated by the cancel handler
//   }

//   /* ----------------- User-Specific Session Management ------------------ */

//   Future<void> _loadSessions() async {
//     if (_currentUserId == null) return;
    
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(getSessionsKey(_currentUserId!));

//     if (stored != null) {
//       try {
//         final Map<String, dynamic> decoded = jsonDecode(stored);
//         _allSessions = decoded.map(
//             (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
//         print('📥 Loaded ${_allSessions.length} sessions for user: $_currentUserId');
//       } catch (e) {
//         print('❌ Error loading sessions: $e');
//         _allSessions = {};
//       }
//     } else {
//       _allSessions = {};
//     }

//     _startFreshSession();
//   }

//   Future<void> _saveSessions() async {
//     if (_currentUserId == null) return;
    
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(getSessionsKey(_currentUserId!), jsonEncode(_allSessions));
//     if (_activeSessionId != null) {
//       await sp.setString(getCurrentSessionKey(_currentUserId!), _activeSessionId!);
//     }
//     print('💾 Saved ${_allSessions.length} sessions for user: $_currentUserId');
//   }

//   void _startFreshSession() {
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     setState(() {
//       _allSessions[newId] = [];
//       _activeSessionId = newId;
//       _selectedVehicle = null; 
//       _selectedImage = null; 
//       _showLanguageDialog = true; // 🔥 Show dialog for new session
//     });
//     print('🆕 Started fresh session: $newId for user: $_currentUserId');
    
//     // 🔥 NEW: Load language preference for this session
//     _loadSessionLanguage(newId).then((language) {
//       if (language != null) {
//         setState(() {
//           _selectedLanguage = language;
//           _showLanguageDialog = false; // Don't show dialog if language already set
//         });
//         _onLanguageChanged(language);
//       } else {
//         // Show language dialog after a brief delay
//         Future.delayed(Duration(milliseconds: 500), () {
//           if (mounted) {
//             _showLanguageSelectionDialog();
//           }
//         });
//       }
//     });
//   }

//   // 🔥 NEW: Show language selection dialog
//   void _showLanguageSelectionDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false, // User must select a language
//       builder: (context) {
//         return AlertDialog(
//           title: Row(
//             children: [
//               Icon(Icons.language, color: AppColors.mainColor),
//               SizedBox(width: 10),
//               Text(
//                 "Select Language",
//                 style: TextStyle(
//                   color: AppColors.mainColor,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           content: Text(
//             "Choose your preferred language for this chat session. "
//             "This will be used for both voice input and chatbot responses.",
//             style: TextStyle(fontSize: 14),
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           backgroundColor: Colors.white,
//           actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           actions: [
//             Column(
//               children: [
//                 // Language options as buttons
//                 ..._languages.keys.map((language) {
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 4.0),
//                     child: SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           _onLanguageChanged(language);
//                           Navigator.of(context).pop();
//                           setState(() {
//                             _showLanguageDialog = false;
//                           });
//                           Get.snackbar(
//                             "Language Set",
//                             "Chatbot will respond in $language",
//                             backgroundColor: Colors.green,
//                             colorText: Colors.white,
//                             duration: Duration(seconds: 2),
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _selectedLanguage == language 
//                               ? AppColors.mainColor 
//                               : AppColors.secondaryColor,
//                           foregroundColor: _selectedLanguage == language 
//                               ? Colors.white 
//                               : AppColors.mainColor,
//                           padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           elevation: 2,
//                         ),
//                         child: Text(
//                           language,
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 }).toList(),
                
//                 SizedBox(height: 10),
                
//                 // Language indicator chip
//                 Container(
//                   padding: EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade100,
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: Colors.grey.shade300),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.info_outline, size: 16, color: Colors.grey),
//                       SizedBox(width: 8),
//                       Flexible(
//                         child: Text(
//                           "You can change language anytime from settings",
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey.shade700,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // 🔥 NEW: Change language button in app bar
//   Widget _buildLanguageChangeButton() {
//     return IconButton(
//       icon: Stack(
//         children: [
//           Icon(Icons.language, color: AppColors.secondaryColor),
//           Positioned(
//             right: 0,
//             top: 0,
//             child: Container(
//               padding: EdgeInsets.all(2),
//               decoration: BoxDecoration(
//                 color: Colors.green,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               constraints: BoxConstraints(
//                 minWidth: 12,
//                 minHeight: 12,
//               ),
//               child: Text(
//                 _selectedLanguage.substring(0, 1),
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 8,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ),
//         ],
//       ),
//       tooltip: "Change Language ($_selectedLanguage)",
//       onPressed: () {
//         _showLanguageSelectionDialog();
//       },
//     );
//   }

//   void _startNewLocalSession() {
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//   }

//   Future<void> _startNewChat() async {
//     setState(() {
//       _startNewLocalSession();
//       _selectedVehicle = null; 
//       _selectedImage = null; // 🔥 Reset image when starting new chat
//     });
//     await _saveSessions();
//     // 🔥 Show language dialog for new chat
//     _showLanguageSelectionDialog();
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
    
//     // Also delete from ChatManagerProvider
//     try {
//       if (Get.isRegistered<ChatManagerProvider>()) {
//         final chatManager = Get.find<ChatManagerProvider>();
//         if (chatManager.sessionExists(sessionId)) {
//           chatManager.deleteSession(sessionId);
//           print('✅ Session deleted from ChatManagerProvider: $sessionId');
//         }
//       }
//     } catch (e) {
//       print('❌ Error deleting from ChatManagerProvider: $e');
//     }
//   }

//   /* ----------------- Backend Auth/Session ------------------ */

//   Future<void> _initAuth() async {
//     try {
//       print('🔄 Starting authentication initialization...');
      
//       final prefs = await SharedPreferences.getInstance();
//       _accessToken = prefs.getString('access_token');
//       _tokenType = prefs.getString('token_type');
//       _currentUserId = prefs.getString('user_id');
      
//       print('🔐 Chatbot Auth Check:');
//       print('   User ID: ${_currentUserId ?? "❌ NULL"}');
//       print('   Access Token: ${_accessToken != null ? "✅ EXISTS" : "❌ MISSING"}');
//       print('   Token Type: ${_tokenType ?? "❌ NULL"}');
      
//       // 🔥 AUTO-FIX: Check for common authentication issues
//       bool needsFix = false;
      
//       // Fix 1: Missing token_type but has access_token (Google user issue)
//       if (_accessToken != null && _accessToken!.isNotEmpty && (_tokenType == null || _tokenType!.isEmpty)) {
//         print('🛠️ Auto-fixing missing token_type for Google user...');
//         await prefs.setString('token_type', 'bearer');
//         _tokenType = 'bearer';
//         needsFix = true;
//         print('✅ Fixed: token_type set to "bearer"');
//       }
      
//       // Fix 2: Check if access_token is valid (not empty string)
//       if (_accessToken != null && _accessToken!.isEmpty) {
//         print('🛠️ Auto-fixing empty access_token...');
//         _accessToken = null;
//         needsFix = true;
//         print('✅ Fixed: cleared empty access_token');
//       }
      
//       // Fix 3: Check if user_id exists but auth tokens are missing
//       if (_currentUserId != null && (_accessToken == null || _tokenType == null)) {
//         print('🛠️ User ID exists but auth tokens missing - checking for stored data...');
//         final userEmail = prefs.getString('email');
//         if (userEmail != null) {
//           print('   Found user email: $userEmail - but tokens are missing');
//           needsFix = true;
//         }
//       }
      
//       if (needsFix) {
//         Get.snackbar(
//           "Authentication Updated", 
//           "Chatbot is now ready to use!",
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           duration: Duration(seconds: 3),
//         );
//       }
      
//       // 🔥 ENHANCED VALIDATION: Check if we have everything needed
//       final hasValidAuth = _accessToken != null && 
//                           _accessToken!.isNotEmpty && 
//                           _tokenType != null && 
//                           _tokenType!.isNotEmpty &&
//                           _currentUserId != null;
      
//       if (!hasValidAuth) {
//         print('❌ INCOMPLETE AUTHENTICATION DATA:');
//         print('   Access Token: ${_accessToken ?? "NULL"}');
//         print('   Token Type: ${_tokenType ?? "NULL"}');
//         print('   User ID: ${_currentUserId ?? "NULL"}');
        
//         String errorMessage = "Missing authentication data:\n";
//         if (_accessToken == null) errorMessage += "• Access Token\n";
//         if (_tokenType == null) errorMessage += "• Token Type\n";
//         if (_currentUserId == null) errorMessage += "• User ID\n";
        
//         Get.snackbar(
//           "Authentication Required", 
//           errorMessage,
//           backgroundColor: Colors.redAccent, 
//           colorText: Colors.white,
//           duration: Duration(seconds: 8),
//           isDismissible: true,
//         );
        
//         await _deepDebugAuth();
//         return;
//       }
      
//       print('✅ Authentication validated successfully');
//       print('   Final Auth Header: "$_tokenType $_accessToken"');
      
//       await _startServerSession();
      
//     } catch (e) {
//       print('❌ CRITICAL ERROR in _initAuth: $e');
//       Get.snackbar(
//         "Authentication Error", 
//         "Failed to initialize authentication: $e",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         duration: Duration(seconds: 5),
//       );
//     }
//   }

//   /// 🔥 NEW: Deep authentication debugging
//   Future<void> _deepDebugAuth() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
      
//       print('\n=== 🔍 DEEP AUTH DEBUG ===');
      
//       final allKeys = prefs.getKeys();
//       final authKeys = allKeys.where((key) => 
//         key.contains('token') || 
//         key.contains('user') || 
//         key.contains('auth') || 
//         key.contains('email') ||
//         key.contains('login')
//       ).toList();
      
//       print('📋 Found auth-related keys: $authKeys');
      
//       for (final key in authKeys) {
//         final value = prefs.get(key);
//         print('   $key: $value');
//       }
      
//       final accessToken = prefs.getString('access_token');
//       final tokenType = prefs.getString('token_type') ?? 'bearer';
//       final authHeader = "$tokenType $accessToken";
      
//       print('🔑 Authorization Header: "$authHeader"');
//       print('📏 Header Length: ${authHeader.length}');
      
//       if (accessToken != null) {
//         final parts = accessToken.split('.');
//         if (parts.length == 3) {
//           print('✅ Access Token appears to be valid JWT');
//         } else {
//           print('⚠️ Access Token does not look like standard JWT');
//         }
//       }
      
//       print('=== END DEEP DEBUG ===\n');
      
//     } catch (e) {
//       print('❌ Error in deep debug: $e');
//     }
//   }

//   /// 🔥 NEW: Manual authentication fix for users
//   Future<void> _manualAuthFix() async {
//     try {
//       print('🛠️ Starting manual authentication fix...');
      
//       final prefs = await SharedPreferences.getInstance();
      
//       final currentAccessToken = prefs.getString('access_token');
//       final currentTokenType = prefs.getString('token_type');
//       final currentUserId = prefs.getString('user_id');
//       final userEmail = prefs.getString('email');
      
//       print('📊 Current State:');
//       print('   Access Token: ${currentAccessToken != null ? "EXISTS" : "NULL"}');
//       print('   Token Type: ${currentTokenType ?? "NULL"}');
//       print('   User ID: ${currentUserId ?? "NULL"}');
//       print('   Email: ${userEmail ?? "NULL"}');
      
//       bool fixedSomething = false;
      
//       if (currentAccessToken != null && currentAccessToken.isNotEmpty && 
//           (currentTokenType == null || currentTokenType.isEmpty)) {
//         await prefs.setString('token_type', 'bearer');
//         print('✅ Fixed: Set token_type to "bearer"');
//         fixedSomething = true;
//       }
      
//       if (userEmail != null && currentAccessToken == null) {
//         print('⚠️ User email found but no access token - user may be logged out');
//         Get.snackbar(
//           "Login Required",
//           "Please log in again to use the chatbot",
//           backgroundColor: Colors.orange,
//           colorText: Colors.white,
//         );
//       }
      
//       if (fixedSomething) {
//         _accessToken = prefs.getString('access_token');
//         _tokenType = prefs.getString('token_type');
//         _currentUserId = prefs.getString('user_id');
        
//         Get.snackbar(
//           "Authentication Fixed",
//           "Try using the chatbot now",
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//         );
        
//         await _startServerSession();
//       } else {
//         Get.snackbar(
//           "No Fix Needed",
//           "Authentication data looks correct",
//           backgroundColor: Colors.blue,
//           colorText: Colors.white,
//         );
//       }
      
//     } catch (e) {
//       print('❌ Error in manual auth fix: $e');
//       Get.snackbar(
//         "Fix Failed",
//         "Please try logging out and back in",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   Future<void> _startServerSession() async {
//     try {
//       print('🚀 Starting server chat session...');
      
//       if (_accessToken == null || _tokenType == null) {
//         print('❌ Cannot start server session: Missing auth tokens');
//         return;
//       }
      
//       final authHeader = "$_tokenType $_accessToken";
//       print('   Using Auth Header: $authHeader');
      
//       final response = await http.post(
//         Uri.parse("$baseUrl/chat/start"),
//         headers: {
//           "Content-Type": "application/json",
//           "accept": "application/json",
//           "Authorization": authHeader,
//         },
//       ).timeout(Duration(seconds: 10));
      
//       print('📡 Server session response: ${response.statusCode}');
      
//       if (response.statusCode == 201) {
//         final data = json.decode(response.body);
//         _sessionId = data["session_id"];
//         print("✅ Server chat session started: $_sessionId");
//       } else {
//         print("❌ Server session failed: ${response.statusCode} - ${response.body}");
        
//         if (response.statusCode == 401) {
//           Get.snackbar(
//             "Session Expired",
//             "Please log in again",
//             backgroundColor: Colors.red,
//             colorText: Colors.white,
//           );
//         } else if (response.statusCode == 403) {
//           Get.snackbar(
//             "Access Denied",
//             "You don't have permission to use chatbot",
//             backgroundColor: Colors.red,
//             colorText: Colors.white,
//           );
//         }
//       }
//     } catch (e) {
//       print("❌ Server session error: $e");
//       Get.snackbar(
//         "Connection Issue",
//         "Could not start chat session. Please check your connection.",
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//     }
//   }

//   /* ----------------- Per-Vehicle Session Logic ------------------ */

//   Future<String?> _getSessionIdForVehicle(String vehicleId) async {
//     if (_currentUserId == null) return null;
    
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(getSessionsKey(_currentUserId!));
//     if (stored == null) return null;

//     final Map<String, dynamic> decoded = jsonDecode(stored);
//     for (var entry in decoded.entries) {
//       final sessionMessages = List<Map<String, dynamic>>.from(entry.value as List);
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
//     await sp.setString(getCurrentSessionKey(_currentUserId!), sessionId!);
    
//     // 🔥 Load language preference for this session
//     final language = await _loadSessionLanguage(sessionId!);
//     if (language != null) {
//       setState(() {
//         _selectedLanguage = language;
//       });
//       _onLanguageChanged(language);
//     }
//   }

//   // 🔥 VEHICLE CATEGORY ICON METHOD (UPDATED)
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
//       case 'bus':
//         return Icons.directions_bus;
//       case 'electric':
//         return Icons.electric_car;
//       default:
//         return Icons.directions_car;
//     }
//   }

//   Future<void> _saveToChatManager(String sessionId, Map<String, dynamic> message, String chatTitle) async {
//     try {
//       if (!Get.isRegistered<ChatManagerProvider>()) {
//         print('❌ ChatManagerProvider not registered');
//         return;
//       }

//       final chatManager = Get.find<ChatManagerProvider>();
      
//       if (!chatManager.isInitialized) {
//         print('❌ ChatManagerProvider not initialized, trying to initialize...');
        
//         final userId = await _prefs.getCurrentUserId();
//         if (userId != null) {
//           await chatManager.initializeForUser(userId);
//           print('✅ ChatManagerProvider initialized in chat screen');
//         } else {
//           print('❌ No user ID found for ChatManagerProvider initialization');
//           return;
//         }
//       }

//       // ENHANCED: Add formatted text to the message
//       final enhancedMessage = Map<String, dynamic>.from(message);
//       if (message.containsKey('text') && message['text'] is String) {
//         enhancedMessage['formattedText'] = _formatMessageForDisplay(message['text']);
//       }

//       if (!chatManager.sessionExists(sessionId)) {
//         chatManager.createSession(
//           id: sessionId,
//           title: chatTitle,
//           firstMessage: enhancedMessage['formattedText']?.toString() ?? enhancedMessage['text']?.toString() ?? 'New chat',
//         );
//         print('✅ Created new session in ChatManagerProvider: $sessionId');
//       } else {
//         chatManager.addMessageToSession(sessionId, enhancedMessage);
//         print('✅ Added message to existing session in ChatManagerProvider: $sessionId');
//       }

//     } catch (e) {
//       print('❌ Error saving to ChatManagerProvider: $e');
//     }
//   }

//   /* ----------------- FIXED IMAGE HANDLING LOGIC ------------------ */
  
//   Future<void> sendMessage() async {
//     // 🔥 Stop any ongoing speech when sending new message
//     if (_isSpeaking || _isPaused) {
//       _stopSpeaking();
//     }
    
//     // 🔥 ENHANCED: Check authentication before sending message
//     if (_accessToken == null || _tokenType == null) {
//       Get.snackbar(
//         "Authentication Missing",
//         "Please log in again to use chatbot",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       await _initAuth();
//       return;
//     }
    
//     if (_selectedVehicle == null) {
//       Get.snackbar(
//         "Select Vehicle",
//         "Please choose a vehicle",
//         backgroundColor: Colors.redAccent,
//         colorText: Colors.white,
//       );
//       return;
//     }
    
//     final text = _controller.text.trim();
//     final vehicleId = _selectedVehicle!["_id"];

//     // 🔥 FIXED: Validate input with image
//     if (text.isEmpty && _selectedImage == null) {
//       Get.snackbar(
//         "Empty Message",
//         "Please enter a message or select an image",
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     // Ensure session exists
//     if (_activeSessionId == null) {
//       await _activateVehicleSession(vehicleId);
//     }

//     // Store user input temporarily
//     final userText = text;
//     final userImage = _selectedImage;

//     // Clear input immediately and show loader
//     setState(() {
//       _controller.clear();
//       _selectedImage = null;
//       _isProcessing = true;
//       _isListening = false;
//     });
//     _speech.stop();

//     // Create user message with image data
//     final userMessage = {
//       "text": userText,
//       "formattedText": _formatMessageForDisplay(userText), 
//       "isSent": true,
//       "vehicleId": vehicleId,
//       "brand": _selectedVehicle?['brand'],
//       "model": _selectedVehicle?['model'],
//       "category": _selectedVehicle?['category'],
//       "timestamp": DateTime.now().toIso8601String(),
//     };

//     // 🔥 FIXED: Add image data to message
//     if (userImage != null) {
//       userMessage["imagePath"] = userImage.path;
//       userMessage["hasImage"] = true;
//       userMessage["imageSize"] = await userImage.length();
//       print('📸 Image attached: ${userImage.path}');
//     }

//     // 🔥 Save to local session
//     setState(() {
//       _allSessions[_activeSessionId]!.add(userMessage);
//     });
//     await _saveSessions();
//     await _saveToChatManager(_activeSessionId!, userMessage, 'New Chat');

//     // 🔥 Send to backend with enhanced image handling
//     try {
//       final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
      
//       // Add headers
//       final authHeader = "$_tokenType $_accessToken";
//       request.headers["Authorization"] = authHeader;
//       request.headers["Accept"] = "application/json";

//       // Add session data
//       if (_sessionId != null) {
//         request.fields["session_id"] = _sessionId!;
//       }
      
//       // 🔥 FIXED: Always send message field - handle image-only queries
//       if (userText.isNotEmpty) {
//         request.fields["message"] = userText;
//       } else if (userImage != null) {
//         // Provide context for CV model when only image is sent
//         request.fields["message"] = "Analyze this vehicle image for any visible issues, damage, or maintenance needs";
//       }
      
//       // 🔥 Send language parameter
//       request.fields["language"] = _selectedLanguage;
      
//       // Send vehicle data as JSON
//       request.fields["vehicle_json"] = json.encode(_selectedVehicle);

//       print('📤 Sending chat message:');
//       print('   Message: ${request.fields["message"]}');
//       print('   Vehicle: ${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}');
//       print('   Language: $_selectedLanguage');
//       print('   Has Image: ${userImage != null}');

//       // 🔥 FIXED: Handle image upload with proper multipart formatting
//       if (userImage != null) {
//         print('📸 Adding image to request: ${userImage.path}');
        
//         // Get file extension and mime type
//         final fileExtension = userImage.path.split('.').last.toLowerCase();
//         final mimeType = _getMimeType(fileExtension);
        
//         // 🔥 CRITICAL: Use exact field name expected by FastAPI
//         final multipartFile = await http.MultipartFile.fromPath(
//           'image', // This MUST be 'image' to match FastAPI parameter
//           userImage.path,
//           contentType: MediaType('image', mimeType),
//           filename: 'vehicle_${_selectedVehicle!['brand']}_${_selectedVehicle!['model']}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
//         );
//         request.files.add(multipartFile);
        
//         final fileSize = await userImage.length();
//         print('   Image details: ${fileSize ~/ 1024} KB, type: $mimeType, field: image');
//       }

//       // Send request with timeout
//       print('🚀 Sending request to backend...');
//       final streamedResponse = await request.send().timeout(Duration(seconds: 30));
//       final response = await http.Response.fromStream(streamedResponse);

//       print('📥 Response received:');
//       print('   Status: ${response.statusCode}');
//       if (response.statusCode != 200) {
//         print('   Error body: ${response.body}');
//       }

//       if (response.statusCode == 200) {
//         try {
//           final decoded = json.decode(response.body);
//           print('✅ Success response received');
          
//           // Handle response format
//           String reply;
//           if (decoded.containsKey("response")) {
//             reply = decoded["response"]; 
//           } else if (decoded.containsKey("reply")) {
//             reply = decoded["reply"];
//           } else if (decoded.containsKey("message")) {
//             reply = decoded["message"];
//           } else if (decoded.containsKey("analysis")) {
//             reply = decoded["analysis"];
//           } else {
//             reply = _extractReplyFromResponse(decoded);
//           }

//           // Create bot message with CV analysis flag
//           final botMessage = {
//             "text": reply,
//             "formattedText": _formatMessageForDisplay(reply),
//             "isSent": false,
//             "timestamp": DateTime.now().toIso8601String(),
//             "isImageAnalysis": userImage != null,
//             "cvAnalysis": userImage != null,
//           };

//           // Save bot response
//           setState(() {
//             _allSessions[_activeSessionId]!.add(botMessage);
//           });
//           await _saveSessions();
//           await _saveToChatManager(_activeSessionId!, botMessage, decoded["chat_title"] ?? 'New Chat');

//           // 🔥 Auto-speak response
//           await _speak(reply);

//           // Show success for image analysis
//           if (userImage != null) {
//             Get.snackbar(
//               "✅ Image Analysis Complete",
//               "FixiBot has processed your vehicle image",
//               backgroundColor: Colors.green,
//               colorText: Colors.white,
//               duration: Duration(seconds: 3),
//             );
//           }
          
//         } catch (e) {
//           print('❌ JSON parsing error: $e');
//           print('   Raw response: ${response.body}');
//           _handleErrorResponse("Failed to parse server response: $e");
//         }
//       } else if (response.statusCode == 401) {
//         _handleErrorResponse("Authentication failed. Please log in again.");
//         await _initAuth();
//       } else if (response.statusCode == 422) {
//         print('❌ FastAPI Validation Error: ${response.body}');
//         _handleValidationError(response.body);
//       } else if (response.statusCode == 415) {
//         _handleErrorResponse("Unsupported media type. The image format may not be supported.");
//       } else if (response.statusCode == 413) {
//         _handleErrorResponse("Image file too large. Please select a smaller image (max 5MB).");
//       } else {
//         print('❌ Server error: ${response.statusCode}');
//         _handleErrorResponse("Server error: ${response.statusCode}\n${response.body}");
//       }
//     } catch (e) {
//       print('❌ Network error: $e');
//       _handleErrorResponse("Network error: ${e.toString()}");
//     } finally {
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }

//   // 🔥 FIXED: Improved image picker with better error handling
//   Future<void> _pickImage() async {
//     try {
//       print('📸 Opening image picker...');
      
//       // Check storage permission
//       var status = await Permission.storage.status;
//       if (!status.isGranted) {
//         status = await Permission.storage.request();
//         if (!status.isGranted) {
//           Get.snackbar(
//             "Permission Required",
//             "Storage access is needed to select images",
//             backgroundColor: Colors.orange,
//             colorText: Colors.white,
//           );
//           return;
//         }
//       }

//       final XFile? file = await _picker.pickImage(
//         source: ImageSource.gallery, 
//         imageQuality: 85,
//         maxWidth: 1200,
//         maxHeight: 1200,
//       );
      
//       if (file != null) {
//         final imageFile = File(file.path);
        
//         // Validate file size (max 5MB)
//         final fileSize = await imageFile.length();
//         if (fileSize > 5 * 1024 * 1024) {
//           Get.snackbar(
//             "File Too Large",
//             "Please select an image smaller than 5MB",
//             backgroundColor: Colors.orange,
//             colorText: Colors.white,
//           );
//           return;
//         }
        
//         // Validate file exists and is readable
//         if (!await imageFile.exists()) {
//           Get.snackbar(
//             "Error",
//             "Selected image file no longer exists",
//             backgroundColor: Colors.red,
//             colorText: Colors.white,
//           );
//           return;
//         }
        
//         setState(() => _selectedImage = imageFile);
        
//         // Auto-focus on text input after image selection
//         FocusScope.of(context).unfocus();
//         Future.delayed(Duration(milliseconds: 100), () {
//           FocusScope.of(context).requestFocus(FocusNode());
//         });
        
//         print('✅ Image selected: ${file.path} (${fileSize ~/ 1024} KB)');
        
//         // Show preview snackbar
//         Get.snackbar(
//           "Image Selected",
//           "Tap send to analyze the image",
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           duration: Duration(seconds: 2),
//         );
//       } else {
//         print('🔄 Image selection cancelled');
//       }
//     } catch (e) {
//       print('❌ Image picker error: $e');
//       Get.snackbar(
//         "Error Selecting Image",
//         "Please try again or select a different image",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         duration: Duration(seconds: 3),
//       );
//     }
//   }

//   String _formatMessageForDisplay(String text) {
//     if (text.isEmpty) return '';
    
//     String formattedText = text;
//     formattedText = formattedText.replaceAll('**', '');
    
//     if (formattedText.contains('###')) {
//       formattedText = formattedText.replaceAll('###', '• ');
//     }
    
//     return formattedText;
//   }

//   String _extractReplyFromResponse(Map<String, dynamic> response) {
//     try {
//       for (var value in response.values) {
//         if (value is String && value.isNotEmpty) {
//           return value;
//         }
//       }
//       return response.toString();
//     } catch (e) {
//       return "I've processed your request. How can I help you further?";
//     }
//   }

//   String _getMimeType(String fileExtension) {
//     switch (fileExtension) {
//       case 'jpg':
//       case 'jpeg':
//         return 'jpeg';
//       case 'png':
//         return 'png';
//       case 'gif':
//         return 'gif';
//       case 'webp':
//         return 'webp';
//       default:
//         return 'jpeg';
//     }
//   }

//   String _formatCVResponse(dynamic cvAnalysis) {
//     if (cvAnalysis is String) {
//       return cvAnalysis;
//     } else if (cvAnalysis is Map) {
//       final issues = cvAnalysis['issues'] ?? [];
//       final confidence = cvAnalysis['confidence'] ?? 0.0;
//       final recommendations = cvAnalysis['recommendations'] ?? [];
      
//       String response = "🔍 **Vehicle Image Analysis Complete**\n\n";
      
//       if (issues.isNotEmpty) {
//         response += "**Detected Issues:**\n";
//         for (var issue in issues) {
//           response += "• $issue\n";
//         }
//       } else {
//         response += "✅ No major issues detected.\n";
//       }
      
//       if (recommendations.isNotEmpty) {
//         response += "\n**Recommendations:**\n";
//         for (var rec in recommendations) {
//           response += "• $rec\n";
//         }
//       }
      
//       response += "\n_Confidence: ${(confidence * 100).toStringAsFixed(1)}%_";
//       return response;
//     }
    
//     return "I've analyzed your vehicle image. Please describe any specific concerns you have.";
//   }

//   void _handleValidationError(String errorBody) {
//     try {
//       final decoded = json.decode(errorBody);
//       final details = decoded['detail'];
//       String errorMessage = "Validation error: ";
      
//       if (details is List) {
//         for (var detail in details) {
//           errorMessage += "${detail['msg']} (${detail['loc']}); ";
//         }
//       } else {
//         errorMessage += "Invalid request format";
//       }
      
//       _handleErrorResponse(errorMessage);
//     } catch (e) {
//       _handleErrorResponse("Request validation failed: $errorBody");
//     }
//   }

//   void _handleErrorResponse(String error) {
//     print('❌ Chat error: $error');
    
//     setState(() {
//       _allSessions[_activeSessionId]!.add({
//         "text": "⚠️ **FixiBot Error**\n\nI encountered an issue while processing your request.\n\n**Error Details:** $error\n\nPlease try again or contact support if the problem persists.",
//         "formattedText": _formatMessageForDisplay("⚠️ FixiBot Error\n\nI encountered an issue while processing your request.\n\nError Details: $error\n\nPlease try again or contact support if the problem persists."),
//         "isSent": false,
//         "isError": true,
//         "timestamp": DateTime.now().toIso8601String(),
//       });
//     });
    
//     Get.snackbar(
//       "Processing Error",
//       "Failed to process your message",
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       duration: Duration(seconds: 5),
//     );
//   }

//   // 🔥 FIXED: Message Bubble with simple audio controls
//   Widget _buildMessageBubble(Map<String, dynamic> m) {
//     final isUser = m["isSent"] == true;
//     final hasImage = m["hasImage"] == true;
//     final isError = m["isError"] == true;
//     final isCVAnalysis = m["cvAnalysis"] == true;
//     final messageText = m["formattedText"]?.toString() ?? m["text"]?.toString() ?? '';
//     final cleanMessageText = messageText.replaceAll('*', '').replaceAll('#', '');
    
//     return Align(
//       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         padding: const EdgeInsets.all(12),
//         constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
//         decoration: BoxDecoration(
//           color: isError 
//             ? Colors.orange.shade100
//             : isCVAnalysis
//               ? Colors.blue.shade50
//               : isUser 
//                 ? AppColors.mainColor 
//                 : Colors.grey.shade300,
//           borderRadius: BorderRadius.circular(12),
//           border: isError 
//             ? Border.all(color: Colors.orange)
//             : isCVAnalysis
//               ? Border.all(color: Colors.blue.shade200)
//               : null,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔥 FIXED: Image preview with better error handling
//             if (hasImage && m.containsKey("imagePath"))
//               Column(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey.shade300),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: FutureBuilder<bool>(
//                         future: File(m["imagePath"]).exists(),
//                         builder: (context, snapshot) {
//                           if (snapshot.data == true) {
//                             return Image.file(
//                               File(m["imagePath"]),
//                               width: 200,
//                               height: 150,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return Container(
//                                   width: 200,
//                                   height: 150,
//                                   color: Colors.grey.shade200,
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.broken_image, color: Colors.grey, size: 40),
//                                       SizedBox(height: 8),
//                                       Text("Image not available", style: TextStyle(fontSize: 10)),
//                                     ],
//                                   ),
//                                 );
//                               },
//                             );
//                           } else {
//                             return Container(
//                               width: 200,
//                               height: 150,
//                               color: Colors.grey.shade200,
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
//                                   SizedBox(height: 8),
//                                   Text("Image file not found", style: TextStyle(fontSize: 10)),
//                                 ],
//                               ),
//                             );
//                           }
//                         },
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                 ],
//               ),
            
//             // Display text message
//             if (messageText.isNotEmpty)
//               Padding(
//                 padding: EdgeInsets.only(top: hasImage ? 4 : 0),
//                 child: _buildRichTextMessage(
//                   messageText,
//                   isUser: isUser,
//                   isError: isError,
//                   isCVAnalysis: isCVAnalysis,
//                 ),
//               ),
            
//             // Analysis type indicator
//             if ((isCVAnalysis || m["isImageAnalysis"] == true) && !isUser)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Row(
//                   children: [
//                     Icon(
//                       isCVAnalysis ? Icons.analytics : Icons.photo_library, 
//                       size: 12, 
//                       color: isCVAnalysis ? Colors.blue : Colors.green
//                     ),
//                     SizedBox(width: 4),
//                     Text(
//                       isCVAnalysis ? "CV Analysis" : "Image Analysis",
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: isCVAnalysis ? Colors.blue : Colors.green,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//             // 🔥 SIMPLIFIED: Audio controls for bot messages
//             if (!isUser && !isError && messageText.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8.0),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Play button (when not speaking this message)
//                     if (!_isSpeaking || _lastSpokenText != cleanMessageText)
//                       GestureDetector(
//                         onTap: () => _speak(messageText),
//                         child: Container(
//                           padding: EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade200,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Icon(
//                             Icons.volume_up_rounded,
//                             size: 16,
//                             color: Colors.black54,
//                           ),
//                         ),
//                       ),
                    
//                     // Pause button (when speaking this message)
//                     if (_isSpeaking && _lastSpokenText == cleanMessageText)
//                       GestureDetector(
//                         onTap: _pauseSpeaking,
//                         child: Container(
//                           padding: EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             color: Colors.orange.shade100,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Icon(
//                             Icons.pause_rounded,
//                             size: 16,
//                             color: Colors.orange.shade800,
//                           ),
//                         ),
//                       ),
                    
//                     // Resume button (when this message is paused)
//                     if (_isPaused && _lastSpokenText == cleanMessageText)
//                       GestureDetector(
//                         onTap: _resumeSpeaking,
//                         child: Container(
//                           padding: EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             color: Colors.green.shade100,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Icon(
//                             Icons.play_arrow_rounded,
//                             size: 16,
//                             color: Colors.green.shade800,
//                           ),
//                         ),
//                       ),
                    
//                     // Stop button (when speaking or paused this message)
//                     if ((_isSpeaking || _isPaused) && _lastSpokenText == cleanMessageText)
//                       GestureDetector(
//                         onTap: _stopSpeaking,
//                         child: Container(
//                           padding: EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             color: Colors.red.shade100,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Icon(
//                             Icons.stop_rounded,
//                             size: 16,
//                             color: Colors.red.shade800,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRichTextMessage(String text, {bool isUser = false, bool isError = false, bool isCVAnalysis = false}) {
//     final textColor = isError 
//       ? Colors.orange.shade900
//       : isCVAnalysis
//         ? Colors.blue.shade900
//         : isUser 
//           ? Colors.white 
//           : Colors.black87;

//     final baseStyle = TextStyle(
//       color: textColor,
//       fontSize: 14,
//       fontWeight: isError || isCVAnalysis ? FontWeight.w600 : FontWeight.normal,
//       height: 1.4,
//     );

//     final boldStyle = TextStyle(
//       color: textColor,
//       fontSize: 14,
//       fontWeight: FontWeight.bold,
//       height: 1.4,
//     );

//     if (text.contains('•')) {
//       return _buildBulletPoints(text, textColor: textColor, baseStyle: baseStyle, boldStyle: boldStyle);
//     }

//     return Text(text, style: baseStyle);
//   }

//   Widget _buildBulletPoints(String text, {required Color textColor, required TextStyle baseStyle, required TextStyle boldStyle}) {
//     final lines = text.split('\n');
//     final List<Widget> bulletWidgets = [];

//     for (final line in lines) {
//       if (line.trim().startsWith('•')) {
//         final bulletText = line.replaceFirst('•', '').trim();

//         bulletWidgets.add(
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 2.0),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(top: 2.0, right: 8.0),
//                   child: Icon(
//                     Icons.arrow_forward_ios,
//                     size: 12,
//                     color: textColor,
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(bulletText, style: baseStyle),
//                 ),
//               ],
//             ),
//           ),
//         );
//       } else if (line.trim().isNotEmpty) {
//         bulletWidgets.add(
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 2.0),
//             child: Text(line, style: baseStyle),
//           ),
//         );
//       } else {
//         bulletWidgets.add(const SizedBox(height: 4.0));
//       }
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: bulletWidgets,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final messages = _activeSessionId != null ? _allSessions[_activeSessionId] ?? [] : [];

//     // 🔥 Show language selection dialog if needed
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_showLanguageDialog && _activeSessionId != null && mounted) {
//         _showLanguageSelectionDialog();
//       }
//     });

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: CustomAppBar(
//         title: "FixiBot",
//         actions: [
//           // 🔥 Language Change Button
//           _buildLanguageChangeButton(),
//           IconButton(
//             icon: const Icon(Icons.history, color: AppColors.secondaryColor),
//             onPressed: () {
//               Get.to(ChatHistoryParentWidget());
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.add_comment, color: AppColors.secondaryColor),
//             tooltip: "New Chat",
//             onPressed: _startNewChat,
//           ),
//           IconButton(
//             icon: const Icon(Icons.build, color: AppColors.secondaryColor),
//             tooltip: "Fix Authentication",
//             onPressed: _manualAuthFix,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Vehicle Selection Header
//           Padding(
//             padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
//             child: Text(
//               "Select the vehicle to resolve an issue:",
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.mainColor,
//               ),
//             ),
//           ),

//           // 🔥 VEHICLE CHIPS WITH CATEGORY ICONS
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
//                           // 🔥 USING VEHICLE CATEGORY ICON
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

//           // Language Indicator
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             margin: EdgeInsets.symmetric(vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: AppColors.mainColor.withOpacity(0.3)),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.translate, size: 14, color: AppColors.mainColor),
//                 SizedBox(width: 6),
//                 Text(
//                   "Chatting in $_selectedLanguage",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: AppColors.mainColor,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 if (_isSpeaking) ...[
//                   SizedBox(width: 8),
//                   Icon(Icons.volume_up, size: 12, color: Colors.green),
//                   SizedBox(width: 4),
//                   Text(
//                     "Speaking...",
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: Colors.green,
//                     ),
//                   ),
//                 ] else if (_isPaused) ...[
//                   SizedBox(width: 8),
//                   Icon(Icons.pause, size: 12, color: Colors.orange),
//                   SizedBox(width: 4),
//                   Text(
//                     "Paused",
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: Colors.orange,
//                     ),
//                   ),
//                 ]
//               ],
//             ),
//           ),

//           // Chat Messages
//           Expanded(
//             child: Column(
//               children: [
//                 // Messages list
//                 Expanded(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(10),
//                     itemCount: messages.length,
//                     itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
//                   ),
//                 ),
                
//                 // Loading indicator
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
//                           _selectedImage != null ? 
//                             "Analyzing image with FixiBot..." : 
//                             "FixiBot is thinking...",
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

//           // 🔥 FIXED: Chat input with image preview
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: _isListening ? Colors.red : 
//                               _selectedImage != null ? Colors.green : 
//                               AppColors.mainColor.withOpacity(0.4),
//                         width: _isListening || _selectedImage != null ? 2.0 : 1.0,
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
//                                         // 🔥 USING VEHICLE CATEGORY ICON IN SELECTED CHIP
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
//                                             setState(() => _selectedVehicle = null);
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
//                                       Container(
//                                         decoration: BoxDecoration(
//                                           borderRadius: BorderRadius.circular(6),
//                                           border: Border.all(color: Colors.green),
//                                         ),
//                                         child: ClipRRect(
//                                           borderRadius: BorderRadius.circular(6),
//                                           child: Image.file(
//                                             _selectedImage!,
//                                             width: 50,
//                                             height: 50,
//                                             fit: BoxFit.cover,
//                                           ),
//                                         ),
//                                       ),
//                                       GestureDetector(
//                                         onTap: () {
//                                           setState(() => _selectedImage = null);
//                                         },
//                                         child: const CircleAvatar(
//                                           radius: 8,
//                                           backgroundColor: Colors.red,
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
//                             // Camera/Image button
//                             IconButton(
//                               icon: Stack(
//                                 children: [
//                                   Icon(Icons.camera_alt_rounded,
//                                       color: AppColors.mainColor),
//                                   if (_selectedImage != null)
//                                     Positioned(
//                                       right: 0,
//                                       top: 0,
//                                       child: Container(
//                                         padding: EdgeInsets.all(2),
//                                         decoration: BoxDecoration(
//                                           color: Colors.green,
//                                           borderRadius: BorderRadius.circular(6),
//                                         ),
//                                         child: Icon(Icons.check, size: 10, color: Colors.white),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                               onPressed: _pickImage,
//                               tooltip: "Add Image",
//                             ),
//                             // Text field
//                             Flexible(
//                               flex: 2,
//                               child: TextField(
//                                 controller: _controller,
//                                 decoration: InputDecoration(
//                                   border: InputBorder.none,
//                                   hintText: _isListening ? "Listening..." : 
//                                           _selectedImage != null ? "Describe image or tap send..." : 
//                                           "Type or speak...",
//                                   hintStyle: TextStyle(
//                                     color: _isListening ? Colors.red : 
//                                           _selectedImage != null ? Colors.green : 
//                                           Colors.grey
//                                   ),
//                                   isDense: true,
//                                   contentPadding: EdgeInsets.symmetric(
//                                       vertical: 8, horizontal: 8),
//                                 ),
//                                 minLines: 1,
//                                 maxLines: 4,
//                               ),
//                             ),
//                             // 🔥 Mic Button
//                             GestureDetector(
//                               onTap: _listen,
//                               child: Container(
//                                 margin: EdgeInsets.symmetric(horizontal: 4),
//                                 padding: EdgeInsets.all(8),
//                                 child: Icon(
//                                   _isListening ? Icons.mic : Icons.mic_none_rounded,
//                                   color: _isListening ? Colors.red : AppColors.mainColor,
//                                 ),
//                               ),
//                             ),
//                             // Send button
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
//                                   : Icon(Icons.send_rounded,
//                                       color: _selectedImage != null ? Colors.green : AppColors.mainColor),
//                               onPressed: _isProcessing ? null : sendMessage,
//                               tooltip: _selectedImage != null ? "Send Image for Analysis" : "Send Message",
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




















//latestLAN///////////
// import 'dart:convert';
// import 'dart:io';
// import 'package:fixibot_app/constants/appConfig.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:fixibot_app/screens/chatbot/chatHistoryParent.dart';
// import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// // 🔥 Voice & Permission Imports
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:permission_handler/permission_handler.dart';

// /// Keys to store/retrieve persistent data - NOW USER-SPECIFIC
// String getSessionsKey(String userId) => "all_chat_sessions_$userId";
// String getCurrentSessionKey(String userId) => "current_session_id_$userId";

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
  
//   // 🔥 Voice & Language State
//   late stt.SpeechToText _speech;
//   late FlutterTts _flutterTts;
//   bool _isListening = false;
//   bool _isSpeaking = false;
  
//   // Language Mapping (Display Name -> Locale ID)
//   final Map<String, String> _languages = {
//     'English': 'en-US',
//     'Urdu': 'ur-PK',
//     'Hindi': 'hi-IN',
//     'Punjabi': 'pa-PK',
//     'Sindhi': 'sd-PK',  // Sindhi (Pakistan)
//     // 'Pashto': 'ps-PK',  // Pashto (Pakistan)
//     // 'Punjabi': 'pa-IN', 
//   };
//   String _selectedLanguage = 'English'; // Default

//   final baseUrl = AppConfig.baseUrl;

//   // Auth & session
//   String? _accessToken;
//   String? _tokenType;
//   String? _sessionId;
//   String? _currentUserId;

//   // UI / chat state
//   File? _selectedImage;
//   Map<String, dynamic>? _selectedVehicle;
//   bool _isProcessing = false;

//   /// All sessions are stored here
//   Map<String, List<Map<String, dynamic>>> _allSessions = {};
//   String? _activeSessionId;
//   void _checkAvailableLocales() async {
//     bool available = await _speech.initialize();
//     if (available) {
//       var locales = await _speech.locales();
//       print("\n=== AVAILABLE SPEECH LOCALES ===");
//       for (var locale in locales) {
//         print("Name: ${locale.name}, ID: ${locale.localeId}");
//       }
//       print("================================\n");
//     } else {
//       print("Speech recognition not available");
//     }
//   }
//   @override
//   void initState() {
//     super.initState();
//     _initializeChatScreen();
//     _initVoiceFeatures(); // 🔥 Initialize Voice
//     _checkAvailableLocales();
//   }

//   @override
//   void dispose() {
//     _flutterTts.stop();
//     _speech.cancel();
//     super.dispose();
//   }

//   // 🔥 Initialize STT and TTS
//   void _initVoiceFeatures() async {
//     _speech = stt.SpeechToText();
//     _flutterTts = FlutterTts();

//     // Default setup
//     await _flutterTts.setLanguage("en-US");
//     await _flutterTts.setPitch(1.0);
//     await _flutterTts.setSpeechRate(0.5);
    
//     _flutterTts.setStartHandler(() {
//       setState(() => _isSpeaking = true);
//     });

//     _flutterTts.setCompletionHandler(() {
//       setState(() => _isSpeaking = false);
//     });

//     _flutterTts.setErrorHandler((msg) {
//       setState(() => _isSpeaking = false);
//     });
//   }

//   // 🔥 Handle Language Change (Update TTS Accent)
//   void _onLanguageChanged(String lang) async {
//     setState(() {
//       _selectedLanguage = lang;
//     });
//     String localeId = _languages[lang] ?? 'en-US';
    
//     // Check if the language is actually available on the device
//     bool isAvailable = await _flutterTts.isLanguageAvailable(localeId);
    
//     if (isAvailable) {
//       await _flutterTts.setLanguage(localeId);
//       print("🗣️ Language switched to: $lang ($localeId)");
//     } else {
//       Get.snackbar(
//         "Voice Not Supported", 
//         "Your device does not have a text-to-speech voice for $lang.",
//         backgroundColor: Colors.orange,
//         colorText: Colors.white
//       );
//       // Fallback to English or keep previous
//       await _flutterTts.setLanguage("en-US");
//     }
//   }

//   // 🔥 Start Listening (Mic Button)
//   void _listen() async {
//     if (!_isListening) {
//       // Request microphone permission
//       var status = await Permission.microphone.request();
//       if (status != PermissionStatus.granted) {
//         Get.snackbar("Permission Denied", "Microphone access is required.");
//         return;
//       }

//       bool available = await _speech.initialize(
//         onStatus: (status) => print('STT Status: $status'),
//         onError: (val) => print('STT Error: $val'),
//       );

//       if (available) {
//         setState(() => _isListening = true);
//         String localeId = _languages[_selectedLanguage] ?? 'en-US';
        
//         _speech.listen(
//           onResult: (val) {
//             setState(() {
//               _controller.text = val.recognizedWords;
//             });
//           },
//           localeId: localeId, // 🔥 Critical: Listen in selected language
//         );
//       }
//     } else {
//       setState(() => _isListening = false);
//       _speech.stop();
//     }
//   }

//   // 🔥 Text-to-Speech Logic
//   Future<void> _speak(String text) async {
//     if (text.isNotEmpty) {
//        // Clean text (remove markdown like ** or ###) before speaking
//        String cleanText = text.replaceAll('*', '').replaceAll('#', '');
//        await _flutterTts.speak(cleanText);
//     }
//   }

//   Future<void> _initializeChatScreen() async {
//     await vehicleController.fetchUserVehicles();
//     await _initAuth();
//     _startFreshSession();
//   }

//   /* ----------------- User-Specific Session Management ------------------ */

//   Future<void> _loadSessions() async {
//     if (_currentUserId == null) return;
    
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(getSessionsKey(_currentUserId!));
//     // final currentId = sp.getString(getCurrentSessionKey(_currentUserId!)); // Unused

//     if (stored != null) {
//       try {
//         final Map<String, dynamic> decoded = jsonDecode(stored);
//         _allSessions = decoded.map(
//             (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
//         print('📥 Loaded ${_allSessions.length} sessions for user: $_currentUserId');
//       } catch (e) {
//         print('❌ Error loading sessions: $e');
//         _allSessions = {};
//       }
//     } else {
//       _allSessions = {};
//     }

//     _startFreshSession();
//   }

//   Future<void> _saveSessions() async {
//     if (_currentUserId == null) return;
    
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(getSessionsKey(_currentUserId!), jsonEncode(_allSessions));
//     if (_activeSessionId != null) {
//       await sp.setString(getCurrentSessionKey(_currentUserId!), _activeSessionId!);
//     }
//     print('💾 Saved ${_allSessions.length} sessions for user: $_currentUserId');
//   }

//   void _startFreshSession() {
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     setState(() {
//       _allSessions[newId] = [];
//       _activeSessionId = newId;
//       _selectedVehicle = null; 
//       _selectedImage = null; 
//     });
//     print('🆕 Started fresh session: $newId for user: $_currentUserId');
//   }

//   void _startNewLocalSession() {
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//   }

//   Future<void> _startNewChat() async {
//     setState(() {
//       _startNewLocalSession();
//       _selectedVehicle = null; 
//     });
//     await _saveSessions();
//   }

//   // ... [Keep onDelete, _initAuth, _deepDebugAuth, _manualAuthFix, _startServerSession, _getSessionIdForVehicle, _createNewSessionForVehicle, _activateVehicleSession, _getVehicleIcon, _saveToChatManager AS THEY WERE] ...
//   // NOTE: I am condensing these existing methods to save space, but you should keep them exactly as they were in your original file.
  
//   Future<void> onDelete(String sessionId) async { /* Your existing code */ }
//   Future<void> _initAuth() async { /* Your existing code */ 
//       // ... (The implementation you provided) ...
//       // Make sure you call _startServerSession at the end like before
//       final prefs = await SharedPreferences.getInstance();
//       _accessToken = prefs.getString('access_token');
//       _tokenType = prefs.getString('token_type');
//       _currentUserId = prefs.getString('user_id');
//       if(_accessToken != null && _tokenType != null) await _startServerSession();
//   }
//   Future<void> _manualAuthFix() async { /* Your existing code */ }
  
//   Future<void> _startServerSession() async {
//     try {
//       if (_accessToken == null || _tokenType == null) return;
//       final authHeader = "$_tokenType $_accessToken";
      
//       final response = await http.post(
//         Uri.parse("$baseUrl/chat/start"),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": authHeader,
//         },
//       ).timeout(Duration(seconds: 10));
      
//       if (response.statusCode == 201) {
//         final data = json.decode(response.body);
//         _sessionId = data["session_id"];
//       } 
//     } catch (e) { print("Session Error: $e"); }
//   }

//   Future<void> _activateVehicleSession(String vehicleId) async {
//       final newId = DateTime.now().millisecondsSinceEpoch.toString();
//       setState(() => _activeSessionId = newId);
//       _allSessions[newId] = [];
//   }

//   Future<void> _saveToChatManager(String sessionId, Map<String, dynamic> message, String chatTitle) async {
//       if (Get.isRegistered<ChatManagerProvider>()) {
//         Get.find<ChatManagerProvider>().addMessageToSession(sessionId, message);
//       }
//   }
  
//   IconData _getVehicleIcon(Map<String, dynamic> vehicle) {
//     return Icons.directions_car; // Simplified for brevity, use your switch case
//   }

//   // -----------------------------------------------------------------------

//   Future<void> sendMessage() async {
//     if (_accessToken == null || _tokenType == null) {
//       Get.snackbar("Authentication Missing", "Please log in again");
//       await _initAuth();
//       return;
//     }
    
//     if (_selectedVehicle == null) {
//       Get.snackbar("Select Vehicle", "Please choose a vehicle", backgroundColor: Colors.redAccent, colorText: Colors.white);
//       return;
//     }
    
//     final text = _controller.text.trim();
//     final vehicleId = _selectedVehicle!["_id"];

//     if (text.isEmpty && _selectedImage == null) {
//       return;
//     }

//     if (_activeSessionId == null) {
//       await _activateVehicleSession(vehicleId);
//     }

//     final userText = text;
//     final userImage = _selectedImage;

//     // Clear input & Stop Listening
//     setState(() {
//       _controller.clear();
//       _selectedImage = null;
//       _isProcessing = true;
//       _isListening = false; 
//     });
//     _speech.stop();

//     // Create user message
//     final userMessage = {
//       "text": userText,
//       "formattedText": _formatMessageForDisplay(userText), 
//       "isSent": true,
//       "vehicleId": vehicleId,
//       "brand": _selectedVehicle?['brand'],
//       "model": _selectedVehicle?['model'],
//       "timestamp": DateTime.now().toIso8601String(),
//     };

//     if (userImage != null) {
//       userMessage["imagePath"] = userImage.path;
//       userMessage["hasImage"] = true;
//     }

//     setState(() {
//       _allSessions[_activeSessionId]!.add(userMessage);
//     });
//     await _saveSessions();
//     await _saveToChatManager(_activeSessionId!, userMessage, 'New Chat');

//     try {
//       final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
      
//       final authHeader = "$_tokenType $_accessToken";
//       request.headers["Authorization"] = authHeader;
//       request.headers["Accept"] = "application/json";

//       if (_sessionId != null) {
//         request.fields["session_id"] = _sessionId!;
//       }
      
//       if (userText.isNotEmpty) {
//         request.fields["message"] = userText;
//       } else {
//         request.fields["message"] = "Analyze this vehicle image";
//       }

//       // 🔥 SEND LANGUAGE PARAMETER TO BACKEND (Sandwich Step 1)
//       request.fields["language"] = _selectedLanguage;
      
//       request.fields["vehicle_json"] = json.encode(_selectedVehicle);

//       if (userImage != null) {
//         final fileExtension = userImage.path.split('.').last.toLowerCase();
//         final mimeType = _getMimeType(fileExtension);
//         final multipartFile = await http.MultipartFile.fromPath(
//           'image', 
//           userImage.path,
//           contentType: MediaType('image', mimeType),
//           filename: 'image.$fileExtension'
//         );
//         request.files.add(multipartFile);
//       }

//       final streamedResponse = await request.send().timeout(Duration(seconds: 30));
//       final response = await http.Response.fromStream(streamedResponse);

//       if (response.statusCode == 200) {
//         final decoded = json.decode(response.body);
        
//         // 🔥 Handle Sandwich Response
//         // 'response' is the Translated Text (e.g. Urdu)
//         // 'english_response' is the original English
//         String reply = "";
//         if (decoded.containsKey("response")) {
//           reply = decoded["response"]; 
//         } else {
//            reply = _extractReplyFromResponse(decoded);
//         }

//         final botMessage = {
//           "text": reply,
//           "formattedText": _formatMessageForDisplay(reply), 
//           "isSent": false,
//           "timestamp": DateTime.now().toIso8601String(),
//           "isImageAnalysis": userImage != null,
//         };

//         setState(() {
//           _allSessions[_activeSessionId]!.add(botMessage);
//         });
//         await _saveSessions();
//         await _saveToChatManager(_activeSessionId!, botMessage, decoded["chat_title"] ?? 'New Chat');

//         // 🔥 AUTO-SPEAK RESPONSE
//         await _speak(reply);

//       } else {
//         print('Server Error: ${response.body}');
//         _handleErrorResponse("Server error: ${response.statusCode}");
//       }
//     } catch (e) {
//       print('Network Error: $e');
//       _handleErrorResponse("Network error: $e");
//     } finally {
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }

//   // ... [Keep _formatMessageForDisplay, _extractReplyFromResponse, _getMimeType, _formatCVResponse, _handleValidationError, _handleErrorResponse, _pickImage AS IS] ...
//   // Copied basic implementation for completeness
//   String _formatMessageForDisplay(String text) {
//     return text.replaceAll('**', '').replaceAll('###', '• ');
//   }
  
//   String _extractReplyFromResponse(Map<String, dynamic> response) {
//     return response['response'] ?? response['reply'] ?? response['message'] ?? "Done";
//   }

//   String _getMimeType(String ext) => ext == 'png' ? 'png' : 'jpeg';
  
//   void _handleErrorResponse(String error) {
//       setState(() {
//          _allSessions[_activeSessionId]!.add({
//              "text": "Error: $error", "isSent": false, "isError": true
//          });
//       });
//   }

//   Future<void> _pickImage() async {
//       final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
//       if (file != null) setState(() => _selectedImage = File(file.path));
//   }

//   // 🔥 NEW: Language Chips Widget
//   Widget _buildLanguageChips() {
//     return Container(
//       height: 50,
//       margin: const EdgeInsets.only(top: 4, bottom: 4),
//       child: ListView(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         children: _languages.keys.map((lang) {
//           final isSelected = _selectedLanguage == lang;
//           return Padding(
//             padding: const EdgeInsets.only(right: 8.0),
//             child: ChoiceChip(
//               label: Text(lang),
//               labelStyle: TextStyle(
//                 color: isSelected ? Colors.white : AppColors.mainColor,
//                 fontSize: 12,
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//               ),
//               selected: isSelected,
//               selectedColor: AppColors.mainColor,
//               backgroundColor: Colors.white,
//               side: BorderSide(color: AppColors.mainColor.withOpacity(0.5)),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//               onSelected: (bool selected) {
//                 if (selected) _onLanguageChanged(lang);
//               },
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   // 🔥 UPDATED: Message Bubble with Audio Icon
//   Widget _buildMessageBubble(Map<String, dynamic> m) {
//     final isUser = m["isSent"] == true;
//     final hasImage = m["hasImage"] == true;
//     final isError = m["isError"] == true;
    
//     return Align(
//       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         padding: const EdgeInsets.all(12),
//         constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
//         decoration: BoxDecoration(
//           color: isError 
//             ? Colors.orange.shade100
//             : isUser 
//               ? AppColors.mainColor 
//               : Colors.grey.shade300,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (hasImage && m.containsKey("imagePath"))
//                Padding(
//                  padding: const EdgeInsets.only(bottom: 8.0),
//                  child: Image.file(File(m["imagePath"]), height: 150, width: double.infinity, fit: BoxFit.cover),
//                ),
            
//             if (m.containsKey("text"))
//                _buildRichTextMessage(m["text"].toString(), isUser: isUser, isError: isError),

//             // 🔥 Audio Replay Button for Bot
//             if (!isUser && !isError)
//               GestureDetector(
//                 onTap: () => _speak(m["text"].toString()),
//                 child: Padding(
//                   padding: const EdgeInsets.only(top: 6.0),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.volume_up_rounded, size: 16, color: Colors.black54),
//                       SizedBox(width: 4),
//                       Text("Listen", style: TextStyle(fontSize: 10, color: Colors.black54))
//                     ],
//                   ),
//                 ),
//               )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRichTextMessage(String text, {bool isUser = false, bool isError = false, bool isCVAnalysis = false}) {
//      // Keep your existing rich text logic implementation here
//      return Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final messages = _activeSessionId != null ? _allSessions[_activeSessionId] ?? [] : [];

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: CustomAppBar(
//         title: "FixiBot",
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.history, color: AppColors.secondaryColor),
//             onPressed: () => Get.to(ChatHistoryParentWidget()),
//           ),
//           IconButton(
//             icon: const Icon(Icons.add_comment, color: AppColors.secondaryColor),
//             onPressed: _startNewChat,
//           ),
//           IconButton(
//             icon: const Icon(Icons.build, color: AppColors.secondaryColor),
//             onPressed: _manualAuthFix,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // 1. Vehicle Selection
//           Padding(
//             padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
//             child: Text(
//               "Select the vehicle to resolve an issue:",
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.mainColor,
//               ),
//             ),
//           ),

//           // Vehicle Chips
//           Obx(() {
//             final vehicles = vehicleController.userVehicles;
//             if (vehicles.isEmpty) return const SizedBox(height: 50, child: Center(child: Text("No vehicles")));
//             return SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//               child: Row(
//                 children: vehicles.map((v) {
//                   final selected = _selectedVehicle != null && _selectedVehicle!["_id"] == v["_id"];
//                   return GestureDetector(
//                     onTap: () async {
//                       setState(() => _selectedVehicle = Map.from(v));
//                       await _activateVehicleSession(v["_id"]);
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(right: 8),
//                       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: selected ? AppColors.mainColor : AppColors.secondaryColor,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: Colors.white),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.directions_car, size: 16, color: selected ? Colors.white : AppColors.mainColor),
//                           const SizedBox(width: 6),
//                           Text("${v['brand']} ${v['model']}",
//                               style: TextStyle(
//                                   fontSize: 12,
//                                   color: selected ? Colors.white : AppColors.mainColor,
//                                   fontWeight: FontWeight.w500)),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             );
//           }),

//           // 2. 🔥 Language Chips (New)
//           _buildLanguageChips(),

//           // 3. Chat Messages
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(10),
//               itemCount: messages.length,
//               itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
//             ),
//           ),

//           // 4. Loading Indicator
//           if (_isProcessing)
//              Padding(
//                padding: const EdgeInsets.all(8.0),
//                child: LinearProgressIndicator(color: AppColors.mainColor, backgroundColor: Colors.white),
//              ),

//           // 5. Input Area (Updated with Mic)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Expanded(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: _isListening ? Colors.red : AppColors.mainColor.withOpacity(0.4),
//                         width: _isListening ? 2.0 : 1.0,
//                       ),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                          // Image Preview Logic (Visual only)
//                          if (_selectedImage != null)
//                             Padding(padding: EdgeInsets.all(8), child: Icon(Icons.image, color: AppColors.mainColor)),
                            
//                         Row(
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.camera_alt_rounded, color: AppColors.mainColor),
//                               onPressed: _pickImage,
//                             ),
//                             Flexible(
//                               child: TextField(
//                                 controller: _controller,
//                                 decoration: InputDecoration(
//                                   border: InputBorder.none,
//                                   // 🔥 Change hint text based on state
//                                   hintText: _isListening ? "Listening..." : "Type or speak...",
//                                   hintStyle: TextStyle(
//                                     color: _isListening ? Colors.red : Colors.grey
//                                   ),
//                                   contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//                                 ),
//                                 minLines: 1,
//                                 maxLines: 4,
//                               ),
//                             ),
//                             // 🔥 Mic Button
//                             GestureDetector(
//                               onTap: _listen,
//                               child: Container(
//                                 margin: EdgeInsets.symmetric(horizontal: 4),
//                                 padding: EdgeInsets.all(8),
//                                 child: Icon(
//                                   _isListening ? Icons.mic : Icons.mic_none_rounded,
//                                   color: _isListening ? Colors.red : AppColors.mainColor,
//                                 ),
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.send_rounded, color: AppColors.mainColor),
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
