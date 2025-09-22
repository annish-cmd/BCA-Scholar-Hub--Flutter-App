import '../models/search_result.dart';
import '../models/firebase_note.dart';
import '../services/database_service.dart';
import '../utils/encryption/algorithms/trie_search_algorithm.dart';
import 'package:logger/logger.dart';

class SearchService {
  static final Logger _logger = Logger();
  static final DatabaseService _databaseService = DatabaseService();
  static final TrieSearchService _trieService = TrieSearchService();

  // Cache for all notes to avoid repeated Firebase calls
  static List<FirebaseNote>? _cachedNotes;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  static bool _trieInitialized = false;

  // Get all notes from Firebase (with caching)
  static Future<List<FirebaseNote>> _getAllNotesFromFirebase() async {
    // Check if cache is still valid
    if (_cachedNotes != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheValidDuration) {
      _logger.d('Using cached notes data');
      return _cachedNotes!;
    }

    _logger.d('Fetching fresh notes data from Firebase');
    List<FirebaseNote> allNotes = [];

    try {
      // Get notes from all semesters (1st to 8th)
      for (int semester = 1; semester <= 8; semester++) {
        String semesterStr = '${semester}st';
        if (semester == 2)
          semesterStr = '2nd';
        else if (semester == 3)
          semesterStr = '3rd';
        else if (semester > 3)
          semesterStr = '${semester}th';

        List<FirebaseNote> semesterNotes = await _databaseService
            .getSemesterNotes(semesterStr);
        allNotes.addAll(semesterNotes);
      }

      // Also get extra course notes
      List<FirebaseNote> extraNotes =
          await _databaseService.getExtraCourseNotes();
      allNotes.addAll(extraNotes);

      // Update cache
      _cachedNotes = allNotes;
      _lastCacheTime = DateTime.now();

      // Initialize trie search with the notes
      await _initializeTrieSearch(allNotes);

      _logger.i('Successfully fetched ${allNotes.length} notes from Firebase');
    } catch (e) {
      _logger.e('Error fetching notes from Firebase:', error: e);
      // Return cached data if available, otherwise empty list
      return _cachedNotes ?? [];
    }

    return allNotes;
  }

  // Initialize trie search with Firebase notes (title-focused)
  static Future<void> _initializeTrieSearch(List<FirebaseNote> notes) async {
    _logger.d('Initializing trie search with ${notes.length} notes');

    try {
      List<Map<String, dynamic>> trieNotes = [];

      for (var note in notes) {
        // Focus only on title for trie search
        String title = note.title.trim();

        // Log sample notes for debugging
        if (trieNotes.length < 5) {
          _logger.d(
            'Sample note ${trieNotes.length + 1}: title="$title", category="${note.category}", semester="${note.semester}"',
          );
        }

        trieNotes.add({
          'id': note.id,
          'title': title,
          'category': note.category,
          'description': note.description,
          'semester': note.semester,
          'documentUrl': note.documentUrl,
          'imageUrl': note.imageUrl,
          'type': note.type,
          'fileName': note.fileName,
          'fileExtension': note.fileExtension,
          'fileSize': note.fileSize,
          'storagePath': note.storagePath,
          'storageProvider': note.storageProvider,
          'uploadedAt': note.uploadedAt,
          'uploadedBy': note.uploadedBy,
          'lastModified':
              DateTime.fromMillisecondsSinceEpoch(
                note.uploadedAt,
              ).toIso8601String(),
        });
      }

      await _trieService.initialize(trieNotes);
      _trieInitialized = true;

      // Get and log statistics
      Map<String, int>? stats = _trieService.getStatistics();
      _logger.i(
        'Trie search initialized successfully with ${notes.length} notes. Stats: $stats',
      );
    } catch (e) {
      _logger.e('Error initializing trie search:', error: e);
      _trieInitialized = false;
    }
  }

