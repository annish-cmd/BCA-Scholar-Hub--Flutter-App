class TrieNode {
  Map<String, TrieNode> children = {};
  bool isEndOfWord = false;
  Set<String> completeTitles =
      {}; // Store complete titles that pass through this node
  List<Map<String, dynamic>> noteData = [];

  TrieNode();
}

class TrieSearchAlgorithm {
  late TrieNode _root;
  static const int maxSuggestions = 20;
  final Map<String, Map<String, dynamic>> _titleToNoteMap =
      {}; // Map titles to note data

  // Fuzzy matching configuration
  static const int maxFuzzyDistance = 2; // Maximum allowed edit distance
  static const double fuzzyThreshold =
      0.6; // Minimum similarity threshold (0.0 to 1.0)

  TrieSearchAlgorithm() {
    _root = TrieNode();
  }

  /// Insert a note into the Trie focusing on title-based search
  void insertNote(String title, Map<String, dynamic> noteMetadata) {
    print('[TRIE INSERT DEBUG] Attempting to insert title: "$title"');

    if (title.isEmpty) {
      print('[TRIE INSERT DEBUG] Title is empty, skipping');
      return;
    }

    String normalizedTitle = title.toLowerCase().trim();
    print('[TRIE INSERT DEBUG] Normalized title: "$normalizedTitle"');

    // Store the mapping from title to note data
    _titleToNoteMap[normalizedTitle] = noteMetadata;
    print(
      '[TRIE INSERT DEBUG] Added to titleToNoteMap, total titles: ${_titleToNoteMap.length}',
    );

    // Insert the complete title for character-by-character search
    _insertTitle(normalizedTitle, noteMetadata);

    // Also insert individual words from the title (including single characters)
    List<String> words = _preprocessText(normalizedTitle);
    print('[TRIE INSERT DEBUG] Preprocessed words: $words');
    for (String word in words) {
      if (word.isNotEmpty) {
        _insertWord(word, noteMetadata, normalizedTitle);
        print('[TRIE INSERT DEBUG] Inserted word: "$word"');
      }
    }

    // Debug: Check node count after insertion
    int nodeCount = _countNodes(_root);
    print('[TRIE INSERT DEBUG] Node count after insertion: $nodeCount');
  }

  /// Insert a complete title character by character
  void _insertTitle(String title, Map<String, dynamic> noteMetadata) {
    TrieNode current = _root;

    for (int i = 0; i < title.length; i++) {
      String char = title[i];

      if (!current.children.containsKey(char)) {
        current.children[char] = TrieNode();
      }

      current = current.children[char]!;

      // Add the complete title to this node so it can be suggested
      current.completeTitles.add(title);

      // Limit the number of titles stored at each node
      if (current.completeTitles.length > maxSuggestions) {
        // Remove the lexicographically largest title to keep the most relevant ones
        List<String> sortedTitles = current.completeTitles.toList()..sort();
        current.completeTitles.remove(sortedTitles.last);
      }
    }

    current.isEndOfWord = true;

    // Add note metadata to the end node
    bool noteExists = current.noteData.any(
      (note) => note['id'] == noteMetadata['id'],
    );

    if (!noteExists) {
      current.noteData.add(noteMetadata);
    }
  }

  /// Insert individual words from title
  void _insertWord(
    String word,
    Map<String, dynamic> noteMetadata,
    String originalTitle,
  ) {
    TrieNode current = _root;

    for (int i = 0; i < word.length; i++) {
      String char = word[i];

      if (!current.children.containsKey(char)) {
        current.children[char] = TrieNode();
      }

      current = current.children[char]!;

      // Add the original title to suggestions at each character level
      current.completeTitles.add(originalTitle);
    }

    current.isEndOfWord = true;

    // Add note metadata to the end node
    bool noteExists = current.noteData.any(
      (note) => note['id'] == noteMetadata['id'],
    );

    if (!noteExists) {
      current.noteData.add(noteMetadata);
    }
  }

