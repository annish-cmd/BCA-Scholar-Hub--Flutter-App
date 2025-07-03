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
  bool _isEncryptionInitialized = false;
  List<ChatMessage> _cachedMessages = [];
  bool _isLoadingMessages = false;
  bool _isAdmin = false;

  // Initialize Firebase Database URL and eagerly load messages
  ChatService() {
    _database.databaseURL =
        'https://bcalibraryapp-default-rtdb.asia-southeast1.firebasedatabase.app/';
    _checkEncryptionStatus();
    _checkAdminStatus();

    // Start eagerly loading messages
    _eagerlyLoadMessages();

    // Set up auth state listener to reload messages when user logs in
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        // User logged in, refresh messages
        _eagerlyLoadMessages();
        _checkAdminStatus();
      }
    });
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

  // Check if encryption is initialized
  Future<void> _checkEncryptionStatus() async {
    try {
      await _encryptionService.initializeUserKeys();
      _isEncryptionInitialized = true;
      notifyListeners();
    } catch (e) {
      _logger.e('Error initializing encryption: $e');
      _isEncryptionInitialized = false;
      notifyListeners();
    }
  }

  // Public method to force check encryption status
  Future<void> checkAndInitializeEncryption() async {
    return _checkEncryptionStatus();
  }

  // Get encryption status
  bool get isEncryptionInitialized => _isEncryptionInitialized;

  // Reference to the global chat collection
  DatabaseReference get _chatRef => _database.ref('global_chat');

  // Eagerly load messages to ensure they're available when needed
  Future<void> _eagerlyLoadMessages() async {
    if (_isLoadingMessages) return;

    _isLoadingMessages = true;
    try {
      final snapshot =
          await _chatRef.orderByChild('timestamp').limitToLast(100).get();

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
        _decryptCachedMessages();

        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error eagerly loading messages: $e');
    } finally {
      _isLoadingMessages = false;
    }
  }

  // Decrypt cached messages in the background
  Future<void> _decryptCachedMessages() async {
    if (!_isEncryptionInitialized) {
      await _checkEncryptionStatus();
    }

    if (!_isEncryptionInitialized || _cachedMessages.isEmpty) return;

    for (int i = 0; i < _cachedMessages.length; i++) {
      final message = _cachedMessages[i];
      if (message.isEncrypted) {
        try {
          final decryptedText = await decryptMessage(message);
          if (decryptedText != null && decryptedText.isNotEmpty) {
            _cachedMessages[i] = ChatMessage(
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
            );
          }
        } catch (e) {
          _logger.w('Error decrypting cached message: $e');
        }
      }
    }

    notifyListeners();
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

      if (replyToId != null) {
        messageData['replyToId'] = replyToId;
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

      // Send message to Firebase
      await messageRef.set(messageData);
      _logger.i('Message sent successfully');
      notifyListeners();
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

  // Get a stream of messages from the global chat
  Stream<List<ChatMessage>> getMessagesStream() {
    return _chatRef.orderByChild('timestamp').limitToLast(100).onValue.map((
      event,
    ) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final messagesMap = data as Map<dynamic, dynamic>;
      final List<ChatMessage> messages = [];

      messagesMap.forEach((key, value) {
        try {
          final message = ChatMessage.fromMap(key.toString(), value);

          // Always add the message first to have it displayed immediately
          messages.add(message);

          // Try to decrypt the message if it's encrypted
          if (message.isEncrypted && _isEncryptionInitialized) {
            // Handle decryption for the current user
            decryptMessage(message)
                .then((decryptedText) {
                  if (decryptedText != null) {
                    // Find the message in the list and replace with decrypted version
                    final index = messages.indexWhere(
                      (m) => m.id == message.id,
                    );
                    if (index >= 0) {
                      messages[index] = ChatMessage(
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
                      );
                      notifyListeners();
                    }
                  }
                })
                .catchError((error) {
                  // Silently handle decryption errors without showing in UI
                  _logger.w(
                    'Decryption error for message ${message.id}: $error',
                  );
                });
          }
        } catch (e) {
          _logger.e('Error parsing message: $e');
          // Don't propagate parsing errors to the UI
        }
      });

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
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

      final decryptedText = await _encryptionService.decryptGlobalChatMessage(
        message.cipherText!,
        message.iv!,
        encryptedKeys,
      );

      if (decryptedText != null && decryptedText.isNotEmpty) {
        notifyListeners();
        return decryptedText;
      } else {
        return "";
      }
    } catch (e) {
      _logger.e('Error decrypting message: $e');
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
      // First try to get the most recent messages from Firebase
      final snapshot =
          await _chatRef.orderByChild('timestamp').limitToLast(50).get();

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
        _decryptCachedMessages();

        return messages;
      }
    } catch (e) {
      _logger.e('Error getting cached messages: $e');
    }

    // Return empty list if no cached messages or error
    return [];
  }

  // Check if current user can delete a message
  bool canDeleteMessage(ChatMessage message) {
    final user = _auth.currentUser;
    if (user == null) return false;
    return message.userId == user.uid;
  }
}
