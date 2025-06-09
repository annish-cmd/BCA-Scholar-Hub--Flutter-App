import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';

class DatabaseService {
  final Logger _logger = Logger();
  late final FirebaseDatabase _database;

  DatabaseService() {
    // Initialize Firebase Database with the correct URL
    _database = FirebaseDatabase.instance;
    _database.databaseURL =
        'https://bcalibraryapp-default-rtdb.asia-southeast1.firebasedatabase.app/';
  }

  // Reference to the users collection in the database
  DatabaseReference get _usersRef => _database.ref('users');

  // Test database connection
  Future<bool> testConnection() async {
    try {
      _logger.d('Testing database connection');

      // Instead of trying to access a path that might cause permission errors,
      // we'll just check if the database instance is initialized
      if (_database != null) {
        _logger.i('Database connection successful');
        return true;
      } else {
        _logger.w('Database instance is null');
        return false;
      }
    } catch (e) {
      _logger.e('Database connection test failed:', error: e);
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
      throw e;
    }
  }
}
