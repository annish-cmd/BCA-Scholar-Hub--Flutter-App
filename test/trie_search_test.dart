import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/algo/trie_search_algorithm.dart';

void main() {
  group('TrieSearchAlgorithm Tests', () {
    late TrieSearchAlgorithm trie;

    setUp(() {
      trie = TrieSearchAlgorithm();
    });

    test('should insert and search single character', () {
      // Test data with sample BCA subjects
      final testNotes = [
        {
          'id': '1',
          'title': 'Mathematics',
          'category': 'Core Subject',
          'semester': '1st',
        },
        {
          'id': '2',
          'title': 'Programming in C',
          'category': 'Programming',
          'semester': '1st',
        },
        {
          'id': '3',
          'title': 'English',
          'category': 'Language',
          'semester': '1st',
        },
        {
          'id': '4',
          'title': 'Computer Architecture',
          'category': 'Hardware',
          'semester': '2nd',
        },
        {
          'id': '5',
          'title': 'Data Structures',
          'category': 'Programming',
          'semester': '2nd',
        },
      ];

      // Insert notes
      for (var note in testNotes) {
        trie.insertNote(note['title'] as String, note);
      }

      // Test single character search - 'M' should find 'Mathematics'
      var results = trie.searchNotes('m');
      expect(results.isNotEmpty, true);
      expect(results.any((r) => r['title'] == 'Mathematics'), true);

      // Test single character search - 'P' should find 'Programming in C'
      results = trie.searchNotes('p');
      expect(results.isNotEmpty, true);
      expect(results.any((r) => r['title'] == 'Programming in C'), true);

      // Test single character search - 'E' should find 'English'
      results = trie.searchNotes('e');
      expect(results.isNotEmpty, true);
      expect(results.any((r) => r['title'] == 'English'), true);
    });

    test('should provide suggestions for single letters', () {
      // Insert test data
      final testNotes = [
        {'id': '1', 'title': 'Mathematics', 'category': 'Core'},
        {'id': '2', 'title': 'Machine Learning', 'category': 'AI'},
        {'id': '3', 'title': 'Mobile Development', 'category': 'Programming'},
        {'id': '4', 'title': 'Programming in C', 'category': 'Programming'},
        {'id': '5', 'title': 'Python Programming', 'category': 'Programming'},
      ];

      for (var note in testNotes) {
        trie.insertNote(note['title'] as String, note);
      }

      // Test suggestions for single letter 'M'
      var suggestions = trie.getSuggestions('m');
      expect(suggestions.isNotEmpty, true);
      expect(suggestions.contains('mathematics'), true);
      expect(suggestions.contains('machine learning'), true);
      expect(suggestions.contains('mobile development'), true);

      // Test suggestions for single letter 'P'
      suggestions = trie.getSuggestions('p');
      expect(suggestions.isNotEmpty, true);
      expect(suggestions.contains('programming in c'), true);
      expect(suggestions.contains('python programming'), true);
    });

    test('should work with partial words', () {
      // Insert test data
      final testNotes = [
        {'id': '1', 'title': 'Computer Science', 'category': 'Core'},
        {'id': '2', 'title': 'Computer Graphics', 'category': 'Graphics'},
        {'id': '3', 'title': 'Software Engineering', 'category': 'Engineering'},
        {'id': '4', 'title': 'Database Management', 'category': 'Database'},
      ];

      for (var note in testNotes) {
        trie.insertNote(note['title'] as String, note);
      }

      // Test partial word search
      var results = trie.searchNotes('comp');
      expect(results.length, 2); // Should find both Computer titles
      expect(results.any((r) => r['title'] == 'Computer Science'), true);
      expect(results.any((r) => r['title'] == 'Computer Graphics'), true);

      // Test suggestions for partial word
      var suggestions = trie.getSuggestions('comp');
      expect(suggestions.isNotEmpty, true);
      expect(suggestions.contains('computer science'), true);
      expect(suggestions.contains('computer graphics'), true);
    });

    test('should handle case-insensitive search', () {
      // Insert test data
      final testNote = {
        'id': '1',
        'title': 'JavaScript Programming',
        'category': 'Web Development',
      };

      trie.insertNote(testNote['title'] as String, testNote);

      // Test case-insensitive search
      var results1 = trie.searchNotes('javascript');
      var results2 = trie.searchNotes('JAVASCRIPT');
      var results3 = trie.searchNotes('JavaScript');
      var results4 = trie.searchNotes('j');

      expect(results1.isNotEmpty, true);
      expect(results2.isNotEmpty, true);
      expect(results3.isNotEmpty, true);
      expect(results4.isNotEmpty, true);

      expect(results1.first['title'], 'JavaScript Programming');
      expect(results2.first['title'], 'JavaScript Programming');
      expect(results3.first['title'], 'JavaScript Programming');
      expect(results4.first['title'], 'JavaScript Programming');
    });

    test('should rank results by relevance', () {
      // Insert test data where some titles start with query and others contain it
      final testNotes = [
        {'id': '1', 'title': 'Data Structures', 'category': 'Programming'},
        {'id': '2', 'title': 'Database Management', 'category': 'Database'},
        {'id': '3', 'title': 'Advanced Data Mining', 'category': 'Analytics'},
        {'id': '4', 'title': 'Big Data Analytics', 'category': 'Analytics'},
      ];

      for (var note in testNotes) {
        trie.insertNote(note['title'] as String, note);
      }

      // Search for 'data'
      var results = trie.searchNotes('data');
      expect(results.isNotEmpty, true);

      // Results starting with 'data' should come first
      var firstResult = results.first;
      expect(firstResult['title'], anyOf('Data Structures', 'Database Management'));
    });

    test('should provide autocomplete suggestions with metadata', () {
      // Insert test data
      final testNotes = [
        {
          'id': '1',
          'title': 'Web Development',
          'category': 'Frontend',
          'semester': '3rd',
          'type': 'pdf'
        },
        {
          'id': '2',
          'title': 'Web Design',
          'category': 'Design',
          'semester': '2nd',
          'type': 'pdf'
        },
      ];

      for (var note in testNotes) {
        trie.insertNote(note['title'] as String, note);
      }

      // Test autocomplete suggestions
      var suggestions = trie.getAutocompleteSuggestions('web');
      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first.containsKey('suggestion'), true);
      expect(suggestions.first.containsKey('noteCount'), true);
      expect(suggestions.first.containsKey('preview'), true);
    });

    test('should clear data properly', () {
      // Insert test data
      final testNote = {
        'id': '1',
        'title': 'Test Subject',
        'category': 'Test',
      };

      trie.insertNote(testNote['title'] as String, testNote);

      // Verify data exists
      var results = trie.searchNotes('test');
      expect(results.isNotEmpty, true);

      // Clear and verify empty
      trie.clear();
      results = trie.searchNotes('test');
      expect(results.isEmpty, true);

      var suggestions = trie.getSuggestions('test');
      expect(suggestions.isEmpty, true);
    });

    test('should handle empty and special cases', () {
      // Test empty search
      var results = trie.searchNotes('');
      expect(results.isEmpty, true);

      var suggestions = trie.getSuggestions('');
      expect(suggestions.isEmpty, true);

      // Test non-existent search
      results = trie.searchNotes('nonexistent');
      expect(results.isEmpty, true);

      suggestions = trie.getSuggestions('nonexistent');
      expect(suggestions.isEmpty, true);
    });
  });

  group('TrieSearchService Tests', () {
    test('should initialize and search correctly', () async {
      final service = TrieSearchService();
      
      // Test data
      final testNotes = [
        {
          'id': '1',
          'title': 'Artificial Intelligence',
          'category': 'AI',
          'semester': '6th',
        },
        {
          'id': '2',
          'title': 'Machine Learning',
          'category': 'AI',
          'semester': '7th',
        },
      ];

      // Initialize service
      await service.initialize(testNotes);

      // Test search
      var results = service.search('artificial');
      expect(results.isNotEmpty, true);
      expect(results.first['title'], 'Artificial Intelligence');

      // Test single letter search
      results = service.search('a');
      expect(results.isNotEmpty, true);
      expect(results.any((r) => r['title'] == 'Artificial Intelligence'), true);

      // Test suggestions
      var suggestions = service.getSuggestions('machine');
      expect(suggestions.isNotEmpty, true);
      expect(suggestions.contains('machine learning'), true);
    });
  });
}