import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/theme_provider.dart';
import '../main.dart';
import 'home_screen.dart';
import '../config/api_keys.dart'; // Import the API keys config

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Multiple API keys configuration - using the config file
  final List<String> _apiKeys = ApiKeys.openRouterApiKeys;
  int _currentApiKeyIndex = 0;
  late final List<bool> _apiKeyExhausted; // Track exhausted keys

  // API configuration - using the config file
  final String _apiUrl = ApiKeys.openRouterApiUrl;
  final String _model = ApiKeys.openRouterModel;
  late final AnimationController _typingController;
  Timer? _responseTimer;
  int _retryCount = 0;
  final int _maxRetries = 2;
  final int _responseTimeout = 15; // Reduced timeout for faster experience

  // Key for storing chat messages in SharedPreferences
  static const String _chatMessagesKey = 'ai_chat_messages';

  // Get current API key
  String get _currentApiKey => _apiKeys[_currentApiKeyIndex];

  // Switch to next available API key
  bool _switchToNextApiKey() {
    // Mark current key as exhausted
    _apiKeyExhausted[_currentApiKeyIndex] = true;

    // Find the next non-exhausted key
    for (int i = 0; i < _apiKeys.length; i++) {
      int nextIndex = (i + _currentApiKeyIndex + 1) % _apiKeys.length;
      if (!_apiKeyExhausted[nextIndex]) {
        _currentApiKeyIndex = nextIndex;
        debugPrint('Switched to API key ${_currentApiKeyIndex + 1}');
        return true;
      }
    }

    // All keys are currently marked as exhausted
    // This could happen if:
    // 1. All keys have genuinely hit their rate limits
    // 2. There might be a temporary network issue
    // 3. The daily quota may have reset
    
    // Let's try to reset and cycle through all keys again
    // This handles the case where the daily quota may have reset or it was a temporary issue
    debugPrint('All API keys are marked as exhausted. Attempting to reset and retry.');
    _resetApiKeyStatus();
    
    // Now try to use the first key again
    _currentApiKeyIndex = 0;
    debugPrint('Reset API keys and trying with key 1 again');
    return true;
  }

  // Reset API key status (for testing)
  void _resetApiKeyStatus() {
    for (int i = 0; i < _apiKeyExhausted.length; i++) {
      _apiKeyExhausted[i] = false;
    }
    _currentApiKeyIndex = 0;
    debugPrint('All API keys reset');
    
    // Show a snackbar to inform the user that keys have been reset
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("API connection refreshed. Ready to assist you again!"),
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize the API key exhausted list based on the number of keys
    _apiKeyExhausted = List.generate(_apiKeys.length, (_) => false);

    _typingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat(reverse: true);

    // Load saved messages or add welcome message if none exist
    _loadSavedMessages();
  }

  // Load saved messages from local storage
  Future<void> _loadSavedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMessagesJson = prefs.getStringList(_chatMessagesKey);

      if (savedMessagesJson != null && savedMessagesJson.isNotEmpty) {
        setState(() {
          _messages.clear();
          for (final messageJson in savedMessagesJson) {
            final messageMap = jsonDecode(messageJson);
            _messages.add(
              ChatMessage(
                text: messageMap['text'],
                isUser: messageMap['isUser'],
              ),
            );
          }
        });

        debugPrint('Loaded ${_messages.length} messages from local storage');

        // Scroll to bottom after loading messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        // If no saved messages, add the welcome message
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  "👋 Hello! I am BCA Scholar Hub AI Assistant. How can I help you today?",
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading saved messages: $e');
      // Add welcome message as fallback
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "👋 Hello! I am BCA Scholar Hub AI Assistant. How can I help you today?",
            isUser: false,
          ),
        );
      });
    }
  }

  // Save messages to local storage
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesToSave =
          _messages.map((message) {
            return jsonEncode({'text': message.text, 'isUser': message.isUser});
          }).toList();

      await prefs.setStringList(_chatMessagesKey, messagesToSave);
      debugPrint('Saved ${messagesToSave.length} messages to local storage');
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Save messages after adding user message
    _saveMessages();

    // Check for custom responses first
    if (_checkAndHandleCustomResponses(text)) {
      return;
    }

    // Special handling for greetings
    if (_isGreeting(text.toLowerCase())) {
      _handleGreeting();
      return;
    }

    _callAPI(text);
  }

  bool _checkAndHandleCustomResponses(String text) {
    final lowerText = text.toLowerCase().trim();

    // Creator question patterns
    final creatorPatterns = [
      'who created you',
      'who made you',
      'who developed you',
      'who is your creator',
      'who is your developer',
      'who built you',
      'who programmed you',
    ];

    // App info question patterns
    final appInfoPatterns = [
      'what is bca scholar hub',
      'tell me about bca scholar hub',
      'what is this app',
      'what does this app do',
      'what is the purpose of this app',
    ];

    // Check for Anish Chauhan mentions
    if (lowerText.contains('anish') ||
        lowerText.contains('chauhan') ||
        lowerText.contains('anish chauhan')) {
      _respondWithCustomMessage(
        "Anish Chauhan is the creator of me and this BCA Scholar Hub app. He developed this educational platform to help BCA students access study materials and AI assistance for their coursework.",
      );
      return true;
    }

    // Check for creator questions
    if (creatorPatterns.any((pattern) => lowerText.contains(pattern))) {
      _respondWithCustomMessage(
        "Mr. Anish Chauhan created me. I'm an AI assistant designed specifically for BCA students to help with their studies and questions.",
      );
      return true;
    }

    // Check for app info questions
    if (appInfoPatterns.any((pattern) => lowerText.contains(pattern))) {
      _respondWithCustomMessage(
        "BCA Scholar Hub is an educational app designed by Mr. Anish Chauhan for Bachelor of Computer Applications (BCA) students. It provides study materials, notes, and AI assistance to help students with their coursework and learning.",
      );
      return true;
    }

    return false;
  }

  void _respondWithCustomMessage(String message) {
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: message, isUser: false));
          _isTyping = false;
        });
        _scrollToBottom();

        // Save messages after adding custom response
        _saveMessages();
      }
    });
  }

  bool _isGreeting(String text) {
    final greetings = [
      'hello',
      'hi',
      'hey',
      'greetings',
      'howdy',
      'hola',
      'namaste',
      'good morning',
      'good afternoon',
      'good evening',
    ];

    return greetings.any(
      (greeting) => text.trim().toLowerCase().contains(greeting),
    );
  }

  void _handleGreeting() {
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  "👋 Hello! I am BCA Scholar Hub AI Assistant. How can I help you today?",
              isUser: false,
            ),
          );
          _isTyping = false;
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _callAPI(String userMessage) async {
    // Set a timeout for the API call
    _responseTimer?.cancel();
    _responseTimer = Timer(Duration(seconds: _responseTimeout), () {
      if (_isTyping && mounted) {
        _retryOrFallback(userMessage);
      }
    });

    try {
      debugPrint('Sending message to Mistral AI using model: $_model');
      debugPrint(
        'Using API key ${_currentApiKeyIndex + 1}: ${_currentApiKey.substring(0, 10)}...',
      );

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_currentApiKey',
              'HTTP-Referer': 'https://bca-scholar-hub.com',
              'X-Title': 'BCA Scholar Hub',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a professional AI assistant for BCA students. Keep your responses concise, clear, and easy to understand. Use simple language and limit explanations to 2-3 short paragraphs when possible. Always complete your sentences and end paragraphs with proper punctuation. Avoid technical jargon unless necessary. For lists, use simple numbered points (1., 2., 3.) and keep them brief. Do not use markdown formatting like asterisks or hashtags. Provide direct, practical answers that are helpful for undergraduate students.',
                },
                {'role': 'user', 'content': userMessage},
              ],
              'temperature': 0.7,
              'max_tokens': 400,
            }),
          )
          .timeout(Duration(seconds: _responseTimeout));

      if (!mounted) return;

      debugPrint('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint(
          'API Response Data: ${response.body.substring(0, min(100, response.body.length))}...',
        );

        final String responseContent = data['choices'][0]['message']['content'];

        if (responseContent.isNotEmpty) {
          // Process the response to ensure it's properly formatted
          final processedResponse = _processAIResponse(responseContent);

          setState(() {
            _messages.add(ChatMessage(text: processedResponse, isUser: false));
            _isTyping = false;
          });

          // Save messages after adding AI response
          _saveMessages();

          _scrollToBottom();
          return;
        } else {
          debugPrint('Empty or null AI response');
        }
      } else if (response.statusCode == 429) {
        // Rate limit exceeded - try switching to another API key
        debugPrint(
          'API key ${_currentApiKeyIndex + 1} exhausted (status: 429)',
        );

        if (_switchToNextApiKey()) {
          // Successfully switched to another key, retry the request
          debugPrint('Switched to API key ${_currentApiKeyIndex + 1}');
          debugPrint('Retrying with new API key ${_currentApiKeyIndex + 1}');
          _callAPI(userMessage);
          return;
        } else {
          // This shouldn't happen anymore with our improved logic, but just in case
          setState(() {
            _messages.add(
              ChatMessage(
                text:
                    "I've temporarily reached my usage limit. Please wait a moment and try again.",
                isUser: false,
              ),
            );
            _isTyping = false;
          });

          // Save error message
          _saveMessages();

          _scrollToBottom();
          return;
        }
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
      }

      // If we get here, something went wrong with the response
      _retryOrFallback(userMessage);
    } catch (e) {
      if (mounted) {
        debugPrint('API Error: $e');
        _retryOrFallback(userMessage);
      }
    }
  }

  void _retryOrFallback(String userMessage) {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      debugPrint('Retrying API call, attempt $_retryCount of $_maxRetries');
      // Add a small delay before retrying to avoid overwhelming the API
      Future.delayed(const Duration(seconds: 1), () {
        _callAPI(userMessage);
      });
    } else {
      // Reset retry count
      _retryCount = 0;

      // Try switching API key as a last resort
      if (_switchToNextApiKey()) {
        debugPrint('Trying with another API key after multiple failures');
        _callAPI(userMessage);
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  "I'm having trouble connecting right now. Please try again in a moment.",
              isUser: false,
            ),
          );
          _isTyping = false;
        });

        // Save fallback message
        _saveMessages();

        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF0F2F5);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        // Save messages before navigating away
        _saveMessages();

        // Navigate back to home screen instead of exiting the app
        // Get the pages list from main app
        final List<Widget> pages = myAppKey.currentState?.getPages() ?? [];

        // Navigate to home screen with index 0 (home)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => HomeScreen(
                  currentIndex: 0,
                  pages: pages,
                  onIndexChanged: (index) {
                    myAppKey.currentState?.updateIndex(index);
                  },
                ),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "AI Assistant",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate back to home screen
              // Get the pages list from main app
              final List<Widget> pages =
                  myAppKey.currentState?.getPages() ?? [];

              // Navigate to home screen with index 0 (home)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => HomeScreen(
                        currentIndex: 0,
                        pages: pages,
                        onIndexChanged: (index) {
                          myAppKey.currentState?.updateIndex(index);
                        },
                      ),
                ),
              );
            },
          ),
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 2,
          actions: [
            // API key status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color:
                    _apiKeyExhausted.every((exhausted) => exhausted)
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "API Key: ${_currentApiKeyIndex + 1}/${_apiKeys.length}",
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _apiKeyExhausted.every((exhausted) => exhausted)
                              ? Colors.red
                              : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _apiKeys.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _apiKeyExhausted[index]
                                  ? Colors.red
                                  : Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Reset API keys button
            IconButton(
              icon: const Icon(Icons.vpn_key),
              onPressed: () {
                _resetApiKeyStatus();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("API keys reset successfully"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Reset API keys',
            ),
            // Restart conversation button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  // Keep only the first welcome message
                  if (_messages.isNotEmpty) {
                    final welcomeMessage = _messages.first;
                    _messages.clear();
                    _messages.add(welcomeMessage);
                  } else {
                    // If somehow there's no message, add the welcome message
                    _messages.add(
                      ChatMessage(
                        text:
                            "👋 Hello! I am BCA Scholar Hub AI Assistant. How can I help you today?",
                        isUser: false,
                      ),
                    );
                  }
                });

                // Save the reset conversation state
                _saveMessages();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Conversation restarted"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Restart conversation',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isDarkMode
                      ? [const Color(0xFF121212), const Color(0xFF1D1D1D)]
                      : [const Color(0xFFE8EAF6), const Color(0xFFF5F7FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child:
                    _messages.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 80,
                                color:
                                    isDarkMode
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.blue.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Start a conversation with the AI assistant',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDarkMode
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _messages.length) {
                              return _buildMessageBubble(
                                _messages[index],
                                isDarkMode,
                              );
                            } else {
                              // Show typing indicator
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.indigo.shade500,
                                            Colors.blue.shade500,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        radius: 18,
                                        child: Icon(
                                          Icons.assistant,
                                          size: 20,
                                          color: Colors.indigo.shade700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isDarkMode
                                                ? const Color(0xFF2D2D2D)
                                                : Colors.white,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(5),
                                          topRight: Radius.circular(20),
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedBuilder(
                                            animation: _typingController,
                                            builder: (context, child) {
                                              return Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade500
                                                      .withOpacity(
                                                        _typingController.value,
                                                      ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors
                                                          .blue
                                                          .shade300
                                                          .withOpacity(0.5),
                                                      blurRadius: 4,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 6),
                                          AnimatedBuilder(
                                            animation: _typingController,
                                            builder: (context, child) {
                                              return Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade500
                                                      .withOpacity(
                                                        1 -
                                                            _typingController
                                                                .value,
                                                      ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors
                                                          .blue
                                                          .shade300
                                                          .withOpacity(0.5),
                                                      blurRadius: 4,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 6),
                                          AnimatedBuilder(
                                            animation: _typingController,
                                            builder: (context, child) {
                                              return Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade500
                                                      .withOpacity(
                                                        _typingController.value,
                                                      ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors
                                                          .blue
                                                          .shade300
                                                          .withOpacity(0.5),
                                                      blurRadius: 4,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: TextStyle(
                            color:
                                isDarkMode ? Colors.grey : Colors.grey.shade600,
                          ),
                          fillColor:
                              isDarkMode
                                  ? const Color(0xFF2D2D2D)
                                  : Colors.grey.shade100,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted:
                            _isTyping ? null : (text) => _sendMessage(text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap:
                            _isTyping
                                ? null
                                : () => _sendMessage(_messageController.text),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDarkMode) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade500, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Icon(
                  Icons.assistant,
                  size: 20,
                  color: Colors.indigo.shade700,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser
                        ? Colors.blue.shade600
                        : (isDarkMode ? const Color(0xFF2D2D2D) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft:
                      isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(5),
                  topRight:
                      isUser
                          ? const Radius.circular(5)
                          : const Radius.circular(20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color:
                      isUser
                          ? Colors.white
                          : (isDarkMode ? Colors.white : Colors.black),
                  fontSize: 16,
                  height: 1.4, // Better line spacing for readability
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.indigo.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Process AI response to ensure complete sentences and proper formatting
  String _processAIResponse(String response) {
    // Remove all markdown symbols
    String processed = response
        .replaceAll(RegExp(r'\*\*'), '') // Bold
        .replaceAll(RegExp(r'\*'), '') // Italic
        .replaceAll(RegExp(r'#+\s*'), '') // Headings
        .replaceAll(RegExp(r'`{3}.*?`{3}', dotAll: true), '') // Code blocks
        .replaceAll(RegExp(r'`'), ''); // Inline code

    // Ensure response ends with proper punctuation
    if (processed.isNotEmpty &&
        !processed.endsWith('.') &&
        !processed.endsWith('!') &&
        !processed.endsWith('?') &&
        !processed.endsWith(':') &&
        !processed.endsWith(';')) {
      processed = '$processed.';
    }

    // Fix any incomplete sentences by removing them or adding a period
    final sentences = processed.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.isNotEmpty) {
      final lastSentence = sentences.last;
      if (lastSentence.length < 5 && !lastSentence.contains(RegExp(r'[.!?]'))) {
        // Remove very short incomplete sentences
        sentences.removeLast();
        processed = sentences.join(' ');
      }
    }

    return processed;
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