  // Search across all Firebase notes using title-focused trie algorithm
  static Future<List<SearchResult>> searchSubjects(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final List<SearchResult> results = [];
    final String normalizedQuery = query.toLowerCase().trim();

    try {
      List<FirebaseNote> allNotes = await _getAllNotesFromFirebase();

      // Use trie search if initialized
      if (_trieInitialized) {
        _logger.d('Using trie search for query: "$query"');

        // Search using trie algorithm (title-focused)
        List<Map<String, dynamic>> trieResults = _trieService.search(
          normalizedQuery,
        );

        _logger.d(
          'Trie search found ${trieResults.length} initial results for "$normalizedQuery"',
        );

        // Debug: Log some details about the search
        if (normalizedQuery.length == 1) {
          Map<String, int>? stats = _trieService.getStatistics();
          _logger.d(
            'Single character search "$normalizedQuery" - Trie stats: $stats',
          );

          // Debug: Try to get suggestions for this single character
          List<String> suggestions = _trieService.getSuggestions(
            normalizedQuery,
          );
          _logger.d(
            'Got ${suggestions.length} suggestions for "$normalizedQuery": ${suggestions.take(5).toList()}',
          );
        }

        // Convert trie results back to SearchResult
        Set<String> processedIds = {};
        for (var trieResult in trieResults) {
          String noteId = trieResult['id']?.toString() ?? '';
          if (noteId.isNotEmpty && !processedIds.contains(noteId)) {
            // Find the corresponding FirebaseNote
            Iterable<FirebaseNote> matchingNotes = allNotes.where(
              (note) => note.id == noteId,
            );
            FirebaseNote? firebaseNote =
                matchingNotes.isNotEmpty ? matchingNotes.first : null;

            if (firebaseNote != null) {
              results.add(SearchResult.fromFirebaseNote(firebaseNote));
              processedIds.add(noteId);
            }
          }
        }

        _logger.i(
          'Title-focused trie search for "$query" returned ${results.length} results',
        );

        // Debug: For single character searches, log more details if no results found
        if (results.isEmpty && normalizedQuery.length == 1) {
          _logger.w(
            'Single character search "$normalizedQuery" returned 0 results - this may indicate a trie indexing issue',
          );

          // Try fallback search to see if Firebase has data
          int fallbackCount = 0;
          List<String> fallbackTitles = [];
          for (final note in allNotes) {
            if (note.title.toLowerCase().contains(normalizedQuery)) {
              fallbackCount++;
              fallbackTitles.add(note.title);
            }
          }
          _logger.d(
            'Fallback direct search found $fallbackCount notes containing "$normalizedQuery": ${fallbackTitles.take(3).toList()}',
          );

          // If fallback found results but trie didn't, force a manual search using the trie
          if (fallbackCount > 0) {
            _logger.w(
              'Trie failed but direct search succeeded - attempting manual trie search',
            );

            // Add fallback results manually
            Set<String> processedIds = {};
            for (final note in allNotes) {
              if (note.title.toLowerCase().contains(normalizedQuery) &&
                  !processedIds.contains(note.id)) {
                results.add(SearchResult.fromFirebaseNote(note));
                processedIds.add(note.id);
              }
            }
            _logger.i(
              'Manual fallback added ${results.length} results for "$normalizedQuery"',
            );
          }
        }
      } else {
        _logger.d('Fallback to basic search for query: "$query"');

        // Fallback to basic title search if trie is not initialized
        for (final note in allNotes) {
          // Search primarily in title, then category and description
          bool matches =
              note.title.toLowerCase().contains(normalizedQuery) ||
              note.category.toLowerCase().contains(normalizedQuery) ||
              note.description.toLowerCase().contains(normalizedQuery);

          if (matches) {
            results.add(SearchResult.fromFirebaseNote(note));
          }
        }

        _logger.i(
          'Basic search for "$query" returned ${results.length} results',
        );
      }
    } catch (e) {
      _logger.e('Error searching subjects:', error: e);
    }

    return results;
  }

