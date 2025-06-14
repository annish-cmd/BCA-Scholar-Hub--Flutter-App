import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import '../models/chat_message.dart';

class ChatService {
  final Logger _logger = Logger();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize Firebase Database URL
  ChatService() {
    _database.databaseURL =
        'https://bcalibraryapp-default-rtdb.asia-southeast1.firebasedatabase.app/';
  }

  // Reference to the global chat collection
  DatabaseReference get _chatRef => _database.ref('global_chat');

  // Send a message to the global chat
  Future<void> sendMessage(String text, {ChatMessage? replyTo}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('Cannot send message: No user logged in');
        throw Exception('You must be logged in to send messages');
      }

      // Create a new message
      final message = ChatMessage(
        id: '', // Will be set by Firebase
        userId: user.uid,
        userName:
            user.displayName ?? user.email?.split('@').first ?? 'Anonymous',
        text: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        userPhotoUrl: user.photoURL,
        replyToId: replyTo?.id,
        replyToUserName: replyTo?.userName,
        replyToText: replyTo?.text,
      );

      // Push the message to Firebase
      await _chatRef.push().set(message.toMap());
      _logger.i('Message sent successfully');
    } catch (e) {
      _logger.e('Error sending message: $e');
      rethrow;
    }
  }

  // Get a stream of messages from the global chat
  Stream<List<ChatMessage>> getMessagesStream() {
    try {
      // Query messages, ordered by timestamp, limited to last 100
      final query = _chatRef.orderByChild('timestamp').limitToLast(100);

      // Convert the Firebase events to a stream of ChatMessage lists
      return query.onValue.map((event) {
        final List<ChatMessage> messages = [];
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          data.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              messages.add(ChatMessage.fromMap(key, value));
            }
          });

          // Sort messages by timestamp (newest last)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }

        return messages;
      });
    } catch (e) {
      _logger.e('Error getting messages stream: $e');
      rethrow;
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
    } catch (e) {
      _logger.e('Error deleting message: $e');
      rethrow;
    }
  }

  // Check if current user can delete a message
  bool canDeleteMessage(ChatMessage message) {
    final user = _auth.currentUser;
    if (user == null) return false;
    return message.userId == user.uid;
  }
}
