import '../../models/firebase_note.dart';

/// Combined Hybrid Recommendation System
/// Combines Rule-Based and Content-Based filtering for note recommendations
class CollaborativeFilteringAlgorithm {
  // Singleton pattern
  static final CollaborativeFilteringAlgorithm _instance = 
      CollaborativeFilteringAlgorithm._internal();
  factory CollaborativeFilteringAlgorithm() => _instance;
  CollaborativeFilteringAlgorithm._internal();

  // Category similarity weights for content-based filtering
  static const Map<String, List<String>> _categoryRelations = {
    'programming': ['theory', 'notes', 'assignment'],
    'theory': ['programming', 'notes', 'numerical'],
    'numerical': ['theory', 'programming', 'assignment'],
    'assignment': ['programming', 'theory', 'question paper'],
    'question paper': ['assignment', 'theory', 'notes'],
    'notes': ['theory', 'programming', 'assignment'],
  };

  // Semester progression weights
  static const Map<String, List<String>> _semesterProgression = {
    '1st': ['2nd', '3rd'],
    '2nd': ['1st', '3rd', '4th'],
    '3rd': ['2nd', '4th', '5th'],
    '4th': ['3rd', '5th', '6th'],
    '5th': ['4th', '6th', '7th'],
    '6th': ['5th', '7th', '8th'],
    '7th': ['6th', '8th'],
    '8th': ['7th', '6th'],
  };

  /// Main hybrid recommendation method
  /// Returns a structured map with rule-based and content-based recommendations
  Map<String, List<FirebaseNote>> getHybridRecommendations({
    required List<FirebaseNote> allNotes,
    required String currentUserSemester,
    FirebaseNote? currentlyViewingNote,
    int maxSuggestions = 10,
  }) {
    // Rule-Based: Get semester-based recommendations first
    final semesterNotes = _getRuleBasedRecommendations(
      allNotes: allNotes,
      userSemester: currentUserSemester,
      excludeCurrentNote: currentlyViewingNote,
    );

    // Content-Based: Get related notes based on current note
    final contentBasedNotes = _getContentBasedRecommendations(
      allNotes: allNotes,
      currentNote: currentlyViewingNote,
      excludeNotes: semesterNotes,
      maxSuggestions: 50, // Increased to show all same-category notes
    );

    return {
      'semester_notes': semesterNotes,
      'you_might_like': contentBasedNotes,
      'combined': _combineRecommendations(semesterNotes, contentBasedNotes),
    };
  }

  /// Rule-Based Filtering: Returns all notes for user's current semester (excluding current note)
  List<FirebaseNote> _getRuleBasedRecommendations({
    required List<FirebaseNote> allNotes,
    required String userSemester,
    FirebaseNote? excludeCurrentNote,
  }) {
    final normalizedUserSemester = _normalizeSemester(userSemester);
    
    // Debug logging
    print('🔍 Rule-based filtering: Looking for semester "$normalizedUserSemester" (from "$userSemester")');
    
    // Debug: Show all unique semesters in the dataset
    final allSemesters = allNotes.map((note) => '${note.semester} -> ${_normalizeSemester(note.semester ?? '')}').toSet().toList();
    print('📚 Available semesters in dataset:');
    allSemesters.forEach((semester) => print('   $semester'));
    print('📊 Total notes to check: ${allNotes.length}');
    
    final matchingNotes = allNotes.where((note) {
      final noteSemester = _normalizeSemester(note.semester ?? '');
      
      // Debug: Show all notes being checked
      print('🔍 Checking note: "${note.title}" - raw semester: "${note.semester}", normalized: "$noteSemester"');
      
      // Exclude the current note being viewed
      if (excludeCurrentNote != null && note.id == excludeCurrentNote.id) {
        print('❌ Excluded current note: "${note.title}"');
        return false;
      }
      
      final matches = noteSemester == normalizedUserSemester;
      if (matches) {
        print('✅ Match found: "${note.title}" - semester: "$noteSemester"');
      } else {
        print('❌ No match: "${note.title}" - expected: "$normalizedUserSemester", got: "$noteSemester"');
      }
      
      return matches;
    }).toList();
    
    print('📊 Found ${matchingNotes.length} matching notes for semester "$normalizedUserSemester"');
    return matchingNotes;
  }

  /// Content-Based Filtering: Returns notes based on similarity to current note
  List<FirebaseNote> _getContentBasedRecommendations({
    required List<FirebaseNote> allNotes,
    FirebaseNote? currentNote,
    List<FirebaseNote> excludeNotes = const [],
    int maxSuggestions = 10,
  }) {
    if (currentNote == null) return [];

    final excludeIds = excludeNotes.map((note) => note.id).toSet();
    
    // Score notes based on similarity to current note
    final scoredNotes = <({FirebaseNote note, double score})>[];

    for (final note in allNotes) {
      if (excludeIds.contains(note.id) || note.id == currentNote.id) continue;

      final score = _calculateSimilarityScore(currentNote, note);
      if (score > 0) {
        scoredNotes.add((note: note, score: score));
      }
    }

    // Sort by score (highest first) and take top suggestions
    scoredNotes.sort((a, b) => b.score.compareTo(a.score));
    
    return scoredNotes
        .take(maxSuggestions)
        .map((scored) => scored.note)
        .toList();
  }