  /// Get instant title suggestions as user types (works with single letters)
  List<String> getSuggestions(String prefix) {
    if (prefix.isEmpty) return [];

    String normalizedPrefix = prefix.toLowerCase().trim();
    TrieNode? node = _findNode(normalizedPrefix);

    if (node == null) return [];

    // Get all complete titles that match this prefix
    Set<String> titleSuggestions = Set.from(node.completeTitles);

    // Also collect titles from child nodes if we don't have enough suggestions
    if (titleSuggestions.length < maxSuggestions) {
      _collectTitleSuggestions(node, titleSuggestions, maxSuggestions);
    }

    List<String> suggestions = titleSuggestions.toList();

    // Sort suggestions by relevance:
    // 1. Titles that start with the prefix first
    // 2. Then titles that contain the prefix
    // 3. Shorter titles before longer ones
    // 4. Alphabetical order
    suggestions.sort((a, b) {
      bool aStartsWithPrefix = a.startsWith(normalizedPrefix);
      bool bStartsWithPrefix = b.startsWith(normalizedPrefix);

      if (aStartsWithPrefix && !bStartsWithPrefix) return -1;
      if (!aStartsWithPrefix && bStartsWithPrefix) return 1;

      // Both start with prefix or both don't, sort by length then alphabetically
      if (a.length != b.length) {
        return a.length.compareTo(b.length);
      }
      return a.compareTo(b);
    });

    return suggestions.take(maxSuggestions).toList();
  }

  /// Search for notes based on title matching
  List<Map<String, dynamic>> searchNotes(String query) {
    if (query.isEmpty) return [];

    String normalizedQuery = query.toLowerCase().trim();
    Set<Map<String, dynamic>> results = {};

    // Debug logging for single characters
    if (normalizedQuery.length == 1) {
      print('[TRIE DEBUG] Searching for single character: "$normalizedQuery"');
      print('[TRIE DEBUG] Total titles in trie: ${_titleToNoteMap.length}');

      // Debug: Check if any titles contain this character
      int containsCount = 0;
      List<String> sampleTitles = [];
      for (String title in _titleToNoteMap.keys) {
        if (title.contains(normalizedQuery)) {
          containsCount++;
          if (sampleTitles.length < 3) {
            sampleTitles.add(title);
          }
        }
      }
      print(
        '[TRIE DEBUG] Titles containing "$normalizedQuery": $containsCount, samples: $sampleTitles',
      );
    }

    // Strategy 1: Direct title prefix matching
    TrieNode? prefixNode = _findNode(normalizedQuery);
    if (prefixNode != null) {
      // Add all notes from this prefix node
      results.addAll(prefixNode.noteData);

      // Also get notes from complete titles that match this prefix
      for (String title in prefixNode.completeTitles) {
        if (_titleToNoteMap.containsKey(title)) {
          results.add(_titleToNoteMap[title]!);
        }
      }

      if (normalizedQuery.length == 1) {
        print(
          '[TRIE DEBUG] Strategy 1 (prefix matching) found ${results.length} results',
        );
      }
    }

    // Strategy 2: Search within individual words of titles
    List<String> queryWords = _preprocessText(normalizedQuery);
    for (String word in queryWords) {
      if (word.isNotEmpty) {
        List<Map<String, dynamic>> wordResults = _searchWord(word);
        results.addAll(wordResults);
      }
    }

    if (normalizedQuery.length == 1) {
      print(
        '[TRIE DEBUG] Strategy 2 (word search) total results: ${results.length}',
      );
    }

    // Strategy 3: Enhanced brute-force matching for single characters and short queries
    // This ensures we catch all possible matches, especially for single characters
    if (normalizedQuery.length <= 2) {
      int beforeBruteForce = results.length;

      for (String title in _titleToNoteMap.keys) {
        bool hasMatch = false;

        // Direct title matching
        if (title.contains(normalizedQuery)) {
          hasMatch = true;
        }

        // Word-level matching within titles
        if (!hasMatch) {
          List<String> titleWords = _preprocessText(title);
          for (String titleWord in titleWords) {
            if (titleWord.startsWith(normalizedQuery) ||
                titleWord.contains(normalizedQuery) ||
                (normalizedQuery.length == 1 &&
                    titleWord.contains(normalizedQuery))) {
              hasMatch = true;
              break;
            }
          }
        }

        // Character-by-character matching for single characters
        if (!hasMatch && normalizedQuery.length == 1) {
          for (int i = 0; i < title.length; i++) {
            if (title[i] == normalizedQuery[0]) {
              hasMatch = true;
              break;
            }
          }
        }

        if (hasMatch) {
          results.add(_titleToNoteMap[title]!);
        }
      }

      if (normalizedQuery.length == 1) {
        print(
          '[TRIE DEBUG] Strategy 3 (brute-force) added ${results.length - beforeBruteForce} results, total: ${results.length}',
        );
      }
    }

    // Strategy 4: Fuzzy matching for longer queries (handles typos)
    if (normalizedQuery.length >= 2 && results.length < maxSuggestions) {
      int beforeFuzzy = results.length;

      List<String> fuzzyMatches = _findFuzzyMatches(normalizedQuery);
      for (String title in fuzzyMatches) {
        if (_titleToNoteMap.containsKey(title)) {
          // Avoid duplicates
          bool alreadyExists = results.any(
            (note) => note['title']?.toString().toLowerCase() == title,
          );
          if (!alreadyExists) {
            results.add(_titleToNoteMap[title]!);
          }
        }
      }

      print(
        '[TRIE DEBUG] Strategy 4 (fuzzy matching) added ${results.length - beforeFuzzy} results, total: ${results.length}',
      );
    }

    List<Map<String, dynamic>> finalResults = results.toList();

    // Sort results by relevance score based on title matching
    finalResults.sort((a, b) {
      double scoreA = _calculateTitleRelevanceScore(a, normalizedQuery);
      double scoreB = _calculateTitleRelevanceScore(b, normalizedQuery);
      return scoreB.compareTo(scoreA);
    });

    return finalResults;
  }

