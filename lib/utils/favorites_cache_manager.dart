import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/pdf_note.dart';
import '../screens/home_content_screen.dart';
import '../services/database_service.dart';

class FavoritesCacheManager {
  // Singleton pattern for global access
  static final FavoritesCacheManager _instance = FavoritesCacheManager._internal();
  factory FavoritesCacheManager() => _instance;
  FavoritesCacheManager._internal();

  // Cache storage
  static List<PdfNote>? _memoryCache;
  static DateTime? _memoryCacheTime;
  static const _memoryCacheDuration = Duration(hours: 2);
  static const _persistentCacheDuration = Duration(days: 1);
  static bool _isLoading = false;

  // Cache keys
  static const String _cacheKey = 'favorites_notes_cache';
  static const String _cacheTimeKey = 'favorites_cache_time';

  /// Get notes instantly - never returns null, always has data
  List<PdfNote> getNotesInstantly() {
    // 1. Memory cache (instant)
    if (_memoryCache != null && 
        _memoryCacheTime != null &&
        DateTime.now().difference(_memoryCacheTime!) < _memoryCacheDuration) {
      print('🚀 INSTANT: Memory cache hit');
      return _memoryCache!;
    }

    // 2. Fallback to hardcoded notes (always available)
    print('📱 INSTANT: Using hardcoded fallback');
    return List<PdfNote>.from(HomeContentScreen.pdfNotes);
  }

  /// Load and update cache asynchronously (non-blocking)
  Future<List<PdfNote>> loadAndUpdateCache() async {
    // Check if already loading
    if (_isLoading) {
      return getNotesInstantly();
    }
    
    _isLoading = true;

    try {
      // 1. Try memory cache first
      if (_memoryCache != null && 
          _memoryCacheTime != null &&
          DateTime.now().difference(_memoryCacheTime!) < _memoryCacheDuration) {
        return _memoryCache!;
      }

      // 2. Try persistent cache
      final persistentData = await _loadPersistentCache();
      if (persistentData != null) {
        _memoryCache = persistentData;
        _memoryCacheTime = DateTime.now();
        print('⚡ CACHE: Loaded from persistent storage');
        return persistentData;
      }

      // 3. Load from Firebase
      final freshData = await _loadFromFirebase();
      _memoryCache = freshData;
      _memoryCacheTime = DateTime.now();
      await _savePersistentCache(freshData);
      print('🔄 FRESH: Loaded from Firebase');
      return freshData;

    } finally {
      _isLoading = false;
    }
  }

  /// Load from persistent storage
  Future<List<PdfNote>?> _loadPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cacheKey);
      final cacheTime = prefs.getInt(_cacheTimeKey);
      
      if (cacheData != null && cacheTime != null) {
        final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        final now = DateTime.now();
        
        if (now.difference(cacheDateTime) < _persistentCacheDuration) {
          final List<dynamic> jsonList = json.decode(cacheData);
          return jsonList.map((json) => PdfNote.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('❌ Persistent cache load failed: $e');
    }
    return null;
  }

  /// Save to persistent storage
  Future<void> _savePersistentCache(List<PdfNote> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notes.map((note) => note.toJson()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ Persistent cache save failed: $e');
    }
  }

  /// Load fresh data from Firebase
  Future<List<PdfNote>> _loadFromFirebase() async {
    final databaseService = DatabaseService();
    final List<Future> futures = [];
    
    // Parallel fetch all semesters and extra courses
    for (var sem in ["1st","2nd","3rd","4th","5th","6th","7th","8th"]) {
      futures.add(databaseService.getSemesterNotes(sem).catchError((_) => <dynamic>[]));
    }
    futures.add(databaseService.getExtraCourseNotes().catchError((_) => <dynamic>[]));

    final results = await Future.wait(futures);
    
    List<PdfNote> firebaseNotes = [];
    for (int i = 0; i < 8; i++) {
      if (results[i] is List && results[i].isNotEmpty) {
        firebaseNotes.addAll((results[i] as List).map((n) => n.toPdfNote()));
      }
    }
    if (results[8] is List && results[8].isNotEmpty) {
      firebaseNotes.addAll((results[8] as List).map((n) => n.toPdfNote()));
    }

    // Combine with hardcoded notes
    final allNotes = List<PdfNote>.from(HomeContentScreen.pdfNotes);
    allNotes.addAll(firebaseNotes);
    return allNotes;
  }

  /// Clear all caches
  Future<void> clearCache() async {
    _memoryCache = null;
    _memoryCacheTime = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
    } catch (e) {
      print('❌ Cache clear failed: $e');
    }
  }

  /// Preload data in background
  void preloadInBackground() {
    if (_isLoading) return;
    
    Future.delayed(Duration(milliseconds: 100), () {
      loadAndUpdateCache();
    });
  }

  /// Check if cache exists
  bool get hasCachedData {
    return _memoryCache != null && 
           _memoryCacheTime != null &&
           DateTime.now().difference(_memoryCacheTime!) < _memoryCacheDuration;
  }
}