  /// Calculate similarity score between two notes (STRICT category matching for "You Might Also Like")
  double _calculateSimilarityScore(FirebaseNote currentNote, FirebaseNote candidateNote) {
    double score = 0.0;

    final currentCategory = currentNote.category.toLowerCase().trim();
    final candidateCategory = candidateNote.category.toLowerCase().trim();
    final currentSemester = _normalizeSemester(currentNote.semester ?? '');
    final candidateSemester = _normalizeSemester(candidateNote.semester ?? '');

    // 1. STRICT: Only exact category match (for "You Might Also Like" section)
    if (currentCategory == candidateCategory) {
      score += 10.0; // Higher weight for exact match
    } else {
      // No score for different categories - strict matching
      return 0.0;
    }

    // 2. Same semester bonus (within same category)
    if (currentSemester == candidateSemester) {
      score += 3.0;
    }
    // 3. Adjacent semester bonus (within same category)
    else if (_semesterProgression[currentSemester]?.contains(candidateSemester) == true) {
      score += 1.5;
    }

    // 4. Title similarity bonus (within same category)
    score += _calculateTitleSimilarity(currentNote.title, candidateNote.title) * 2.0; // Higher weight

    // 5. Type match bonus (within same category)
    if (currentNote.type.toLowerCase() == candidateNote.type.toLowerCase()) {
      score += 2.0;
    }

    return score;
  }

  /// Calculate title similarity based on common keywords
  double _calculateTitleSimilarity(String title1, String title2) {
    final words1 = _extractKeywords(title1);
    final words2 = _extractKeywords(title2);

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = (words1.length + words2.length) / 2;

    return (commonWords / totalWords) * 1.0; // Max 1.0 points for title similarity
  }

  /// Extract meaningful keywords from title
  Set<String> _extractKeywords(String title) {
    // Remove common words and extract meaningful keywords
    const stopWords = {'the', 'and', 'or', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'};
    
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .split(' ')
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toSet();
  }

  /// Combine rule-based and content-based recommendations intelligently
  List<FirebaseNote> _combineRecommendations(
    List<FirebaseNote> semesterNotes,
    List<FirebaseNote> contentBasedNotes,
  ) {
    final combined = <FirebaseNote>[];
    final addedIds = <String>{};

    // Add semester notes first (rule-based priority)
    for (final note in semesterNotes) {
      combined.add(note);
      addedIds.add(note.id);
    }

    // Add content-based notes that aren't already included
    for (final note in contentBasedNotes) {
      if (!addedIds.contains(note.id)) {
        combined.add(note);
        addedIds.add(note.id);
      }
    }

    return combined;
  }

  /// Get related notes for a specific category (STRICT - only exact category matches)
  List<FirebaseNote> getRelatedNotesByCategory({
    required List<FirebaseNote> allNotes,
    required String category,
    String? excludeNoteId,
    int maxResults = 10,
  }) {
    final normalizedCategory = category.toLowerCase().trim();

    // STRICT: Only get exact category matches - no related categories
    final exactMatches = allNotes.where((note) {
      return note.category.toLowerCase().trim() == normalizedCategory &&
             note.id != excludeNoteId;
    }).toList();

    return exactMatches.take(maxResults).toList();
  }

  /// Get semester-based recommendations for related subjects
  List<FirebaseNote> getRelatedSemesterNotes({
    required List<FirebaseNote> allNotes,
    required String currentSemester,
    String? excludeNoteId,
    int maxResults = 5,
  }) {
    final normalizedSemester = _normalizeSemester(currentSemester);
    final relatedSemesters = _semesterProgression[normalizedSemester] ?? [];
    final relatedNotes = <FirebaseNote>[];

    // Get notes from related semesters
    for (final semester in relatedSemesters) {
      final semesterNotes = allNotes.where((note) {
        final noteSemester = _normalizeSemester(note.semester ?? '');
        return noteSemester == semester &&
               note.id != excludeNoteId &&
               !relatedNotes.any((existing) => existing.id == note.id);
      }).toList();

      relatedNotes.addAll(semesterNotes);
      
      if (relatedNotes.length >= maxResults) break;
    }

    return relatedNotes.take(maxResults).toList();
  }

  /// Normalize semester format for consistent matching
  String _normalizeSemester(String semester) {
    final normalized = semester.toLowerCase().trim();
    
    // Handle empty or null semesters (likely extra courses)
    if (normalized.isEmpty || normalized == 'null' || normalized == 'undefined') {
      return 'extra';
    }
    
    // Handle different semester formats
    final semesterMap = {
      // Numeric formats
      '1': '1st',
      '2': '2nd', 
      '3': '3rd',
      '4': '4th',
      '5': '5th',
      '6': '6th',
      '7': '7th',
      '8': '8th',
      
      // Written formats
      'first': '1st',
      'second': '2nd',
      'third': '3rd',
      'fourth': '4th',
      'fifth': '5th',
      'sixth': '6th',
      'seventh': '7th',
      'eighth': '8th',
      
      // Standard formats (should already be correct)
      '1st': '1st',
      '2nd': '2nd',
      '3rd': '3rd',
      '4th': '4th',
      '5th': '5th',
      '6th': '6th',
      '7th': '7th',
      '8th': '8th',
      
      // Extra course variations
      'extra': 'extra',
      'extracourse': 'extra',
      'extra course': 'extra',
      'extra courses': 'extra',
      'extracourses': 'extra',
    };

    return semesterMap[normalized] ?? normalized;
  }

  /// Get simple related notes (used for quick related subjects in UI)
  List<FirebaseNote> getSimpleRelatedNotes({
    required List<FirebaseNote> allNotes,
    required FirebaseNote currentNote,
    int maxResults = 6,
  }) {
    // Get content-based recommendations (show all available in same category)
    final contentBased = _getContentBasedRecommendations(
      allNotes: allNotes,
      currentNote: currentNote,
      maxSuggestions: 50, // Increased to show more same-category notes
    );

    return contentBased;
  }
}
