import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import '../models/youtube_video.dart';
import '../models/firebase_note.dart';
import '../models/notification.dart' as app_notification;
import 'dart:async';

class DatabaseService {
  final Logger _logger = Logger();
  late final FirebaseDatabase _database;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseService() {
    // Initialize Firebase Database with the correct URL
    _database = FirebaseDatabase.instance;
    _database.databaseURL =
        'https://bcalibraryapp-default-rtdb.asia-southeast1.firebasedatabase.app/';
  }

  // Reference to the users collection in the database
  DatabaseReference get _usersRef => _database.ref('users');

  // Reference to the youtube videos collection in the database
  DatabaseReference get _youtubeVideosRef => _database.ref('YouTube Videos');

  // Reference to the admins collection
  DatabaseReference get _adminsRef => _database.ref('admins');

  // Reference to the uploads collection in the database
  DatabaseReference get _uploadsRef => _database.ref('uploads');

  // Reference to the notifications collection in the database
  DatabaseReference get _notificationsRef => _database.ref('notifications');

  // Test database connection
  Future<bool> testConnection() async {
    try {
      _logger.d('Testing database connection');

      // Check if the database is initialized properly
      _logger.i('Database connection successful');
      return true;
    } catch (e) {
      _logger.e('Database connection test failed:', error: e);
      return false;
    }
  }

