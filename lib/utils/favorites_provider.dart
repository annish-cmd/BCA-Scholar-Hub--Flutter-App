import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_note.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<String> _favoritePdfIds = {};
  bool _isInitialized = false;

  FavoritesProvider() {
    _loadFavorites();
  }

  // Get all favorite PDF IDs
  Set<String> get favoritePdfIds => _favoritePdfIds;

  // Check if a PDF is in favorites
  bool isFavorite(String pdfId) {
    return _favoritePdfIds.contains(pdfId);
  }

  // Toggle favorite status of a PDF
  Future<void> toggleFavorite(String pdfId) async {
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

  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('favorite_pdfs') ?? [];
      _favoritePdfIds.clear();
      _favoritePdfIds.addAll(favoriteIds);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_pdfs', _favoritePdfIds.toList());
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Get list of favorite PDFs from the full list
  List<PdfNote> getFavoritePdfs(List<PdfNote> allPdfs) {
    if (!_isInitialized) return [];
    return allPdfs.where((pdf) => _favoritePdfIds.contains(pdf.id)).toList();
  }
}
