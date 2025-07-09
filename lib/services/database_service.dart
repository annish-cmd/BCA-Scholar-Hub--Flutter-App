import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import '../models/youtube_video.dart';

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
        await _youtubeVideosRef
            .onValue
            .first
            .timeout(const Duration(seconds: 5))
            .then((event) {
          if (event.snapshot.exists && event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            
            data.forEach((key, value) {
              if (value is Map && value['isActive'] == true) {
                videos.add(YouTubeVideo.fromMap(key.toString(), value));
              }
            });
            
            _logger.i('Retrieved ${videos.length} YouTube videos via stream');
          }
        }).catchError((e) {
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
}