  // Get all subjects (for showing all subjects when search is empty)
  static Future<List<SearchResult>> getAllSubjects() async {
    final List<SearchResult> allSubjects = [];

    try {
      List<FirebaseNote> allNotes = await _getAllNotesFromFirebase();

      for (final note in allNotes) {
        allSubjects.add(SearchResult.fromFirebaseNote(note));
      }

      _logger.i('Retrieved ${allSubjects.length} total subjects from Firebase');
    } catch (e) {
      _logger.e('Error getting all subjects:', error: e);
    }

    return allSubjects;
  }

  // Helper method for fuzzy partial matching
  static bool _isPartialMatch(String query, String word) {
    if (query.length < 2 || word.length < 2) return false;

    // Check if query is a partial match of word with some tolerance
    int matches = 0;
    int queryIndex = 0;

    for (int i = 0; i < word.length && queryIndex < query.length; i++) {
      if (word[i] == query[queryIndex]) {
        matches++;
        queryIndex++;
      }
    }

    // Consider it a match if at least 70% of query characters are found in order
    double matchRatio = matches / query.length;
    return matchRatio >= 0.7;
  }

  // Helper method for partial word matching in content
  static bool _hasPartialWordMatch(String query, String content) {
    if (query.length < 2) return content.contains(query);

    List<String> contentWords = content.split(RegExp(r'\s+'));

    for (String word in contentWords) {
      if (word.length >= query.length) {
        // Check if word starts with query
        if (word.startsWith(query)) return true;

        // Check for approximate matching (allowing 1-2 character differences)
        if (query.length >= 3) {
          int differences = 0;
          int minLength = query.length;

          for (int i = 0; i < minLength && i < word.length; i++) {
            if (query[i] != word[i]) {
              differences++;
            }
          }

          // Allow up to 1 difference for queries 3-5 chars, 2 for longer
          int allowedDifferences = query.length <= 5 ? 1 : 2;
          if (differences <= allowedDifferences) return true;
        }
      }
    }

    return false;
  }

  // Get search suggestions using title-focused trie algorithm
  static Future<List<String>> getSearchSuggestions(String prefix) async {
    if (prefix.isEmpty) return [];

    try {
      // Ensure trie is initialized
      if (!_trieInitialized) {
        await _getAllNotesFromFirebase();
      }

      if (_trieInitialized) {
        List<String> suggestions = _trieService.getSuggestions(
          prefix.toLowerCase(),
        );
        _logger.d(
          'Got ${suggestions.length} title suggestions for prefix: "$prefix"',
        );
        return suggestions;
      }
    } catch (e) {
      _logger.e('Error getting search suggestions:', error: e);
    }

    return [];
  }

  // Get enriched autocomplete suggestions with note details
  static Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(
    String prefix,
  ) async {
    if (prefix.isEmpty) return [];

    try {
      // Ensure trie is initialized
      if (!_trieInitialized) {
        await _getAllNotesFromFirebase();
      }

      if (_trieInitialized) {
        List<Map<String, dynamic>> suggestions = _trieService
            .getAutocompleteSuggestions(prefix.toLowerCase());
        _logger.d(
          'Got ${suggestions.length} enriched title suggestions for prefix: "$prefix"',
        );
        return suggestions;
      }
    } catch (e) {
      _logger.e('Error getting autocomplete suggestions:', error: e);
    }

    return [];
  }

  // Get trie search statistics
  static Map<String, int>? getSearchStatistics() {
    if (_trieInitialized) {
      return _trieService.getStatistics();
    }
    return null;
  }

  // Clear cache and trie (useful for forcing refresh)
  static void clearCache() {
    _cachedNotes = null;
    _lastCacheTime = null;
    _trieService.clear();
    _trieInitialized = false;
    _logger.d('Search cache and trie cleared');
  }

  // Force refresh of data and reinitialize trie
  static Future<void> forceRefresh() async {
    clearCache();
    await _getAllNotesFromFirebase();
    _logger.i('Forced refresh completed');
  }
}
