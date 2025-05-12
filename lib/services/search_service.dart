import '../models/bca_subjects.dart';
import '../models/search_result.dart';

class SearchService {
  // Search across all subjects in all semesters
  static List<SearchResult> searchSubjects(String query) {
    if (query.isEmpty) {
      return [];
    }

    final List<SearchResult> results = [];
    final String normalizedQuery = query.toLowerCase().trim();

    // Search through all subjects in all semesters
    BcaSubjectsData.subjectsBySemester.forEach((semester, subjects) {
      for (final subject in subjects) {
        if (subject.toLowerCase().contains(normalizedQuery)) {
          results.add(
            SearchResult(
              subject: subject,
              semester: semester,
              description: 'Semester $semester',
            ),
          );
        }
      }
    });

    return results;
  }

  // Get all subjects (for showing all subjects when search is empty)
  static List<SearchResult> getAllSubjects() {
    final List<SearchResult> allSubjects = [];

    BcaSubjectsData.subjectsBySemester.forEach((semester, subjects) {
      for (final subject in subjects) {
        allSubjects.add(
          SearchResult(
            subject: subject,
            semester: semester,
            description: 'Semester $semester',
          ),
        );
      }
    });

    return allSubjects;
  }
}
