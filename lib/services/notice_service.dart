import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notice.dart';
import 'package:logger/logger.dart';

class NoticeService {
  static final Logger _logger = Logger();
  static final DatabaseReference _noticesRef = FirebaseDatabase.instance.ref('notices');
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add a new notice to Firebase
  static Future<String?> addNotice(Notice notice) async {
    try {
      _logger.d('Adding new notice: ${notice.title}');
      
      final user = _auth.currentUser;
      if (user == null) {
        _logger.e('User not authenticated');
        return null;
      }

      // Create a new notice with generated ID
      final newNoticeRef = _noticesRef.push();
      final noticeId = newNoticeRef.key;
      
      if (noticeId == null) {
        _logger.e('Failed to generate notice ID');
        return null;
      }

      // Create notice with ID
      final noticeWithId = notice.copyWith(id: noticeId);
      
      // Save to Firebase
      await newNoticeRef.set(noticeWithId.toMap());
      
      _logger.i('Notice added successfully with ID: $noticeId');
      return noticeId;
    } catch (e) {
      _logger.e('Error adding notice:', error: e);
      return null;
    }
  }

  /// Get all notices from Firebase
  static Future<List<Notice>> getAllNotices() async {
    try {
      _logger.d('Fetching all notices from Firebase');
      
      final snapshot = await _noticesRef.once();
      final List<Notice> notices = [];

      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
            notices.add(Notice.fromMap(key.toString(), Map<String, dynamic>.from(value)));
          }
        });

        // Sort by creation date (newest first)
        notices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      _logger.i('Fetched ${notices.length} notices');
      return notices;
    } catch (e) {
      _logger.e('Error fetching notices:', error: e);
      return [];
    }
  }

  /// Get notices by author
  static Future<List<Notice>> getNoticesByAuthor(String authorId) async {
    try {
      _logger.d('Fetching notices by author: $authorId');
      
      final snapshot = await _noticesRef.once();
      final List<Notice> notices = [];

      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map && value['authorId'] == authorId) {
            notices.add(Notice.fromMap(key.toString(), Map<String, dynamic>.from(value)));
          }
        });

        // Sort by creation date (newest first)
        notices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      _logger.i('Fetched ${notices.length} notices by author');
      return notices;
    } catch (e) {
      _logger.e('Error fetching notices by author:', error: e);
      return [];
    }
  }

  /// Update an existing notice
  static Future<bool> updateNotice(String noticeId, Notice updatedNotice) async {
    try {
      _logger.d('Updating notice: $noticeId');
      
      final user = _auth.currentUser;
      if (user == null) {
        _logger.e('User not authenticated');
        return false;
      }

      // Add updated timestamp
      final noticeWithTimestamp = updatedNotice.copyWith(
        updatedAt: DateTime.now(),
      );

      await _noticesRef.child(noticeId).update(noticeWithTimestamp.toMap());
      
      _logger.i('Notice updated successfully');
      return true;
    } catch (e) {
      _logger.e('Error updating notice:', error: e);
      return false;
    }
  }

  /// Delete a notice
  static Future<bool> deleteNotice(String noticeId) async {
    try {
      _logger.d('Deleting notice: $noticeId');
      
      final user = _auth.currentUser;
      if (user == null) {
        _logger.e('User not authenticated');
        return false;
      }

      await _noticesRef.child(noticeId).remove();
      
      _logger.i('Notice deleted successfully');
      return true;
    } catch (e) {
      _logger.e('Error deleting notice:', error: e);
      return false;
    }
  }

  /// Get important notices only
  static Future<List<Notice>> getImportantNotices() async {
    try {
      _logger.d('Fetching important notices');
      
      final allNotices = await getAllNotices();
      final importantNotices = allNotices.where((notice) => notice.isImportant).toList();
      
      _logger.i('Fetched ${importantNotices.length} important notices');
      return importantNotices;
    } catch (e) {
      _logger.e('Error fetching important notices:', error: e);
      return [];
    }
  }

  /// Check if user is admin (you can customize this logic)
  static bool isUserAdmin() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // For now, we'll consider users with specific email domains as admin
    // You can modify this logic based on your requirements
    final adminEmails = ['admin@bca.com', 'anish@bca.com'];
    return adminEmails.contains(user.email?.toLowerCase());
  }

  /// Get current user info
  static Map<String, String> getCurrentUserInfo() {
    final user = _auth.currentUser;
    if (user == null) {
      return {'id': '', 'name': 'Anonymous', 'email': ''};
    }
    
    return {
      'id': user.uid,
      'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
      'email': user.email ?? '',
    };
  }
}

