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

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _errorMessage;
  ChatMessage? _replyingToMessage;
  List<ChatMessage> _messages = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Subscribe to the messages stream
    _chatService.getMessagesStream().listen(
      (messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _isInitialized = true;
          });
          // Scroll to bottom when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error.toString();
            _isInitialized = true;
          });
        }
      },
    );
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

  // Send a message
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Clear input immediately for better UX
    final ChatMessage? replyToMessage = _replyingToMessage;
    _messageController.clear();
    setState(() {
      _replyingToMessage = null;
    });

    // Add optimistic message to the local list for immediate display
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final optimisticMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName:
            user.displayName ?? user.email?.split('@').first ?? 'Anonymous',
        text: message,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        userPhotoUrl: user.photoURL,
        replyToId: replyToMessage?.id,
        replyToUserName: replyToMessage?.userName,
        replyToText: replyToMessage?.text,
      );

      setState(() {
        _messages = [..._messages, optimisticMessage];
      });

      // Scroll to bottom to show the new message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    try {
      // Send message in background
      _chatService.sendMessage(message, replyTo: replyToMessage).catchError((
        e,
      ) {
        setState(() {
          _errorMessage = e.toString();
          // Remove the optimistic message on error
          _messages =
              _messages.where((m) => !m.id.startsWith('temp_')).toList();
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        // Remove the optimistic message on error
        _messages = _messages.where((m) => !m.id.startsWith('temp_')).toList();
      });
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
      return DateFormat.jm().format(dateTime); // e.g. "3:30 PM"
    }

    // If the message is from this year, show month and day
    if (dateTime.year == now.year) {
      return DateFormat('MMM d, jm').format(dateTime); // e.g. "Apr 3, 3:30 PM"
    }

    // Otherwise, show full date
    return DateFormat(
      'MMM d, y, jm',
    ).format(dateTime); // e.g. "Apr 3, 2023, 3:30 PM"
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : Colors.blue[50]!;
    final secondaryBackgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : Colors.purple[50]!;
    final cardColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;

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
        child: Column(
          children: [
            // Error message if any
            if (_errorMessage != null)
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
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Chat messages
            Expanded(
              child:
                  !_isInitialized
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                      ? Center(
                        child: Text(
                          'No messages yet. Be the first to chat!',
                          style: TextStyle(color: textColor),
                        ),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isCurrentUser =
                              message.userId == authProvider.currentUser?.uid;
                          final isTemporary = message.id.startsWith('temp_');

                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: isTemporary ? 0.7 : 1.0,
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
                                  margin: const EdgeInsets.only(bottom: 12),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isCurrentUser
                                            ? Colors.blue[700]
                                            : (isDarkMode
                                                ? const Color(0xFF2D2D2D)
                                                : Colors.grey[200]),
                                    borderRadius: BorderRadius.circular(16),
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
                                            child: Text(
                                              message.userName,
                                              style: TextStyle(
                                                color:
                                                    isCurrentUser
                                                        ? Colors.white
                                                        : (isDarkMode
                                                            ? Colors.blue[200]
                                                            : Colors.blue[700]),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              if (isTemporary)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    right: 4,
                                                  ),
                                                  width: 8,
                                                  height: 8,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            isCurrentUser
                                                                ? Colors.white70
                                                                : Colors
                                                                    .blue[300],
                                                      ),
                                                ),
                                              Text(
                                                _formatTimestamp(
                                                  message.timestamp,
                                                ),
                                                style: TextStyle(
                                                  color:
                                                      isCurrentUser
                                                          ? Colors.white70
                                                          : (isDarkMode
                                                              ? Colors.grey[400]
                                                              : Colors
                                                                  .grey[600]),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Reply to ${message.replyToUserName}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color:
                                                      isCurrentUser
                                                          ? Colors.white70
                                                          : (isDarkMode
                                                              ? Colors.grey[400]
                                                              : Colors
                                                                  .grey[600]),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                message.replyToText != null &&
                                                        message
                                                                .replyToText!
                                                                .length >
                                                            50
                                                    ? '${message.replyToText!.substring(0, 50)}...'
                                                    : message.replyToText ?? '',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      isCurrentUser
                                                          ? Colors.white70
                                                          : (isDarkMode
                                                              ? Colors.grey[300]
                                                              : Colors
                                                                  .grey[800]),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      const SizedBox(height: 5),
                                      // Message text
                                      Text(
                                        message.text,
                                        style: TextStyle(
                                          color:
                                              isCurrentUser
                                                  ? Colors.white
                                                  : textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),

            // Reply indicator
            if (_replyingToMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[200],
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to ${_replyingToMessage!.userName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _replyingToMessage!.text.isNotEmpty &&
                                    _replyingToMessage!.text.length > 50
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
                    child: InkWell(
                      onTap: _sendMessage,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.send, color: Colors.white),
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
