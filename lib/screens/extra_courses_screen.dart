import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../models/pdf_note.dart';
import '../models/firebase_note.dart';
import '../services/database_service.dart';
import 'pdf_details_screen.dart';

class ExtraCoursesScreen extends StatefulWidget {
  const ExtraCoursesScreen({super.key});

  @override
  State<ExtraCoursesScreen> createState() => _ExtraCoursesScreenState();
}

class _ExtraCoursesScreenState extends State<ExtraCoursesScreen> with AutomaticKeepAliveClientMixin {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<FirebaseNote> _extraCourses = [];
  String _errorMessage = '';
  
  @override
  bool get wantKeepAlive => false; // Don't keep this state when navigating away

  @override
  void initState() {
    super.initState();
    _fetchExtraCourses();
  }

  Future<void> _fetchExtraCourses() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _extraCourses = []; // Clear previous courses
    });

    try {
      final notes = await _databaseService.getExtraCourseNotes();
      
      if (mounted) {
        setState(() {
          _extraCourses = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load courses: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;

    // Get translations
    final localizations = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [const Color(0xFF121212), const Color(0xFF1A1A1A)]
                  : [Colors.blue[50]!, Colors.purple[50]!],
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
                          child: Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Extra Courses',
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
                      'Enhance your skills with these additional courses',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(context, cardColor, textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color cardColor, Color textColor) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: TextStyle(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchExtraCourses,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_extraCourses.isEmpty) {
      // Show empty state message instead of hardcoded fallback
      return RefreshIndicator(
        onRefresh: _fetchExtraCourses,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: textColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No extra courses available',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Extra courses will appear here once they are added.',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchExtraCourses,
      child: ListView.builder(
        itemCount: _extraCourses.length,
        itemBuilder: (context, index) {
          final course = _extraCourses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfDetailsScreen(
                      pdfNote: course.toPdfNote(),
                      firebaseNote: course,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        course.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            course.description,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDarkMode(context)
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(26),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Tap to view notes',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool isDarkMode(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
  }
}
