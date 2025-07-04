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
  List<ChatMessage> _tempMessages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _errorMessage = '';
  bool _isLoading = true;
  bool _isEncryptionInitialized = false;
  ChatMessage? _replyingToMessage;
  bool isReplyMode = false;
  ChatMessage? replyToMessage;
  final Logger _logger = Logger();

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

  // Load messages with high priority
  Future<void> _loadMessagesImmediately() async {
    try {
      // Use the optimized cached messages method
      final cachedMessages = await _chatService.getCachedMessages();

      if (mounted) {
        setState(() {
          if (cachedMessages.isNotEmpty) {
            _messages = cachedMessages;
            _isLoading = false;
          }
        });

        // Scroll to bottom after cached messages are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      // Now set up the real-time listener for new messages
      _setupMessageListener();

      // Check encryption status in parallel
      _checkEncryptionStatus();

      // Force refresh messages after a short delay to ensure all messages are visible
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _chatService.refreshMessages();
        }
      });

      // Clear any existing error messages
      _errorMessage = '';
    } catch (e) {
      _logger.e('Error in _loadMessagesImmediately: $e');

      // Even if this fails, still set up the message listener
      _setupMessageListener();
      _checkEncryptionStatus();
    }
  }

  // Set up real-time listener for message updates
  void _setupMessageListener() {
    _chatService.getMessagesStream().listen(
      (messages) {
        if (mounted) {
          final bool shouldScrollToBottom = 
              _scrollController.hasClients &&
              (_scrollController.position.maxScrollExtent - _scrollController.offset) < 200;
          
          setState(() {
            _messages = messages;
            _isLoading = false;
          });

          // Scroll to bottom when new messages arrive if user was already near bottom
          if (shouldScrollToBottom) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
          
          // Always scroll to bottom if a new message arrives in the last 2 seconds
          final now = DateTime.now().millisecondsSinceEpoch;
          final hasNewMessage = messages.any((m) => (now - m.timestamp) < 2000);
          
          if (hasNewMessage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error loading messages. Please try again.';
            _isLoading = false;
          });
          _logger.e('Error in message stream: $error');
        }
      },
    );
  }

  // Check encryption status
  void _checkEncryptionStatus() {
    _isEncryptionInitialized = _chatService.isEncryptionInitialized;

    // If not initialized, try initializing now
    if (!_isEncryptionInitialized) {
      _chatService
          .checkAndInitializeEncryption()
          .then((_) {
            if (mounted) {
              setState(() {
                _isEncryptionInitialized = _chatService.isEncryptionInitialized;
              });
            }
          })
          .catchError((e) {
            _logger.e('Error initializing encryption: $e');
          });
    }

    setState(() {});
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll to bottom of chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Send message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      final messageText = _messageController.text.trim();
      _messageController.clear();

      // Add a temporary message while it's sending
      final tempMessage = ChatMessage(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        userId: firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '',
        userName:
            firebase_auth.FirebaseAuth.instance.currentUser?.displayName ??
            'Me',
        text: messageText,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        userPhotoUrl: firebase_auth.FirebaseAuth.instance.currentUser?.photoURL,
        isEncrypted: _isEncryptionInitialized,
      );

      setState(() {
        _tempMessages.add(tempMessage);
        _messages = [..._messages, tempMessage];
      });

      // Scroll to bottom to show the new message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      try {
        // First, force check the encryption status
        if (!_isEncryptionInitialized) {
          await _chatService.checkAndInitializeEncryption();
          setState(() {
            _isEncryptionInitialized = _chatService.isEncryptionInitialized;
          });
        }

        // Send message to the service
        final replyToId = _replyingToMessage?.id;
        final success = await _chatService.sendMessage(
          messageText,
          replyToId: replyToId,
        );

        if (!success) {
          // If failed with encryption, try again without encryption
          if (_isEncryptionInitialized) {
            setState(() {
              _isEncryptionInitialized = false;
            });

            final retrySuccess = await _chatService.sendMessage(
              messageText,
              replyToId: replyToId,
            );

            if (!retrySuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Failed to send message. Please restart the app and try again.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to send message. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // Remove temp message after a delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _messages =
                  _messages.where((m) => m.id != tempMessage.id).toList();
              _tempMessages.remove(tempMessage);
            });
          }
        });
      }

      // Clear reply if there was one
      if (_replyingToMessage != null) {
        setState(() {
          _replyingToMessage = null;
        });
      }
    }
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
      return DateFormat('MMM d, h:mm a').format(dateTime); // e.g. "Apr 3, 3:30 PM"
    }

    // Otherwise, show full date with time
    return DateFormat('MMM d, y, h:mm a').format(dateTime); // e.g. "Apr 3, 2023, 3:30 PM"
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
            // Encryption status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    _isEncryptionInitialized
                        ? Colors.green[700]
                        : Colors.orange[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isEncryptionInitialized ? Icons.lock : Icons.lock_open,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isEncryptionInitialized ? 'Encrypted' : 'Setting up...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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

            // Chat messages
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              "Loading messages...",
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      )
                      : _messages.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                            SizedBox(height: 16),
                            Text(
                              _errorMessage.isNotEmpty
                                  ? _errorMessage
                                  : 'No messages yet.\nStart the conversation!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
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
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isCurrentUser =
                                  message.userId ==
                                  authProvider.currentUser?.uid;
                              final isTemporary = message.id.startsWith(
                                'temp-',
                              );

                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: isTemporary ? 0.7 : 1.0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutQuint,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: GestureDetector(
                                    onLongPress: () {
                                      if (!isTemporary) {
                                        _showMessageOptions(context, message);
                                      }
                                    },
                                    child: Align(
                                      alignment:
                                          isCurrentUser
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.75,
                                        ),
                                        decoration: BoxDecoration(
                                          color: message.isAdmin
                                              ? (isDarkMode
                                                  ? Colors.orange[800]
                                                  : Colors.orange[100])
                                              : (isCurrentUser
                                                  ? Colors.blue[700]
                                                  : (isDarkMode
                                                      ? const Color(0xFF2D2D2D)
                                                      : Colors.grey[200])),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: message.isAdmin
                                              ? Border.all(
                                                  color: Colors.orange[600]!,
                                                  width: 2,
                                                )
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
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
                                                      if (message.isAdmin)
                                                        Container(
                                                          margin: const EdgeInsets.only(left: 6),
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.orange[700],
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            'ADMIN',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    // Show encryption indicator
                                                    if (message.isEncrypted &&
                                                        !isTemporary)
                                                      Tooltip(
                                                        message:
                                                            'End-to-End Encrypted',
                                                        child: Icon(
                                                          Icons.lock,
                                                          size: 12,
                                                          color:
                                                              isCurrentUser
                                                                  ? Colors
                                                                      .white70
                                                                  : Colors
                                                                      .green[300],
                                                        ),
                                                      ),
                                                    if (isTemporary)
                                                      Container(
                                                        margin:
                                                            const EdgeInsets.only(
                                                              right: 4,
                                                            ),
                                                        width: 8,
                                                        height: 8,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              isCurrentUser
                                                                  ? Colors
                                                                      .white70
                                                                  : Colors
                                                                      .blue[300],
                                                        ),
                                                      ),
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

                                            // Only show "Message from before you joined" when the message is blank due to encryption
                                            // This happens when the user can't decrypt the message because they weren't present when it was sent
                                            if (message.isEncrypted && message.text.isEmpty && !isTemporary)
                                            Container(
                                              margin: const EdgeInsets.only(top: 4, bottom: 4),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.lock,
                                                    size: 14,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "Message from before you joined",
                                                    style: TextStyle(
                                                      fontStyle: FontStyle.italic,
                                                      color: isCurrentUser
                                                          ? Colors.white70
                                                          : (isDarkMode
                                                              ? Colors.grey[400]
                                                              : Colors.grey[600]),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Reply indicator if this is a reply
                                            if (message.replyToId != null)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  top: 5,
                                                  bottom: 5,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isCurrentUser
                                                          ? Colors.blue[800]
                                                          : (isDarkMode
                                                              ? const Color(
                                                                0xFF3D3D3D,
                                                              )
                                                              : Colors
                                                                  .grey[300]),
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
                                                          : message
                                                                  .replyToText ??
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
                                                    message.text.isNotEmpty
                                                        ? message.text
                                                        : (isTemporary
                                                            ? 'Sending...'
                                                            : ''),
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
                  // Show encryption indicator in text field
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _isEncryptionInitialized
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Tooltip(
                      message:
                          _isEncryptionInitialized
                              ? 'End-to-End Encrypted'
                              : 'Encryption setup in progress',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isEncryptionInitialized
                                ? Icons.lock
                                : Icons.lock_open,
                            size: 16,
                            color:
                                _isEncryptionInitialized
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isEncryptionInitialized
                                ? 'Encrypted'
                                : 'Unencrypted',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  _isEncryptionInitialized
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText:
                            _isEncryptionInitialized
                                ? 'Type a message...'
                                : 'Setting up encryption...',
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
                                isReplyMode
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
                      onSubmitted:
                          (_) =>
                              _isEncryptionInitialized ? _sendMessage() : null,
                      enabled: _isEncryptionInitialized,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  Material(
                    color: _isEncryptionInitialized ? Colors.blue : Colors.grey,
                    borderRadius: BorderRadius.circular(24),
                    elevation: 2,
                    child: InkWell(
                      onTap: _isEncryptionInitialized ? _sendMessage : null,
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient:
                              _isEncryptionInitialized
                                  ? const LinearGradient(
                                    colors: [Colors.blue, Colors.purple],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : null,
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
