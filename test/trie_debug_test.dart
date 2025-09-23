import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/encryption/algorithms/trie_search_algorithm.dart';

void main() {
  group('Trie Search Debug Tests', () {
    test('Debug single character "e" search with typical BCA titles', () {
      final trie = TrieSearchAlgorithm();

      // Sample titles that might contain 'e'
      final testNotes = [
        {
          'id': '1',
          'title': 'Computer Science',
          'category': 'Core Subject',
          'semester': '1st',
        },
        {
          'id': '2',
          'title': 'Mathematics',
          'category': 'Core Subject',
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
          'title': 'Data Structures',
          'category': 'Programming',
          'semester': '2nd',
        },
        {
          'id': '5',
          'title': 'Database Management',
          'category': 'Database',
          'semester': '3rd',
        },
        {
          'id': '6',
          'title': 'Software Engineering',
          'category': 'Engineering',
          'semester': '4th',
        },
        {
          'id': '7',
          'title': 'Web Development',
          'category': 'Web',
          'semester': '5th',
        },
        {
          'id': '8',
          'title': 'Network Security',
          'category': 'Security',
          'semester': '6th',
        },
      ];

      // Insert all notes
      for (var note in testNotes) {
        print('Inserting: ${note['title']}');
        trie.insertNote(note['title'] as String, note);
      }

      // Get statistics
      Map<String, int> stats = trie.getStatistics();
      print('Trie Statistics: $stats');

      // Test search for 'e'
      print('\n--- Testing search for "e" ---');
      var results = trie.searchNotes('e');
      print('Search results for "e": ${results.length}');
      
      for (var result in results) {
        print('  - ${result['title']}');
      }

      // Test suggestions for 'e'
      print('\n--- Testing suggestions for "e" ---');
      var suggestions = trie.getSuggestions('e');
      print('Suggestions for "e": ${suggestions.length}');
      
      for (var suggestion in suggestions) {
        print('  - $suggestion');
      }

      // Manual verification - which titles should contain 'e'?
      print('\n--- Manual verification ---');
      List<String> expectedTitles = [];
      for (var note in testNotes) {
        String title = note['title'] as String;
        if (title.toLowerCase().contains('e')) {
          expectedTitles.add(title);
        }
      }
      print('Expected titles containing "e": ${expectedTitles.length}');
      for (String title in expectedTitles) {
        print('  - $title');
      }

      // Assertions
      expect(results.isNotEmpty, true, reason: 'Should find titles containing "e"');
      expect(results.length, greaterThanOrEqualTo(6), reason: 'Should find at least 6 titles with "e"');
      
      // Check specific expected results
      expect(results.any((r) => r['title'] == 'Computer Science'), true);
      expect(results.any((r) => r['title'] == 'Mathematics'), true);
      expect(results.any((r) => r['title'] == 'English'), true);
      expect(results.any((r) => r['title'] == 'Data Structures'), true);
      expect(results.any((r) => r['title'] == 'Database Management'), true);
      expect(results.any((r) => r['title'] == 'Software Engineering'), true);
      expect(results.any((r) => r['title'] == 'Web Development'), true);
      expect(results.any((r) => r['title'] == 'Network Security'), true);
    });

    test('Debug trie node structure for character "e"', () {
      final trie = TrieSearchAlgorithm();

      // Insert a simple title containing 'e'
      trie.insertNote('Test Subject', {
        'id': '1',
        'title': 'Test Subject',
        'category': 'Test',
      });

      // Test direct node access for 'e'
      var results = trie.searchNotes('e');
      print('Results for "e" after inserting "Test Subject": ${results.length}');
      
      for (var result in results) {
        print('  - ${result['title']}');
      }

      expect(results.isNotEmpty, true);
      expect(results.any((r) => r['title'] == 'Test Subject'), true);
    });

    test('Debug strategy breakdown for "e" search', () {
      final trie = TrieSearchAlgorithm();

      // Insert test data
      trie.insertNote('English', {
        'id': '1',
        'title': 'English',
        'category': 'Language',
      });

      // Test each strategy separately by examining the search method logic
      String query = 'e';
      String normalizedQuery = query.toLowerCase().trim();
      
      print('Testing normalized query: "$normalizedQuery"');
      
      // Test the full search
      var results = trie.searchNotes(query);
      print('Full search results: ${results.length}');
      
      expect(results.isNotEmpty, true);
      expect(results.first['title'], 'English');
    });
  });
}