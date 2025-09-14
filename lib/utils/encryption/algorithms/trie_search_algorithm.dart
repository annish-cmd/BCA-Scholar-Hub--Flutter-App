class TrieNode {
  Map<String, TrieNode> children = {};
  bool isEndOfWord = false;
  List<String> suggestions = [];
  List<Map<String, dynamic>> noteData = [];

  TrieNode();
}

class TrieSearchAlgorithm {
  late TrieNode _root;
  static const int maxSuggestions = 10;

  TrieSearchAlgorithm() {
    _root = TrieNode();
  }

  /// Insert a note into the Trie with its content and metadata
  void insertNote(String content, Map<String, dynamic> noteMetadata) {
    if (content.isEmpty) return;

    // Split content into words and insert each word
    List<String> words = _preprocessText(content);

    for (String word in words) {
      if (word.isNotEmpty) {
        _insertWord(word.toLowerCase(), noteMetadata);
      }
    }

    // Also insert the full content for phrase searching
    _insertPhrase(content.toLowerCase(), noteMetadata);
  }

  /// Insert a single word into the Trie
  void _insertWord(String word, Map<String, dynamic> noteMetadata) {
    TrieNode current = _root;

    for (int i = 0; i < word.length; i++) {
      String char = word[i];

      if (!current.children.containsKey(char)) {
        current.children[char] = TrieNode();
      }

      current = current.children[char]!;

      // Add suggestion at each level (prefix)
      String prefix = word.substring(0, i + 1);
      if (!current.suggestions.contains(word)) {
        current.suggestions.add(word);
        if (current.suggestions.length > maxSuggestions) {
          current.suggestions.removeAt(0);
        }
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

  /// Insert a phrase for multi-word searching
  void _insertPhrase(String phrase, Map<String, dynamic> noteMetadata) {
    TrieNode current = _root;

    for (int i = 0; i < phrase.length; i++) {
      String char = phrase[i];

      if (!current.children.containsKey(char)) {
        current.children[char] = TrieNode();
      }

      current = current.children[char]!;
    }

    current.isEndOfWord = true;

    bool noteExists = current.noteData.any(
      (note) => note['id'] == noteMetadata['id'],
    );

    if (!noteExists) {
      current.noteData.add(noteMetadata);
    }
  }

  /// Get instant suggestions as user types
  List<String> getSuggestions(String prefix) {
    if (prefix.isEmpty) return [];

    TrieNode? node = _findNode(prefix.toLowerCase());
    if (node == null) return [];

    List<String> suggestions = [];
    _collectSuggestions(node, prefix.toLowerCase(), suggestions);

    // Sort suggestions by relevance (shorter words first, then alphabetically)
    suggestions.sort((a, b) {
      if (a.length != b.length) {
        return a.length.compareTo(b.length);
      }
      return a.compareTo(b);
    });

    return suggestions.take(maxSuggestions).toList();
  }

  /// Search for notes containing the given query
  List<Map<String, dynamic>> searchNotes(String query) {
    if (query.isEmpty) return [];

    Set<Map<String, dynamic>> results = {};
    List<String> queryWords = _preprocessText(query);

    // Search for each word in the query
    for (String word in queryWords) {
      if (word.isNotEmpty) {
        List<Map<String, dynamic>> wordResults = _searchWord(
          word.toLowerCase(),
        );
        results.addAll(wordResults);
      }
    }

    // Also search for the complete phrase
    List<Map<String, dynamic>> phraseResults = _searchPhrase(
      query.toLowerCase(),
    );
    results.addAll(phraseResults);

    List<Map<String, dynamic>> finalResults = results.toList();

    // Sort results by relevance score
    finalResults.sort((a, b) {
      double scoreA = _calculateRelevanceScore(a, query);
      double scoreB = _calculateRelevanceScore(b, query);
      return scoreB.compareTo(scoreA);
    });

    return finalResults;
  }

  /// Search for a specific word
  List<Map<String, dynamic>> _searchWord(String word) {
    TrieNode? node = _findNode(word);
    if (node == null || !node.isEndOfWord) return [];

    return List<Map<String, dynamic>>.from(node.noteData);
  }

  /// Search for a phrase
  List<Map<String, dynamic>> _searchPhrase(String phrase) {
    TrieNode? node = _findNode(phrase);
    if (node == null) return [];

    return List<Map<String, dynamic>>.from(node.noteData);
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

  /// Collect all possible suggestions from a node
  void _collectSuggestions(
    TrieNode node,
    String prefix,
    List<String> suggestions,
  ) {
    if (node.isEndOfWord && !suggestions.contains(prefix)) {
      suggestions.add(prefix);
    }

    if (suggestions.length >= maxSuggestions) return;

    for (String char in node.children.keys) {
      _collectSuggestions(node.children[char]!, prefix + char, suggestions);

      if (suggestions.length >= maxSuggestions) break;
    }
  }

  /// Preprocess text by removing special characters and splitting into words
  List<String> _preprocessText(String text) {
    // Remove special characters and split by whitespace
    String cleaned = text.replaceAll(RegExp(r'[^\w\s]'), ' ');
    List<String> words = cleaned.split(RegExp(r'\s+'));

    // Filter out empty strings and very short words
    return words.where((word) => word.length > 1).toList();
  }

  /// Calculate relevance score for search results
  double _calculateRelevanceScore(Map<String, dynamic> note, String query) {
    String title = note['title']?.toString().toLowerCase() ?? '';
    String content = note['content']?.toString().toLowerCase() ?? '';
    String queryLower = query.toLowerCase();

    double score = 0.0;

    // Title matches get higher score
    if (title.contains(queryLower)) {
      score += 10.0;
    }

    // Content matches
    if (content.contains(queryLower)) {
      score += 5.0;
    }

    // Exact word matches
    List<String> queryWords = _preprocessText(queryLower);
    List<String> titleWords = _preprocessText(title);
    List<String> contentWords = _preprocessText(content);

    for (String queryWord in queryWords) {
      if (titleWords.contains(queryWord)) {
        score += 3.0;
      }
      if (contentWords.contains(queryWord)) {
        score += 1.0;
      }
    }

    // Boost score for recently modified notes
    if (note.containsKey('lastModified')) {
      DateTime? lastModified = DateTime.tryParse(
        note['lastModified'].toString(),
      );
      if (lastModified != null) {
        int daysSinceModified = DateTime.now().difference(lastModified).inDays;
        if (daysSinceModified < 7) {
          score += 2.0;
        } else if (daysSinceModified < 30) {
          score += 1.0;
        }
      }
    }

    return score;
  }

  /// Get autocomplete suggestions with note count
  List<Map<String, dynamic>> getAutocompleteSuggestions(String prefix) {
    if (prefix.isEmpty) return [];

    List<String> suggestions = getSuggestions(prefix);
    List<Map<String, dynamic>> enrichedSuggestions = [];

    for (String suggestion in suggestions) {
      List<Map<String, dynamic>> notes = _searchWord(suggestion);
      enrichedSuggestions.add({
        'suggestion': suggestion,
        'noteCount': notes.length,
        'preview': notes.isNotEmpty ? notes.first['title'] ?? '' : '',
      });
    }

    return enrichedSuggestions;
  }

  /// Clear all data from the Trie
  void clear() {
    _root = TrieNode();
  }

  /// Get statistics about the Trie
  Map<String, int> getStatistics() {
    int nodeCount = 0;
    int wordCount = 0;
    Set<String> uniqueNotes = {};

    _countNodes(_root, nodeCount, wordCount, uniqueNotes);

    return {
      'totalNodes': nodeCount,
      'totalWords': wordCount,
      'uniqueNotes': uniqueNotes.length,
    };
  }

  /// Helper method to count nodes recursively
  void _countNodes(
    TrieNode node,
    int nodeCount,
    int wordCount,
    Set<String> uniqueNotes,
  ) {
    nodeCount++;

    if (node.isEndOfWord) {
      wordCount++;
      for (var note in node.noteData) {
        if (note.containsKey('id')) {
          uniqueNotes.add(note['id'].toString());
        }
      }
    }

    for (TrieNode child in node.children.values) {
      _countNodes(child, nodeCount, wordCount, uniqueNotes);
    }
  }

  /// Bulk insert multiple notes for better performance
  void bulkInsertNotes(List<Map<String, dynamic>> notes) {
    for (Map<String, dynamic> note in notes) {
      String content = '';

      // Extract content from different possible fields
      if (note.containsKey('content')) {
        content += note['content'].toString() + ' ';
      }
      if (note.containsKey('title')) {
        content += note['title'].toString() + ' ';
      }
      if (note.containsKey('tags')) {
        if (note['tags'] is List) {
          content += (note['tags'] as List).join(' ') + ' ';
        } else {
          content += note['tags'].toString() + ' ';
        }
      }

      if (content.isNotEmpty) {
        insertNote(content.trim(), note);
      }
    }
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
    _trie.clear();
    _trie.bulkInsertNotes(notes);
  }

  /// Add a single note to the search index
  void addNote(Map<String, dynamic> note) {
    String content = '';

    if (note.containsKey('content')) {
      content += note['content'].toString() + ' ';
    }
    if (note.containsKey('title')) {
      content += note['title'].toString() + ' ';
    }
    if (note.containsKey('tags')) {
      if (note['tags'] is List) {
        content += (note['tags'] as List).join(' ') + ' ';
      } else {
        content += note['tags'].toString() + ' ';
      }
    }

    if (content.isNotEmpty) {
      _trie.insertNote(content.trim(), note);
    }
  }

  /// Search for notes
  List<Map<String, dynamic>> search(String query) {
    return _trie.searchNotes(query);
  }

  /// Get suggestions for autocomplete
  List<String> getSuggestions(String prefix) {
    return _trie.getSuggestions(prefix);
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