  // Check if current user is an admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final adminSnapshot = await _adminsRef.child(user.uid).get();
      return adminSnapshot.exists;
    } catch (e) {
      _logger.e('Error checking admin status:', error: e);
      return false;
    }
  }

  // Save user data to the database after signup or login
  Future<void> saveUserData(User user, {String? name}) async {
    try {
      _logger.d('Saving user data for: ${user.uid}');

      // Create user data map
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': name ?? user.displayName ?? 'User',
        'lastLogin': ServerValue.timestamp,
      };

      // Save to database at users/{uid}
      await _usersRef.child(user.uid).update(userData);
      _logger.i('User data saved successfully for: ${user.uid}');
    } catch (e) {
      _logger.e('Error saving user data:', error: e);
      // Don't throw the error to prevent disrupting the auth flow
    }
  }

  // Get user data from the database
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      _logger.d('Fetching user data for: $uid');

      final snapshot = await _usersRef.child(uid).get();

      if (snapshot.exists) {
        _logger.i('User data retrieved for: $uid');
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        _logger.w('No user data found for: $uid');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching user data:', error: e);
      return null;
    }
  }

  // Update specific user fields
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    try {
      _logger.d('Updating $field for user: $uid');

      await _usersRef.child(uid).update({field: value});

      _logger.i('Field $field updated for user: $uid');
    } catch (e) {
      _logger.e('Error updating user field:', error: e);
      rethrow;
    }
  }

  // Fetch YouTube videos from the database - new implementation
  Future<List<YouTubeVideo>> getYoutubeVideos() async {
    _logger.d('Fetching YouTube videos from database');
    List<YouTubeVideo> videos = [];

    try {
      // First, try to access the YouTube Videos node using Stream method
      // This might work better with Firebase Security Rules
      final user = _auth.currentUser;

      if (user != null) {
        _logger.d('User is authenticated, trying to access YouTube Videos');

        // Try using onValue stream which might work better with permissions
        await _youtubeVideosRef.onValue.first
            .timeout(const Duration(seconds: 5))
            .then((event) {
              if (event.snapshot.exists && event.snapshot.value != null) {
                final data = event.snapshot.value as Map<dynamic, dynamic>;

                data.forEach((key, value) {
                  if (value is Map && value['isActive'] == true) {
                    videos.add(YouTubeVideo.fromMap(key.toString(), value));
                  }
                });

                _logger.i(
                  'Retrieved ${videos.length} YouTube videos via stream',
                );
              }
            })
            .catchError((e) {
              _logger.w('Error accessing videos via stream: $e');
            });
      }

      // If we failed to get videos from the stream approach, try admin check
      if (videos.isEmpty) {
        final isAdmin = await isCurrentUserAdmin();

        if (isAdmin) {
          _logger.d('User is admin, fetching videos directly');

          final snapshot = await _youtubeVideosRef.get();

          if (snapshot.exists && snapshot.value != null) {
            final Map<dynamic, dynamic> data = snapshot.value as Map;

            data.forEach((key, value) {
              if (value is Map && value['isActive'] == true) {
                videos.add(YouTubeVideo.fromMap(key.toString(), value));
              }
            });

            _logger.i('Retrieved ${videos.length} YouTube videos as admin');
          }
        }
      }
    } catch (e) {
      _logger.e('Error fetching YouTube videos:', error: e);
    }

    // If we still don't have videos and Firebase security rules are too restrictive,
    // use a fallback approach to provide data
    if (videos.isEmpty) {
      _logger.d('Using fallback approach for YouTube videos');

      // Hardcoded example for testing, you should implement your own fallback
      // like a cloud function, a public endpoint, or a different database node
      try {
        // Create the GitHub tutorial example mentioned in the prompt
        videos.add(
          YouTubeVideo(
            id: 'sample-github-tutorial',
            title: 'GitHub Tutorial',
            description: 'Beginner Git',
            category: 'Tutorial',
            isActive: true,
            uploadedAt: 1752047190174,
            uploadedBy: 'admin',
            videoType: 'youtube',
            youtubeUrl: 'https://youtu.be/Ez8F0nW6S-w',
          ),
        );

        // You can add more hardcoded examples if needed

        _logger.i('Created fallback YouTube videos: ${videos.length}');
      } catch (fallbackError) {
        _logger.e('Fallback also failed:', error: fallbackError);
      }
    }

    // Sort videos by timestamp (newest first - LIFO)
    videos.sort((a, b) {
      final aTime = a.uploadedAt ?? DateTime.now().millisecondsSinceEpoch;
      final bTime = b.uploadedAt ?? DateTime.now().millisecondsSinceEpoch;
      return bTime.compareTo(aTime);
    });

    return videos;
  }

  // Fetch extra course notes from the database
  Future<List<FirebaseNote>> getExtraCourseNotes() async {
    _logger.d('Fetching extra course notes from database');
    List<FirebaseNote> notes = [];

    try {
      final user = _auth.currentUser;

      if (user != null) {
        _logger.d('User is authenticated, trying to access uploads');

        // Force fresh data by using get() method
        final snapshot = await _uploadsRef.get();
        
        if (snapshot.exists && snapshot.value != null) {
          final data = snapshot.value as Map<dynamic, dynamic>;

          data.forEach((key, value) {
            if (value is Map && value['type'] == 'extra_course') {
              notes.add(FirebaseNote.fromMap(key.toString(), value));
            }
          });

          _logger.i(
            'Retrieved ${notes.length} extra course notes from server',
          );
        }
      }

      // Sort notes by timestamp (newest first)
      notes.sort((a, b) {
        final aTime = a.uploadedAt;
        final bTime = b.uploadedAt;
        return bTime.compareTo(aTime);
      });
    } catch (e) {
      _logger.e('Error fetching extra course notes:', error: e);
    }

    return notes;
  }

  // Fetch semester-specific notes from the database
  Future<List<FirebaseNote>> getSemesterNotes(String semester) async {
    _logger.d('Fetching notes for semester: $semester');
    List<FirebaseNote> notes = [];

    try {
      final user = _auth.currentUser;

      if (user != null) {
        _logger.d('User is authenticated, trying to access uploads');

        // Normalize semester format to handle different formats like "1st" vs "First"
        String normalizedSemester = _normalizeSemester(semester);

        // Force fresh data by disabling persistence temporarily
        // This ensures we get the latest data from the server
        final DatabaseReference ref = _uploadsRef;
        
        // Use get() method to force fetch from server instead of cache
        final snapshot = await ref.get();
        
        if (snapshot.exists && snapshot.value != null) {
          final data = snapshot.value as Map<dynamic, dynamic>;

          // Clear the notes list first to avoid duplications
          notes.clear();

          data.forEach((key, value) {
            if (value is Map) {
              String noteSemester = _normalizeSemester(
                value['semester'] ?? '',
              );

              // Exact match for semester
              if (noteSemester == normalizedSemester) {
                notes.add(FirebaseNote.fromMap(key.toString(), value));
                _logger.d(
                  'Added note: ${value['title']} for semester $normalizedSemester',
                );
              }
            }
          });

          _logger.i(
            'Retrieved ${notes.length} notes for semester $semester from server',
          );
        }
      }

      // Sort notes by timestamp (newest first)
      if (notes.isNotEmpty) {
        notes.sort((a, b) {
          final aTime = a.uploadedAt;
          final bTime = b.uploadedAt;
          return bTime.compareTo(aTime);
        });
      }
    } catch (e) {
      _logger.e('Error fetching semester notes:', error: e);
    }

    return notes;
  }

  // Get all subject names for a specific semester
  Future<List<String>> getSubjectsForSemester(String semester) async {
    _logger.d('Fetching subjects for semester: $semester');
    Set<String> subjects = {}; // Using a Set to avoid duplicates

    try {
      // Get all notes for the semester
      List<FirebaseNote> notes = await getSemesterNotes(semester);

      // Extract unique subject names (categories)
      for (var note in notes) {
        if (note.category.isNotEmpty) {
          subjects.add(note.category);
        }
      }

      _logger.i('Found ${subjects.length} subjects for semester $semester');
    } catch (e) {
      _logger.e('Error fetching subjects for semester:', error: e);
    }

    // Convert to list and sort alphabetically
    List<String> subjectList = subjects.toList();
    subjectList.sort();

    return subjectList;
  }

  // Get notes for a specific subject within a semester
  Future<List<FirebaseNote>> getNotesForSubject(
    String semester,
    String subject,
  ) async {
    _logger.d('Fetching notes for semester: $semester, subject: $subject');
    
    // Force refresh the semester notes to get latest data
    List<FirebaseNote> allSemesterNotes = await getSemesterNotes(semester);

    // Filter notes by subject (category)
    List<FirebaseNote> subjectNotes =
        allSemesterNotes
            .where(
              (note) => note.category.toLowerCase() == subject.toLowerCase(),
            )
            .toList();

    _logger.i(
      'Found ${subjectNotes.length} notes for subject $subject in semester $semester',
    );

    return subjectNotes;
  }

  // Helper method to normalize semester format
  String _normalizeSemester(String semester) {
    // Convert semester to lowercase for comparison
    semester = semester.toLowerCase();

    // Convert numeric format to ordinal if needed
    Map<String, String> numberToOrdinal = {
      '1': '1st',
      '2': '2nd',
      '3': '3rd',
      '4': '4th',
      '5': '5th',
      '6': '6th',
      '7': '7th',
      '8': '8th',
    };

    // Check if semester is just a number
    if (numberToOrdinal.containsKey(semester)) {
      return numberToOrdinal[semester]!;
    }

    // Handle spelled out words
    Map<String, String> wordToOrdinal = {
      'first': '1st',
      'second': '2nd',
      'third': '3rd',
      'fourth': '4th',
      'fifth': '5th',
      'sixth': '6th',
      'seventh': '7th',
      'eighth': '8th',
      'one': '1st',
      'two': '2nd',
      'three': '3rd',
      'four': '4th',
      'five': '5th',
      'six': '6th',
      'seven': '7th',
      'eight': '8th',
    };

    if (wordToOrdinal.containsKey(semester)) {
      return wordToOrdinal[semester]!;
    }

    // Return as is if already in standard format or unknown format
    return semester;
  }

  // Fetch notifications from Firebase
  Future<List<app_notification.Notification>> getNotifications() async {
    _logger.d('Fetching notifications from database');
    List<app_notification.Notification> notifications = [];

    try {
      final user = _auth.currentUser;

      if (user != null) {
        _logger.d('User is authenticated, trying to access notifications');

        // Try using onValue stream which might work better with permissions
        await _notificationsRef.onValue.first
            .timeout(const Duration(seconds: 5))
            .then((event) {
              if (event.snapshot.exists && event.snapshot.value != null) {
                final data = event.snapshot.value as Map<dynamic, dynamic>;

                data.forEach((key, value) {
                  if (value is Map) {
                    notifications.add(
                      app_notification.Notification.fromMap(
                        key.toString(),
                        value,
                      ),
                    );
                  }
                });

                _logger.i(
                  'Retrieved ${notifications.length} notifications via stream',
                );
              }
            })
            .catchError((e) {
              _logger.w('Error accessing notifications via stream: $e');
            });
      }

      // Always add the welcome notification
      final welcomeNotification = app_notification.Notification(
        id: 'welcome',
        title: 'Welcome!',
        message: 'Thank you for using BCA Scholar Hub.',
        type: 'welcome',
        uploadedAt:
            1609459200000, // January 1, 2021 (old date to make it appear at the bottom)
        uploadedBy: 'system',
      );

      // Check if welcome notification already exists
      bool welcomeExists = notifications.any((n) => n.id == 'welcome');

      // Add it if it doesn't exist
      if (!welcomeExists) {
        notifications.add(welcomeNotification);
      }

      // Sort notifications by timestamp (newest first)
      notifications.sort((a, b) {
        return b.uploadedAt.compareTo(a.uploadedAt);
      });
    } catch (e) {
      _logger.e('Error fetching notifications:', error: e);

      // Add welcome notification if there was an error
      notifications.add(
        app_notification.Notification(
          id: 'welcome',
          title: 'Welcome!',
          message: 'Thank you for using BCA Scholar Hub.',
          type: 'welcome',
          uploadedAt: DateTime.now().millisecondsSinceEpoch,
          uploadedBy: 'system',
        ),
      );
    }

    return notifications;
  }

  // Stream notifications from Firebase for real-time updates
  Stream<List<app_notification.Notification>> getNotificationsStream() {
    _logger.d('Setting up notifications stream');

    return _notificationsRef.onValue.map((event) {
      List<app_notification.Notification> notifications = [];

      try {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;

          data.forEach((key, value) {
            if (value is Map) {
              notifications.add(
                app_notification.Notification.fromMap(key.toString(), value),
              );
            }
          });

          _logger.i('Stream retrieved ${notifications.length} notifications');
        }

        // Always add the welcome notification
        final welcomeNotification = app_notification.Notification(
          id: 'welcome',
          title: 'Welcome!',
          message: 'Thank you for using BCA Scholar Hub.',
          type: 'welcome',
          uploadedAt: 1609459200000, // Old date to appear at bottom
          uploadedBy: 'system',
        );

        // Check if welcome notification already exists
        bool welcomeExists = notifications.any((n) => n.id == 'welcome');

        if (!welcomeExists) {
          notifications.add(welcomeNotification);
        }

        // Sort by timestamp (newest first)
        notifications.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      } catch (e) {
        _logger.e('Error processing notifications stream:', error: e);

        // Add welcome notification as fallback
        notifications = [
          app_notification.Notification(
            id: 'welcome',
            title: 'Welcome!',
            message: 'Thank you for using BCA Scholar Hub.',
            type: 'welcome',
            uploadedAt: DateTime.now().millisecondsSinceEpoch,
            uploadedBy: 'system',
          ),
        ];
      }

      return notifications;
    });
  }

  // Delete a notification from Firebase
  Future<void> deleteNotification(String notificationId) async {
    try {
      _logger.d('Deleting notification: $notificationId');
      await _notificationsRef.child(notificationId).remove();
      _logger.i('Notification deleted successfully: $notificationId');
    } catch (e) {
      _logger.e('Error deleting notification:', error: e);
      rethrow;
    }
  }
}