  /// Search for a specific word in titles
  List<Map<String, dynamic>> _searchWord(String word) {
    TrieNode? node = _findNode(word);
    if (node == null) return [];

    Set<Map<String, dynamic>> results = {};
    results.addAll(node.noteData);

    // Also get notes from titles that contain this word
    for (String title in node.completeTitles) {
      if (_titleToNoteMap.containsKey(title)) {
        results.add(_titleToNoteMap[title]!);
      }
    }

    return results.toList();
  }

  /// Find node for a given prefix/word
  TrieNode? _findNode(String prefix) {
    TrieNode current = _root;

    for (String char in prefix.split('')) {
      if (!current.children.containsKey(char)) {
        return null;
      }
      current = current.children[char]!;
    }

    return current;
  }

  /// Collect title suggestions from child nodes
  void _collectTitleSuggestions(
    TrieNode node,
    Set<String> suggestions,
    int maxCount,
  ) {
    if (suggestions.length >= maxCount) return;

    // Add titles from current node
    suggestions.addAll(node.completeTitles);

    if (suggestions.length >= maxCount) {
      // Trim to max count if exceeded
      List<String> sortedSuggestions = suggestions.toList()..sort();
      suggestions.clear();
      suggestions.addAll(sortedSuggestions.take(maxCount));
      return;
    }

    // Recursively collect from children
    for (TrieNode child in node.children.values) {
      _collectTitleSuggestions(child, suggestions, maxCount);
      if (suggestions.length >= maxCount) break;
    }
  }

  /// Preprocess text by removing special characters and splitting into words
  List<String> _preprocessText(String text) {
    // Remove special characters and split by whitespace
    String cleaned = text.replaceAll(RegExp(r'[^\w\s]'), ' ');
    List<String> words = cleaned.split(RegExp(r'\s+'));

    // Filter out empty strings only (keep single characters for single-letter search)
    return words.where((word) => word.isNotEmpty).toList();
  }

