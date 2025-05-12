import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../models/bca_subjects.dart';
import '../models/pdf_note.dart';
import 'pdf_viewer_screen.dart';

class BcaSemesterPage extends StatelessWidget {
  final int semester;
  final String notes;

  const BcaSemesterPage({
    super.key,
    required this.semester,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : Colors.blue[50]!;
    final secondaryBackgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : Colors.purple[50]!;

    // Get localizations
    final localizations = AppLocalizations.of(context);

    // Get subjects for this semester
    final List<String> semesterSubjects =
        BcaSubjectsData.subjectsBySemester[semester] ?? [];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundColor, secondaryBackgroundColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 24,
                          child: Text(
                            '$semester',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${localizations.translate('bca_semester')} $semester',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.translate('notes'),
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                color: cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: semesterSubjects.length,
                  itemBuilder: (context, index) {
                    final subject = semesterSubjects[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Icon(Icons.book, color: Colors.blue),
                      ),
                      title: Text(
                        subject,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        localizations.translate('tap_for_notes'),
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      trailing: Icon(
                        Icons.download,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue,
                      ),
                      onTap: () {
                        // Open PDF for the subject (using test.pdf for now)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PdfViewerScreen(
                                  pdfNote: PdfNote(
                                    title: subject,
                                    subject: 'Semester $semester',
                                    description: 'Notes for $subject',
                                    filename: 'test.pdf',
                                    thumbnailImage:
                                        'c.jpg', // Default thumbnail
                                  ),
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
