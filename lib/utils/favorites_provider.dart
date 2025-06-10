import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/pdf_note.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<String> _favoritePdfIds = {};
  bool _isInitialized = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Logger instance
  final _logger = Logger();

  FavoritesProvider() {
    // Initialize Firebase Database URL
    _database.databaseURL =
        'https://bcalibraryapp-default-rtdb.asia-southeast1.firebasedatabase.app/';

    // Listen for auth state changes to load user-specific favorites
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadFavorites();
      } else {
        // Clear favorites when user logs out
        _favoritePdfIds.clear();
        _isInitialized = false;
        notifyListeners();
      }
    });

    // Initial load if user is already logged in
    if (_auth.currentUser != null) {
      _loadFavorites();
    }
  }

  // Get all favorite PDF IDs
  Set<String> get favoritePdfIds => _favoritePdfIds;

  // Check if a PDF is in favorites
  bool isFavorite(String pdfId) {
    return _favoritePdfIds.contains(pdfId);
  }

  // Toggle favorite status of a PDF
  Future<void> toggleFavorite(String pdfId) async {
    // Check if user is logged in
    if (_auth.currentUser == null) {
      _logger.w('Cannot toggle favorite: No user logged in');
      return;
    }

    if (_favoritePdfIds.contains(pdfId)) {
      _favoritePdfIds.remove(pdfId);
    } else {
      _favoritePdfIds.add(pdfId);
    }
    notifyListeners();
    await _saveFavorites();
  }

  // Check if favorites are loaded
  bool get isInitialized => _isInitialized;

  // Load favorites from Firebase Realtime Database
  Future<void> _loadFavorites() async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('Cannot load favorites: No user logged in');
        return;
      }

      _logger.d('Loading favorites for user: ${user.uid}');

      // Reference to user's favorites in database
      final favoritesRef = _database.ref('users/${user.uid}/favorites');

      // Get favorites snapshot
      final snapshot = await favoritesRef.get();

      _favoritePdfIds.clear();

      if (snapshot.exists && snapshot.value != null) {
        // Convert snapshot value to Map
        final Map<dynamic, dynamic> favoritesMap =
            snapshot.value as Map<dynamic, dynamic>;

        // Add each favorite PDF ID to the set
        favoritesMap.forEach((key, value) {
          if (value == true) {
            _favoritePdfIds.add(key.toString());
          }
        });
      }

      _isInitialized = true;
      notifyListeners();
      _logger.i('Favorites loaded successfully for user: ${user.uid}');
    } catch (e) {
      _logger.e('Error loading favorites: $e');
    }
  }

  // Save favorites to Firebase Realtime Database
  Future<void> _saveFavorites() async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('Cannot save favorites: No user logged in');
        return;
      }

      _logger.d('Saving favorites for user: ${user.uid}');

      // Reference to user's favorites in database
      final favoritesRef = _database.ref('users/${user.uid}/favorites');

      // Create a map of favorite PDFs
      final Map<String, bool> favoritesMap = {};
      for (final pdfId in _favoritePdfIds) {
        favoritesMap[pdfId] = true;
      }

      // Save to database
      await favoritesRef.set(favoritesMap);

      _logger.i('Favorites saved successfully for user: ${user.uid}');
    } catch (e) {
      _logger.e('Error saving favorites: $e');
    }
  }

  // Get list of favorite PDFs from the full list
  List<PdfNote> getFavoritePdfs(List<PdfNote> allPdfs) {
    if (!_isInitialized) return [];
    return allPdfs.where((pdf) => _favoritePdfIds.contains(pdf.id)).toList();
  }
}
