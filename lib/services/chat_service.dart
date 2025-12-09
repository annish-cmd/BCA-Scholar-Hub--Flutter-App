import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../utils/encryption/encryption_service.dart';

class ChatService extends ChangeNotifier {
  final Logger _logger = Logger();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionService _encryptionService = EncryptionService();
  List<ChatMessage> _cachedMessages = [];
  bool _isLoadingMessages = false;
  bool _isAdmin = false;
  bool _isEncryptionInitialized = false;

  // Smart cache with timestamp tracking for automatic cleanup
  final Map<String, ChatMessage> _decryptedMessageCache = {};
  final Map<String, String> _decryptionTextCache = {};
  final Map<String, int> _cacheTimestamps = {}; // Track when messages were cached
  
  // Performance tracking
  DateTime? _lastNotifyTime;
  bool _hasNotificationScheduled = false;
  
  // Batch decryption for faster processing
  bool _isBatchDecrypting = false;
  final List<ChatMessage> _decryptionQueue = [];

  // Stream controller for reactive message updates
  StreamController<List<ChatMessage>>? _messagesStreamController;
  StreamSubscription? _firebaseStreamSubscription;

  // Initialize Firebase Database URL and eagerly load messages
  ChatService() {
    _database.databaseURL =
        'https://bcalibraryapp-default-rtdb.asia-southeast1.firebasedatabase.app/';

    // Optimize Firebase for real-time performance
    _database.setPersistenceEnabled(true);
    _database.setPersistenceCacheSizeBytes(10000000); // 10MB cache

    // Initialize encryption immediately and aggressively
    _initializeEverythingImmediately();

    // Set up auth state listener to reload messages when user logs in
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        // User logged in, refresh everything
        _initializeEverythingImmediately();
      }
    });
  }

  // Initialize everything for fastest startup
  void _initializeEverythingImmediately() async {
    // Load messages first for instant display
    _eagerlyLoadMessages();

    // Check admin status in background (don't wait)
    _checkAdminStatus();

    // Initialize encryption in background (don't wait)
    _checkEncryptionStatus();

    // Clean up old cache entries
    _cleanupStaleCache();
  }

  // Check if current user is an admin
  Future<void> _checkAdminStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _isAdmin = false;
        notifyListeners();
        return;
      }

      final adminRef = _database.ref('admins').child(user.uid);
      final snapshot = await adminRef.get();

      _isAdmin = snapshot.exists;
      _logger.i('Admin status for ${user.email}: $_isAdmin');
      notifyListeners();
    } catch (e) {
      _logger.e('Error checking admin status: $e');
      _isAdmin = false;
      notifyListeners();
    }
  }

  // Get admin status
  bool get isAdmin => _isAdmin;

  // Check if encryption is initialized - ultra-fast
  Future<void> _checkEncryptionStatus() async {
    try {
      await _encryptionService.initializeUserKeys();
      _isEncryptionInitialized = true;
      _logger.i('Encryption initialized');
      
      // Decrypt cached messages in background (non-blocking)
      _batchDecryptMessages();
    } catch (e) {
      _logger.e('Encryption init error: $e');
      _isEncryptionInitialized = false;
    }
  }

  // Batch decrypt messages for faster processing
  Future<void> _batchDecryptMessages() async {
    if (_isBatchDecrypting || !_isEncryptionInitialized) return;
    
    _isBatchDecrypting = true;
    try {
      // Get all encrypted messages that need decryption
      final toDecrypt = _cachedMessages
          .where((m) => m.isEncrypted && !_decryptedMessageCache.containsKey(m.id))
          .take(10) // Process in batches of 10 for speed
          .toList();

      // Decrypt in parallel for maximum speed
      await Future.wait(
        toDecrypt.map((msg) => _fastDecryptMessage(msg)),
        eagerError: false,
      );
    } finally {
      _isBatchDecrypting = false;
    }
  }

  // Public method to force check encryption status and decrypt messages
  Future<void> checkAndInitializeEncryption() async {
    if (_isEncryptionInitialized) return; // Skip if already initialized
    await _checkEncryptionStatus();
  }

  // Get encryption status
  bool get isEncryptionInitialized => _isEncryptionInitialized;

  // Reference to the global chat collection
  DatabaseReference get _chatRef => _database.ref('global_chat');

  // Helper method to get 12-hour cutoff timestamp for faster loading
  int get _get12HourCutoffTimestamp {
    final now = DateTime.now().millisecondsSinceEpoch;
    const twelveHours = 12 * 60 * 60 * 1000; // 12 hours in milliseconds
    return now - twelveHours;
  }

  // Eagerly load messages to ensure they're available when needed
  Future<void> _eagerlyLoadMessages() async {
    if (_isLoadingMessages) return;

    _isLoadingMessages = true;
    try {
      final snapshot = await _chatRef
          .orderByChild('timestamp')
          .startAt(_get12HourCutoffTimestamp)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<ChatMessage> messages = [];

        data.forEach((key, value) {
          try {
            final message = ChatMessage.fromMap(key.toString(), value);
            messages.add(message);
          } catch (e) {
            _logger.e('Error parsing eager message: $e');
          }
        });

        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _cachedMessages = messages;

        // Start decrypting messages in the background
        _batchDecryptMessages();

        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error eagerly loading messages: $e');
    } finally {
      _isLoadingMessages = false;
    }
  }

  // Fast decrypt single message (non-blocking)
  Future<void> _fastDecryptMessage(ChatMessage message) async {
    if (!_isEncryptionInitialized) return;
    
    final messageId = message.id;
    
    // Skip if already cached or failed
    if (_decryptedMessageCache.containsKey(messageId) ||
        (_decryptionTextCache.containsKey(messageId) && _decryptionTextCache[messageId]!.isEmpty)) {
      return;
    }

    try {
      final decryptedText = await decryptMessage(message);
      if (decryptedText != null && decryptedText.isNotEmpty) {
        final decryptedMessage = ChatMessage(
          id: message.id,
          userId: message.userId,
          userName: message.userName,
          text: decryptedText,
          timestamp: message.timestamp,
          userPhotoUrl: message.userPhotoUrl,
          replyToId: message.replyToId,
          replyToUserName: message.replyToUserName,
          replyToText: message.replyToText,
          isEncrypted: message.isEncrypted,
          cipherText: message.cipherText,
          iv: message.iv,
          encryptedKeys: message.encryptedKeys,
          isAdmin: message.isAdmin,
        );

        _decryptedMessageCache[messageId] = decryptedMessage;
        _decryptionTextCache[messageId] = decryptedText;
        _cacheTimestamps[messageId] = DateTime.now().millisecondsSinceEpoch;
      } else {
        _decryptionTextCache[messageId] = '';
      }
    } catch (e) {
      _decryptionTextCache[messageId] = '';
    }
  }

  // Send a message to the global chat
  Future<bool> sendMessage(String messageText, {String? replyToId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.e('User not logged in');
        return false;
      }

      final messageRef = _chatRef.push();
      final messageId = messageRef.key!;

      Map<String, dynamic> messageData = {
        'userId': user.uid,
        'userName':
            user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous',
        'userPhotoUrl': user.photoURL,
        'timestamp': ServerValue.timestamp,
        'isEncrypted': false,
        'text': messageText,
      };

      // Add admin flag if user is admin
      if (_isAdmin) {
        messageData['isAdmin'] = true;
      }

      // Handle reply information
      if (replyToId != null) {
        messageData['replyToId'] = replyToId;

        // Find the original message to get reply information
        try {
          final originalMessageSnapshot = await _chatRef.child(replyToId).get();
          if (originalMessageSnapshot.exists) {
            final originalData =
                originalMessageSnapshot.value as Map<dynamic, dynamic>;
            messageData['replyToUserName'] =
                originalData['userName'] ?? 'Unknown';

            // Get the original message text (decrypt if needed)
            String originalText = originalData['text'] ?? '';
            if (originalData['isEncrypted'] == true && originalText.isEmpty) {
              // Try to decrypt for reply display
              try {
                final originalMessage = ChatMessage.fromMap(
                  replyToId,
                  originalData,
                );
                final decryptedText = await decryptMessage(originalMessage);
                originalText = decryptedText ?? 'Encrypted message';
              } catch (e) {
                originalText = 'Encrypted message';
              }
            }
            messageData['replyToText'] = originalText;

            _logger.i(
              'Reply information added: ${messageData['replyToUserName']}, text: ${originalText.length > 50 ? '${originalText.substring(0, 50)}...' : originalText}',
            );
          }
        } catch (e) {
          _logger.w('Failed to get original message for reply: $e');
          // Continue without reply information
        }
      }

      // Try to encrypt the message if encryption is initialized
      if (_isEncryptionInitialized) {
        try {
          // Make sure encryption is properly initialized
          await _encryptionService.initializeUserKeys();

          final encryptedData = await _encryptionService
              .encryptGlobalChatMessage(messageText);

          messageData['isEncrypted'] = true;
          messageData['text'] = '';
          messageData['cipherText'] = encryptedData['cipherText'];
          messageData['iv'] = encryptedData['iv'];
          messageData['encryptedKeys'] = encryptedData['encryptedKeys'];

          _logger.i('Message encrypted successfully');
        } catch (e) {
          _logger.w('Failed to encrypt message, sending as plaintext: $e');
          messageData['isEncrypted'] = false;
          messageData['text'] = messageText;
        }
      } else {
        _logger.w('Encryption not initialized, sending plaintext message');
        // Try to initialize encryption for next time
        _checkEncryptionStatus();
      }

      // Send message to Firebase with immediate response
      await messageRef.set(messageData);
      _logger.i('Message sent successfully');
      _immediateNotify(); // Immediate notification for message sending
      return true;
    } catch (e) {
      _logger.e('Error sending message: $e');
      // Check if error is permission denied and encryption is related
      if (e.toString().contains('permission-denied') &&
          _isEncryptionInitialized) {
        // Try again without encryption
        _logger.w('Retrying without encryption');
        _isEncryptionInitialized = false;
        notifyListeners();
        return sendMessage(messageText, replyToId: replyToId);
      }
      return false;
    }
  }

  // Professional real-time message stream with millisecond performance
  Stream<List<ChatMessage>> getMessagesStream() {
    _messagesStreamController ??= StreamController<List<ChatMessage>>.broadcast();
    _firebaseStreamSubscription?.cancel();

    _firebaseStreamSubscription = _chatRef
        .orderByChild('timestamp')
        .startAt(_get12HourCutoffTimestamp)
        .onValue
        .listen((event) {
          final data = event.snapshot.value;
          
          if (data == null) {
            _decryptedMessageCache.clear();
            _decryptionTextCache.clear();
            _cacheTimestamps.clear();
            if (!_messagesStreamController!.isClosed) {
              _messagesStreamController!.add([]);
            }
            return;
          }

          final messagesMap = data as Map<dynamic, dynamic>;
          final List<ChatMessage> messages = [];
          final Set<String> currentMessageIds = {};
          final List<ChatMessage> needsDecryption = [];

          messagesMap.forEach((key, value) {
            try {
              final message = ChatMessage.fromMap(key.toString(), value);
              final messageId = message.id;
              currentMessageIds.add(messageId);

              // Use cached version if available
              if (_decryptedMessageCache.containsKey(messageId)) {
                messages.add(_decryptedMessageCache[messageId]!);
                return;
              }

              // Use cached decrypted text
              if (message.isEncrypted && _decryptionTextCache.containsKey(messageId)) {
                final cachedText = _decryptionTextCache[messageId]!;
                if (cachedText.isNotEmpty) {
                  final decryptedMsg = ChatMessage(
                    id: message.id,
                    userId: message.userId,
                    userName: message.userName,
                    text: cachedText,
                    timestamp: message.timestamp,
                    userPhotoUrl: message.userPhotoUrl,
                    replyToId: message.replyToId,
                    replyToUserName: message.replyToUserName,
                    replyToText: message.replyToText,
                    isEncrypted: message.isEncrypted,
                    cipherText: message.cipherText,
                    iv: message.iv,
                    encryptedKeys: message.encryptedKeys,
                    isAdmin: message.isAdmin,
                  );
                  _decryptedMessageCache[messageId] = decryptedMsg;
                  messages.add(decryptedMsg);
                  return;
                }
              }

              // Add message and queue for decryption
              messages.add(message);
              if (message.isEncrypted && !_decryptionTextCache.containsKey(messageId)) {
                needsDecryption.add(message);
              } else if (!message.isEncrypted) {
                _decryptedMessageCache[messageId] = message;
                _cacheTimestamps[messageId] = DateTime.now().millisecondsSinceEpoch;
              }
            } catch (e) {
              _logger.e('Parse error: $e');
            }
          });

          // Smart cache cleanup
          _cleanupDeletedMessagesFromCache(currentMessageIds);
          _cleanupStaleCache();

          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // Emit immediately
          if (!_messagesStreamController!.isClosed) {
            _messagesStreamController!.add(messages);
          }

          // Decrypt new messages in background
          if (needsDecryption.isNotEmpty && _isEncryptionInitialized) {
            _batchDecryptNewMessages(needsDecryption);
          }
        });

    return _messagesStreamController!.stream;
  }

  // Batch decrypt new messages for speed
  Future<void> _batchDecryptNewMessages(List<ChatMessage> messages) async {
    await Future.wait(
      messages.map((msg) => _forceDecryptMessageFast(msg)),
      eagerError: false,
    );
  }

  // Clean up cache for deleted messages
  void _cleanupDeletedMessagesFromCache(Set<String> currentMessageIds) {
    _decryptedMessageCache.removeWhere((key, value) => !currentMessageIds.contains(key));
    _decryptionTextCache.removeWhere((key, value) => !currentMessageIds.contains(key));
    _cacheTimestamps.removeWhere((key, value) => !currentMessageIds.contains(key));
  }

  // Clean up stale cache entries (older than 1 hour)
  void _cleanupStaleCache() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneHour = 60 * 60 * 1000;
    
    final staleKeys = _cacheTimestamps.entries
        .where((entry) => (now - entry.value) > oneHour)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in staleKeys) {
      _decryptedMessageCache.remove(key);
      _decryptionTextCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // Force refresh the message stream with latest decrypted content
  void _refreshMessageStream() {
    _chatRef
        .orderByChild('timestamp')
        .startAt(_get12HourCutoffTimestamp)
        .once()
        .then((snapshot) {
          final data = snapshot.snapshot.value;
          if (data == null) return;

          final messagesMap = data as Map<dynamic, dynamic>;
          final List<ChatMessage> messages = [];

          messagesMap.forEach((key, value) {
            try {
              final message = ChatMessage.fromMap(key.toString(), value);
              final messageId = message.id;

              // Use decrypted version if available
              if (_decryptedMessageCache.containsKey(messageId)) {
                messages.add(_decryptedMessageCache[messageId]!);
              } else if (message.isEncrypted &&
                  _decryptionTextCache.containsKey(messageId)) {
                final cachedText = _decryptionTextCache[messageId]!;
                final decryptedMessage = ChatMessage(
                  id: message.id,
                  userId: message.userId,
                  userName: message.userName,
                  text: cachedText,
                  timestamp: message.timestamp,
                  userPhotoUrl: message.userPhotoUrl,
                  replyToId: message.replyToId,
                  replyToUserName: message.replyToUserName,
                  replyToText: message.replyToText,
                  isEncrypted: message.isEncrypted,
                  cipherText: message.cipherText,
                  iv: message.iv,
                  encryptedKeys: message.encryptedKeys,
                  isAdmin: message.isAdmin,
                );
                _decryptedMessageCache[messageId] = decryptedMessage;
                messages.add(decryptedMessage);
              } else {
                messages.add(message);
              }
            } catch (e) {
              _logger.e('Error parsing message in refresh: $e');
            }
          });

          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          if (_messagesStreamController != null &&
              !_messagesStreamController!.isClosed) {
            _messagesStreamController!.add(messages);
          }
        })
        .catchError((error) {
          _logger.e('Error refreshing message stream: $error');
        });
  }

  // Ultra-fast decrypt with immediate stream update
  Future<void> _forceDecryptMessageFast(ChatMessage message) async {
    if (!_isEncryptionInitialized) return;
    
    final messageId = message.id;
    
    // Skip if already processed
    if (_decryptionTextCache.containsKey(messageId)) return;

    try {
      final decryptedText = await decryptMessage(message);
      if (decryptedText != null && decryptedText.isNotEmpty) {
        _decryptionTextCache[messageId] = decryptedText;
        
        final decryptedMsg = ChatMessage(
          id: message.id,
          userId: message.userId,
          userName: message.userName,
          text: decryptedText,
          timestamp: message.timestamp,
          userPhotoUrl: message.userPhotoUrl,
          replyToId: message.replyToId,
          replyToUserName: message.replyToUserName,
          replyToText: message.replyToText,
          isEncrypted: message.isEncrypted,
          cipherText: message.cipherText,
          iv: message.iv,
          encryptedKeys: message.encryptedKeys,
          isAdmin: message.isAdmin,
        );

        _decryptedMessageCache[messageId] = decryptedMsg;
        _cacheTimestamps[messageId] = DateTime.now().millisecondsSinceEpoch;
        
        // Instant stream refresh
        _refreshMessageStream();
      } else {
        _decryptionTextCache[messageId] = '';
      }
    } catch (error) {
      _decryptionTextCache[messageId] = '';
    }
  }



  // Immediate decryption for real-time message updates
  Future<void> _decryptMessageImmediately(ChatMessage message) async {
    try {
      final decryptedText = await decryptMessage(message);
      if (decryptedText != null && decryptedText.isNotEmpty) {
        // Cache both the decrypted text and full message
        _decryptionTextCache[message.id] = decryptedText;

        final decryptedMessage = ChatMessage(
          id: message.id,
          userId: message.userId,
          userName: message.userName,
          text: decryptedText,
          timestamp: message.timestamp,
          userPhotoUrl: message.userPhotoUrl,
          replyToId: message.replyToId,
          replyToUserName: message.replyToUserName,
          replyToText: message.replyToText,
          isEncrypted: message.isEncrypted,
          cipherText: message.cipherText,
          iv: message.iv,
          encryptedKeys: message.encryptedKeys,
          isAdmin: message.isAdmin,
        );

        _decryptedMessageCache[message.id] = decryptedMessage;
        // Force immediate UI update for real-time decryption
        _immediateNotify();
      }
    } catch (error) {
      _logger.w('Decryption error for message ${message.id}: $error');
      // Cache empty text for failed decryptions to avoid retrying
      _decryptionTextCache[message.id] = '';
      // Still notify to prevent UI from hanging
      _immediateNotify();
    }
  }

  // Keep background decryption for compatibility
  Future<void> _decryptMessageBackground(ChatMessage message) async {
    await _decryptMessageImmediately(message);
  }

  // Decrypt a message for the current user
  Future<String?> decryptMessage(ChatMessage message) async {
    if (!message.isEncrypted) return message.text;
    if (message.cipherText == null ||
        message.iv == null ||
        message.encryptedKeys == null) {
      return message.text.isNotEmpty ? message.text : "";
    }

    try {
      // Check if encryption is initialized
      if (!_isEncryptionInitialized) {
        await _checkEncryptionStatus();
        if (!_isEncryptionInitialized) {
          return "";
        }
      }

      // Check if the current user has a key for this message
      final user = _auth.currentUser;
      if (user == null) {
        return "";
      }

      // Make sure to handle null keys safely
      Map<String, String> encryptedKeys;
      try {
        encryptedKeys = Map<String, String>.from(message.encryptedKeys!);
        if (!encryptedKeys.containsKey(user.uid)) {
          return "";
        }
      } catch (e) {
        _logger.e('Invalid encryptedKeys format: $e');
        return "";
      }

      // Check if we've already tried and failed to decrypt this message
      if (_decryptionTextCache.containsKey(message.id) &&
          _decryptionTextCache[message.id]!.isEmpty) {
        // We've already tried and failed, don't retry
        return "";
      }

      final decryptedText = await _encryptionService.decryptGlobalChatMessage(
        message.cipherText!,
        message.iv!,
        encryptedKeys,
      );

      if (decryptedText != null && decryptedText.isNotEmpty) {
        _throttledNotify();
        return decryptedText;
      } else {
        // Cache empty result to prevent repeated failed attempts
        _decryptionTextCache[message.id] = "";
        return "";
      }
    } catch (e) {
      _logger.e('Error decrypting message: $e');
      // Cache empty result to prevent repeated failed attempts
      _decryptionTextCache[message.id] = "";
      // Return original text if available, or an empty string (NOT an error message)
      return message.text.isNotEmpty ? message.text : "";
    }
  }

  // Delete a message (only if the current user is the message author)
  Future<void> deleteMessage(ChatMessage message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('Cannot delete message: No user logged in');
        throw Exception('You must be logged in to delete messages');
      }

      // Check if the current user is the message author
      if (message.userId != user.uid) {
        _logger.w('Cannot delete message: User is not the author');
        throw Exception('You can only delete your own messages');
      }

      // Delete the message
      await _chatRef.child(message.id).remove();
      _logger.i('Message deleted successfully');
      notifyListeners();
    } catch (e) {
      _logger.e('Error deleting message: $e');
      rethrow;
    }
  }

  // Get cached messages for immediate display
  Future<List<ChatMessage>> getCachedMessages() async {
    // If we already have cached messages, return them immediately
    if (_cachedMessages.isNotEmpty) {
      return _cachedMessages;
    }

    // Otherwise try to load them
    try {
      // First try to get the most recent messages from Firebase (12-hour window)
      final snapshot = await _chatRef
          .orderByChild('timestamp')
          .startAt(_get12HourCutoffTimestamp)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<ChatMessage> messages = [];

        data.forEach((key, value) {
          try {
            final message = ChatMessage.fromMap(key.toString(), value);
            messages.add(message);
          } catch (e) {
            _logger.e('Error parsing cached message: $e');
          }
        });

        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _cachedMessages = messages;

        // Start decrypting in the background
        _batchDecryptMessages();

        return messages;
      }
    } catch (e) {
      _logger.e('Error getting cached messages: $e');
    }

    // Return empty list if no cached messages or error
    return [];
  }

  // Force refresh messages while preserving decryption cache
  Future<void> refreshMessages() async {
    try {
      _logger.i('Forcing message refresh - preserving decryption cache');
      // Make a safe copy of the current messages in case reload fails
      final previousMessages = List<ChatMessage>.from(_cachedMessages);

      // Clear only cached messages, NOT decryption caches
      _cachedMessages = [];
      // DO NOT clear decryption caches to prevent re-encryption
      // _decryptedMessageCache.clear(); // Keep this!
      // _decryptionTextCache.clear();   // Keep this!

      // Reload messages with error handling
      try {
        await _eagerlyLoadMessages();
      } catch (loadError) {
        // If loading fails, restore previous messages
        _logger.e('Error loading fresh messages: $loadError');
        _cachedMessages = previousMessages;
      }

      // Force stream refresh to use cached decryptions
      _refreshMessageStream();

      notifyListeners();
    } catch (e) {
      _logger.e('Error refreshing messages: $e');
    }
  }

  // Clear decryption cache (useful for debugging or memory management)
  void clearDecryptionCache() {
    _decryptedMessageCache.clear();
    _decryptionTextCache.clear();
    _logger.i('Decryption cache cleared');
  }

  // Force clear cache and refresh (only for debugging/reset)
  Future<void> forceFullRefresh() async {
    _logger.i('Force full refresh - clearing ALL caches');
    _decryptedMessageCache.clear();
    _decryptionTextCache.clear();
    _cachedMessages = [];
    await _eagerlyLoadMessages();
    await _batchDecryptMessages();
    notifyListeners();
  }

  // Check if current user can delete a message
  bool canDeleteMessage(ChatMessage message) {
    final user = _auth.currentUser;
    if (user == null) return false;
    return message.userId == user.uid;
  }

  // Fast notification for real-time performance
  void _throttledNotify() {
    final now = DateTime.now();
    // Minimal throttling for instant updates
    if (_lastNotifyTime != null &&
        now.difference(_lastNotifyTime!) < const Duration(milliseconds: 50)) {
      if (!_hasNotificationScheduled) {
        _hasNotificationScheduled = true;
        Future.microtask(() {
          if (_hasNotificationScheduled) {
            _lastNotifyTime = DateTime.now();
            _hasNotificationScheduled = false;
            notifyListeners();
          }
        });
      }
      return;
    }

    _lastNotifyTime = now;
    notifyListeners();
  }

  // Immediate notification for critical updates (new messages)
  void _immediateNotify() {
    _lastNotifyTime = DateTime.now();
    notifyListeners();
  }

  // Clean up resources
  @override
  void dispose() {
    _firebaseStreamSubscription?.cancel();
    _messagesStreamController?.close();
    super.dispose();
  }
}