  /// Calculate relevance score based on title matching (enhanced with fuzzy logic)
  double _calculateTitleRelevanceScore(
    Map<String, dynamic> note,
    String query,
  ) {
    String title = note['title']?.toString().toLowerCase() ?? '';
    double score = 0.0;

    // Exact title match gets highest score
    if (title == query) {
      score += 100.0;
    }
    // Title starts with query gets very high score
    else if (title.startsWith(query)) {
      score += 50.0;
    }
    // Title contains query gets high score
    else if (title.contains(query)) {
      score += 25.0;
    }
    // Fuzzy matching bonus for longer queries
    else if (query.length >= 2) {
      double similarity = _calculateSimilarity(query, title);
      if (similarity >= fuzzyThreshold) {
        score += similarity * 20.0; // Scale similarity to score
      }
    }

    // Word-level matching (enhanced with fuzzy logic)
    List<String> queryWords = _preprocessText(query);
    List<String> titleWords = _preprocessText(title);

    int exactWordMatches = 0;
    int partialWordMatches = 0;
    int fuzzyWordMatches = 0;

    for (String queryWord in queryWords) {
      for (String titleWord in titleWords) {
        if (titleWord == queryWord) {
          exactWordMatches++;
          score += 10.0;
        } else if (titleWord.startsWith(queryWord)) {
          partialWordMatches++;
          score += 5.0;
        } else if (titleWord.contains(queryWord)) {
          score += 2.0;
        }
        // Fuzzy word matching for words with 2+ characters
        else if (queryWord.length >= 2 && titleWord.length >= 2) {
          double wordSimilarity = _calculateSimilarity(queryWord, titleWord);
          if (wordSimilarity >= fuzzyThreshold) {
            fuzzyWordMatches++;
            score += wordSimilarity * 8.0; // Fuzzy match bonus
          }
        }
      }
    }

    // Bonus for shorter titles (more specific results)
    if (title.length < 50) {
      score += 3.0;
    }

    // Penalty for very long titles
    if (title.length > 100) {
      score -= 2.0;
    }

    return score;
  }

  /// Get autocomplete suggestions with note count based on titles
  List<Map<String, dynamic>> getAutocompleteSuggestions(String prefix) {
    if (prefix.isEmpty) return [];

    List<String> titleSuggestions = getSuggestions(prefix);
    List<Map<String, dynamic>> enrichedSuggestions = [];

    for (String title in titleSuggestions) {
      if (_titleToNoteMap.containsKey(title)) {
        Map<String, dynamic> note = _titleToNoteMap[title]!;
        enrichedSuggestions.add({
          'suggestion': title,
          'noteCount': 1, // Each title represents one note
          'preview': note['category'] ?? '',
          'semester': note['semester'] ?? '',
          'type': note['type'] ?? 'pdf',
        });
      }
    }

    return enrichedSuggestions;
  }

  /// Clear all data from the Trie
  void clear() {
    _root = TrieNode();
    _titleToNoteMap.clear();
  }

  /// Get statistics about the Trie
  Map<String, int> getStatistics() {
    return {
      'totalTitles': _titleToNoteMap.length,
      'totalNodes': _countNodes(_root),
      'uniqueNotes': _titleToNoteMap.length,
    };
  }

  /// Helper method to count nodes recursively
  int _countNodes(TrieNode node) {
    int count = 1;
    for (TrieNode child in node.children.values) {
      count += _countNodes(child);
    }
    return count;
  }

