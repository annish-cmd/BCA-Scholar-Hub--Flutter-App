import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../utils/theme_provider.dart';
import '../utils/auth_provider.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import 'auth/login_screen.dart';
import '../main.dart';
import 'package:logger/logger.dart';

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  late ChatService _chatService;
  List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _errorMessage = '';
  bool _isLoading = true;
  bool _isEncryptionInitialized = false;
  ChatMessage? _replyingToMessage;
  final Logger _logger = Logger();

  bool _isSendingMessage = false; // Flag to prevent duplicate message sends

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);

    // Show loading indicator immediately
    setState(() {
      _isLoading = true;
    });

    // Immediately load cached messages first (this should be very fast)
    _loadMessagesImmediately();
  }

  // Load messages instantly
  Future<void> _loadMessagesImmediately() async {
    try {
      // Get cached messages for instant display
      final cachedMessages = await _chatService.getCachedMessages();

      if (mounted && cachedMessages.isNotEmpty) {
        setState(() {
          _messages = cachedMessages;
          _isLoading = false;
        });

        // Instant scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }

      // Set up real-time listener
      _setupMessageListener();

      // Initialize encryption in background
      _checkEncryptionStatus();
    } catch (e) {
      _logger.e('Load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _setupMessageListener();
      _checkEncryptionStatus();
    }
  }



  // Real-time message listener with instant updates
  void _setupMessageListener() {
    _chatService.getMessagesStream().listen(
      (messages) {
        if (!mounted) return;
        
        final shouldScroll = _scrollController.hasClients &&
            (_scrollController.position.maxScrollExtent - _scrollController.offset) < 200;
        
        final hasNewMessages = messages.length > _messages.length;

        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        // Auto-scroll for new messages
        if (shouldScroll && hasNewMessages) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
              );
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          _logger.e('Stream error: $error');
          setState(() {
            _errorMessage = 'Connection error. Retrying...';
            _isLoading = false;
          });
        }
      },
    );
  }

  // Check encryption status (non-blocking)
  void _checkEncryptionStatus() {
    _chatService.checkAndInitializeEncryption().then((_) {
      if (mounted) {
        _isEncryptionInitialized = _chatService.isEncryptionInitialized;
      }
    }).catchError((e) {
      _logger.e('Encryption error: $e');
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Instant scroll to bottom
  void _scrollToBottomSmooth() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  // Legacy method for backward compatibility
  void _scrollToBottom() {
    _scrollToBottomSmooth();
  }

  // Get messages - only Firebase messages, no optimistic UI
  List<ChatMessage> get _combinedMessages {
    return _messages;
  }

  // Send message - clean approach without temporary messages
  Future<void> _sendMessage() async {
    // CRITICAL: Check if already sending at the very start
    if (_isSendingMessage) {
      _logger.w('Message send already in progress, ignoring duplicate request');
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final messageText = _messageController.text.trim();
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final replyToId = _replyingToMessage?.id;

    // Mark as sending IMMEDIATELY to prevent duplicate sends
    setState(() {
      _isSendingMessage = true;
    });

    // Clear input and reply state immediately
    _messageController.clear();
    if (_replyingToMessage != null) {
      setState(() {
        _replyingToMessage = null;
      });
    }

    try {
      // Send message to Firebase (encryption handled by service)
      final success = await _chatService.sendMessage(
        messageText,
        replyToId: replyToId,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Always reset the flag
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      } else {
        _isSendingMessage = false;
      }
    }
  }

  // Helper method to check if there are any temporary messages
  bool _hasAnyTempMessages() {
    return _messages.any((m) => m.id.startsWith('temp-'));
  }

  // Helper method to check if message is older than 5 minutes
  bool _isMessageOlderThan5Minutes(ChatMessage message) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - message.timestamp) > 300000; // 5 minutes in milliseconds
  }

  // Simplified method to check if message should show "before joined" text
  bool _shouldShowBeforeJoinedMessage(ChatMessage message) {
    // Must be encrypted with empty text (failed decryption)
    if (!message.isEncrypted || message.text.isNotEmpty) {
      return false;
    }

    // Don't show for temporary messages (check by ID)
    if (message.id.startsWith('temp-')) {
      return false;
    }

    // Simple logic: if encrypted message has no text, user probably can't decrypt it
    // This covers most cases where new users can't see old messages
    return true;
  }

  // Cancel reply mode
  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  // Set replying to message
  void _replyToMessage(ChatMessage message) {
    setState(() {
      _replyingToMessage = message;
    });
    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  // Delete a message
  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      await _chatService.deleteMessage(message);
      if (_replyingToMessage?.id == message.id) {
        _cancelReply();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  // Show message options menu
  void _showMessageOptions(BuildContext context, ChatMessage message) {
    final canDelete = _chatService.canDeleteMessage(message);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _replyToMessage(message);
                },
              ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Format timestamp to readable date/time
  String _formatTimestamp(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();

    // If the message is from today, just show the time
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return DateFormat('h:mm a').format(dateTime); // e.g. "3:30 PM"
    }

    // If the message is from this year, show month, day and time
    if (dateTime.year == now.year) {
      return DateFormat(
        'MMM d, h:mm a',
      ).format(dateTime); // e.g. "Apr 3, 3:30 PM"
    }

    // Otherwise, show full date with time
    return DateFormat(
      'MMM d, y, h:mm a',
    ).format(dateTime); // e.g. "Apr 3, 2023, 3:30 PM"
  }

  // Clear error message
  void _clearErrorMessage() {
    setState(() {
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final chatService = Provider.of<ChatService>(
      context,
    ); // Listen to chatService
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final backgroundColor = isDarkMode ? Colors.black87 : Colors.white;
    final bubbleColor = isDarkMode ? Colors.grey[850] : Colors.grey[200];
    final userBubbleColor = Theme.of(context).primaryColor;
    final secondaryBackgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : Colors.purple[50]!;
    final cardColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;

    // Update encryption status from the service
    _isEncryptionInitialized = chatService.isEncryptionInitialized;

    // Check if user is logged in
    if (!authProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Global Chat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 2,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundColor, secondaryBackgroundColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Card(
              elevation: 5,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Login Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please login to join the global chat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder:
                                (context) => LoginScreen(
                                  pages: myAppKey.currentState!.getPages(),
                                ),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Login Now',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Global Chat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // Hide encryption status from UI
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundColor, secondaryBackgroundColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Error message if any
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: _clearErrorMessage,
                    ),
                  ],
                ),
              ),

            // Chat messages with optimized rendering
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _combinedMessages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet.\nStart the conversation!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _combinedMessages.length,
                              // Professional optimization
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: true,
                              cacheExtent: 1000,
                              physics: const ClampingScrollPhysics(),
                              itemBuilder: (context, index) {
                                final message = _combinedMessages[index];
                                final isCurrentUser = message.userId == authProvider.currentUser?.uid;

                                // Wrap in RepaintBoundary for better performance
                                return RepaintBoundary(
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: GestureDetector(
                                      onLongPress: () => _showMessageOptions(context, message),
                                      child: Align(
                                        alignment: isCurrentUser
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 4),
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isCurrentUser
                                                ? Colors.blue[700]
                                                : (isDarkMode
                                                    ? const Color(0xFF2D2D2D)
                                                    : Colors.grey[200]),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Message header (username and time)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          message.userName,
                                                          style: TextStyle(
                                                            color:
                                                                isCurrentUser
                                                                    ? Colors.white
                                                                    : (isDarkMode
                                                                        ? Colors
                                                                            .blue[200]
                                                                        : Colors
                                                                            .blue[700]),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _formatTimestamp(
                                                          message.timestamp,
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              isCurrentUser
                                                                  ? Colors.white70
                                                                  : (isDarkMode
                                                                      ? Colors
                                                                          .grey[400]
                                                                      : Colors
                                                                          .grey[600]),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),

                                              // Show compact "Message from before you joined" for blank encrypted messages
                                              if (message.isEncrypted &&
                                                  message.text.isEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                    top: 2,
                                                  ),
                                                  child: Text(
                                                    "🔒✨ Message from before you joined",
                                                    style: TextStyle(
                                                      fontStyle: FontStyle.italic,
                                                      color:
                                                          isCurrentUser
                                                              ? Colors.white60
                                                              : (isDarkMode
                                                                  ? Colors.grey[500]
                                                                  : Colors
                                                                      .grey[500]),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),

                                              // Reply indicator if this is a reply
                                              if (message.replyToId != null)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    top: 5,
                                                    bottom: 5,
                                                  ),
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isCurrentUser
                                                            ? Colors.blue[800]
                                                            : (isDarkMode
                                                                ? const Color(
                                                                  0xFF3D3D3D,
                                                                )
                                                                : Colors.grey[300]),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Reply to ${message.replyToUserName}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color:
                                                              isCurrentUser
                                                                  ? Colors.white70
                                                                  : (isDarkMode
                                                                      ? Colors
                                                                          .grey[400]
                                                                      : Colors
                                                                          .grey[600]),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        message.replyToText !=
                                                                    null &&
                                                                message
                                                                        .replyToText!
                                                                        .length >
                                                                    50
                                                            ? '${message.replyToText!.substring(0, 50)}...'
                                                            : message.replyToText ??
                                                                '',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              isCurrentUser
                                                                  ? Colors.white70
                                                                  : (isDarkMode
                                                                      ? Colors
                                                                          .grey[300]
                                                                      : Colors
                                                                          .grey[800]),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                              const SizedBox(height: 5),
                                              // Message text (without the extra lock icon)
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Removed the lock icon that was showing on the left side
                                                  Expanded(
                                                    child: Text(
                                                      // Smart message display logic
                                                      message.text.isNotEmpty
                                                          ? message.text
                                                          : '', // Always empty for messages without text
                                                      style: TextStyle(
                                                        color:
                                                            isCurrentUser
                                                                ? Colors.white
                                                                : textColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                            },
                          ),

                          // Reply indicator
                          if (_replyingToMessage != null)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? const Color(
                                            0xFF2D2D2D,
                                          ).withOpacity(0.95)
                                          : Colors.grey[200]!.withOpacity(0.95),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.reply,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Replying to ${_replyingToMessage!.userName}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            _replyingToMessage!
                                                        .text
                                                        .isNotEmpty &&
                                                    _replyingToMessage!
                                                            .text
                                                            .length >
                                                        50
                                                ? '${_replyingToMessage!.text.substring(0, 50)}...'
                                                : _replyingToMessage!.text,
                                            style: TextStyle(
                                              color:
                                                  isDarkMode
                                                      ? Colors.grey[400]
                                                      : Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: _cancelReply,
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
            ),

            // Message input
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Hide encryption indicators from input area
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor:
                            isDarkMode
                                ? const Color(0xFF2D2D2D)
                                : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color:
                                _replyingToMessage != null
                                    ? Colors.green
                                    : Colors.purple.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.blue,
                            width: 1.5,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  Material(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(24),
                    elevation: 2,
                    child: InkWell(
                      onTap: _sendMessage,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
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
    );
  }
}
