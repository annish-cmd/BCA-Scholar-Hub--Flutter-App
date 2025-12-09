import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProfileCache {
  static const String _cacheKey = 'user_profile_cache';
  static const String _cacheTimestampKey = 'user_profile_cache_timestamp';
  static const int _cacheExpiryDuration = 5 * 60 * 1000; // 5 minutes in milliseconds

  /// Save user profile data to cache
  static Future<void> saveUserProfile(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(userData);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_cacheTimestampKey, timestamp);
    } catch (e) {
      // Silently fail if cache save fails
      print('Failed to save user profile to cache: $e');
    }
  }

  /// Get cached user profile data
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if cache exists
      if (!prefs.containsKey(_cacheKey) || !prefs.containsKey(_cacheTimestampKey)) {
        return null;
      }
      
      // Check if cache is expired
      final timestamp = prefs.getInt(_cacheTimestampKey)!;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - timestamp > _cacheExpiryDuration) {
        // Cache expired, clear it
        await clearCache();
        return null;
      }
      
      // Get cached data
      final jsonString = prefs.getString(_cacheKey)!;
      final userData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return userData;
    } catch (e) {
      // Silently fail if cache retrieval fails
      print('Failed to get user profile from cache: $e');
      return null;
    }
  }

  /// Clear cached user profile data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {
      // Silently fail if cache clear fails
      print('Failed to clear user profile cache: $e');
    }
  }

  /// Check if cache exists and is valid
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey(_cacheKey) || !prefs.containsKey(_cacheTimestampKey)) {
        return false;
      }
      
      final timestamp = prefs.getInt(_cacheTimestampKey)!;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      return now - timestamp <= _cacheExpiryDuration;
    } catch (e) {
      return false;
    }
  }
}