  /// Calculate Levenshtein distance between two strings (for fuzzy matching)
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    // Initialize first row and column
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    // Fill the matrix
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Calculate similarity ratio between two strings (0.0 to 1.0)
  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    int maxLength = s1.length > s2.length ? s1.length : s2.length;
    int distance = _levenshteinDistance(s1, s2);
    return 1.0 - (distance / maxLength);
  }

  /// Find fuzzy matches for a query string
  List<String> _findFuzzyMatches(String query) {
    List<String> fuzzyMatches = [];
    String normalizedQuery = query.toLowerCase().trim();

    // Skip fuzzy matching for very short queries (single characters)
    if (normalizedQuery.length <= 1) return fuzzyMatches;

    for (String title in _titleToNoteMap.keys) {
      // Check fuzzy matching against the full title
      double titleSimilarity = _calculateSimilarity(normalizedQuery, title);
      if (titleSimilarity >= fuzzyThreshold) {
        fuzzyMatches.add(title);
        continue;
      }

      // Check fuzzy matching against individual words in the title
      List<String> titleWords = _preprocessText(title);
      for (String titleWord in titleWords) {
        if (titleWord.length >= 2) {
          // Only check words with 2+ characters
          double wordSimilarity = _calculateSimilarity(
            normalizedQuery,
            titleWord,
          );
          if (wordSimilarity >= fuzzyThreshold) {
            fuzzyMatches.add(title);
            break;
          }

          // Also check if query is similar to the beginning of the word
          if (titleWord.length >= normalizedQuery.length) {
            String wordPrefix = titleWord.substring(0, normalizedQuery.length);
            double prefixSimilarity = _calculateSimilarity(
              normalizedQuery,
              wordPrefix,
            );
            if (prefixSimilarity >= fuzzyThreshold) {
              fuzzyMatches.add(title);
              break;
            }
          }
        }
      }
    }

    return fuzzyMatches;
  }

  /// Enhanced getSuggestions with fuzzy matching
  List<String> getSuggestionsWithFuzzy(String prefix) {
    if (prefix.isEmpty) return [];

    Set<String> allSuggestions = {};

    // Get regular suggestions first
    List<String> regularSuggestions = getSuggestions(prefix);
    allSuggestions.addAll(regularSuggestions);

    // Add fuzzy matches if we don't have enough suggestions
    if (allSuggestions.length < maxSuggestions && prefix.length >= 2) {
      List<String> fuzzyMatches = _findFuzzyMatches(prefix);
      allSuggestions.addAll(fuzzyMatches);
    }

    List<String> suggestions = allSuggestions.toList();

    // Sort by relevance with fuzzy matching considered
    String normalizedPrefix = prefix.toLowerCase().trim();
    suggestions.sort((a, b) {
      // Calculate similarity scores
      double aSimilarity = _calculateSimilarity(normalizedPrefix, a);
      double bSimilarity = _calculateSimilarity(normalizedPrefix, b);

      // Exact matches first
      bool aExact = a.startsWith(normalizedPrefix);
      bool bExact = b.startsWith(normalizedPrefix);

      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      // Then by similarity score
      if (aSimilarity != bSimilarity) {
        return bSimilarity.compareTo(aSimilarity);
      }

      // Finally by length and alphabetically
      if (a.length != b.length) {
        return a.length.compareTo(b.length);
      }
      return a.compareTo(b);
    });

    return suggestions.take(maxSuggestions).toList();
  }

  /// Bulk insert multiple notes for better performance (title-focused)
  void bulkInsertNotes(List<Map<String, dynamic>> notes) {
    print('[TRIE BULK DEBUG] Starting bulk insert with ${notes.length} notes');

    for (int i = 0; i < notes.length; i++) {
      Map<String, dynamic> note = notes[i];
      String title = note['title']?.toString() ?? '';

      print('[TRIE BULK DEBUG] Processing note $i: title="$title"');

      if (title.isEmpty) {
        print('[TRIE BULK DEBUG] Note $i has empty title, skipping');
        continue;
      }

      insertNote(title, note);
      print('[TRIE BULK DEBUG] Completed inserting note $i');
    }

    print('[TRIE BULK DEBUG] Bulk insert completed');
  }
}

/// Singleton instance for global access
class TrieSearchService {
  static final TrieSearchService _instance = TrieSearchService._internal();
  factory TrieSearchService() => _instance;
  TrieSearchService._internal();

  final TrieSearchAlgorithm _trie = TrieSearchAlgorithm();

  TrieSearchAlgorithm get trie => _trie;

  /// Initialize the search service with notes
  Future<void> initialize(List<Map<String, dynamic>> notes) async {
    print(
      '[TRIE SERVICE DEBUG] initialize() called with ${notes.length} notes',
    );
    _trie.clear();
    print('[TRIE SERVICE DEBUG] Trie cleared, starting bulk insert');
    _trie.bulkInsertNotes(notes);
    print('[TRIE SERVICE DEBUG] Bulk insert completed');
  }

  /// Add a single note to the search index (title-focused)
  void addNote(Map<String, dynamic> note) {
    String title = note['title']?.toString() ?? '';

    if (title.isNotEmpty) {
      _trie.insertNote(title, note);
    }
  }

  /// Search for notes
  List<Map<String, dynamic>> search(String query) {
    print('[TRIE SERVICE DEBUG] search() method called with query: "$query"');
    List<Map<String, dynamic>> results = _trie.searchNotes(query);
    print(
      '[TRIE SERVICE DEBUG] search() method returning ${results.length} results',
    );
    return results;
  }

  /// Get suggestions for autocomplete (with fuzzy matching)
  List<String> getSuggestions(String prefix) {
    return _trie.getSuggestionsWithFuzzy(prefix);
  }

  /// Get enriched autocomplete suggestions
  List<Map<String, dynamic>> getAutocompleteSuggestions(String prefix) {
    return _trie.getAutocompleteSuggestions(prefix);
  }

  /// Clear the search index
  void clear() {
    _trie.clear();
  }

  /// Get search statistics
  Map<String, int> getStatistics() {
    return _trie.getStatistics();
  }
}
