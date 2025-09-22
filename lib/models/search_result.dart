import 'firebase_note.dart';

class SearchResult {
  final String subject;
  final int semester;
  final String? description;
  final FirebaseNote? firebaseNote; // Add Firebase note data

  SearchResult({
    required this.subject,
    required this.semester,
    this.description,
    this.firebaseNote,
  });

  // Factory constructor to create SearchResult from FirebaseNote
  factory SearchResult.fromFirebaseNote(FirebaseNote note) {
    // Extract semester from note data
    int semesterNumber = 1; // Default
    if (note.semester != null) {
      String semesterStr = note.semester!.toLowerCase();
      // Extract number from semester string like "1st", "2nd", etc.
      RegExp regExp = RegExp(r'(\d+)');
      Match? match = regExp.firstMatch(semesterStr);
      if (match != null) {
        semesterNumber = int.tryParse(match.group(1)!) ?? 1;
      }
    }

    return SearchResult(
      subject: note.title,
      semester: semesterNumber,
      description: note.description.isNotEmpty ? note.description : 'Semester $semesterNumber',
      firebaseNote: note,
    );
  }
}
