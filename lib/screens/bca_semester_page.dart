import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../models/firebase_note.dart';
import '../services/database_service.dart';
import 'pdf_details_screen.dart';

class BcaSemesterPage extends StatefulWidget {
  final int semester;
  final String notes;

  const BcaSemesterPage({
    super.key,
    required this.semester,
    required this.notes,
  });

  @override
  State<BcaSemesterPage> createState() => _BcaSemesterPageState();
}

class _BcaSemesterPageState extends State<BcaSemesterPage>
    with AutomaticKeepAliveClientMixin {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<FirebaseNote> _semesterNotes = [];
  String _errorMessage = '';
  String _currentSemesterString = '';

  @override
  bool get wantKeepAlive => true; // Keep state when switching semesters to improve performance

  @override
  void initState() {
    super.initState();
    _fetchSemesterNotes();
  }

  @override
  void didUpdateWidget(BcaSemesterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when semester changes
    if (oldWidget.semester != widget.semester) {
      _fetchSemesterNotes();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when dependencies change (e.g., when navigating back to this page)
    _fetchSemesterNotes();
  }

  // Convert numeric semester to ordinal format
  String _getSemesterString() {
    if (widget.semester == 1) {
      return '1st';
    } else if (widget.semester == 2) {
      return '2nd';
    } else if (widget.semester == 3) {
      return '3rd';
    } else {
      return '${widget.semester}th';
    }
  }

  Future<void> _fetchSemesterNotes() async {
    // Only set loading state if we're fetching for a different semester
    if (_currentSemesterString != _getSemesterString() ||
        _semesterNotes.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _semesterNotes = []; // Clear previous notes
      });
    }

    try {
      // Get semester string
      String semesterString = _getSemesterString();
      _currentSemesterString = semesterString;

      final notes = await _databaseService.getSemesterNotes(semesterString);

      // Only update state if we're still on the same semester
      if (_currentSemesterString == semesterString && mounted) {
        setState(() {
          _semesterNotes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load notes: $e';
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
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : Colors.blue[50]!;
    final secondaryBackgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : Colors.purple[50]!;

    // Get localizations
    final localizations = AppLocalizations.of(context);

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
                            '${widget.semester}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${localizations.translate('bca_semester')} ${widget.semester}',
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
                      widget.notes,
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildContent(context, cardColor, textColor)),
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
              onPressed: _fetchSemesterNotes,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_semesterNotes.isEmpty) {
      // Show empty state message instead of hardcoded fallback
      return RefreshIndicator(
        onRefresh: _fetchSemesterNotes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: textColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes available for this semester',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Notes will appear here once they are added.',
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
      onRefresh: _fetchSemesterNotes,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _semesterNotes.length,
        itemBuilder: (context, index) {
          final note = _semesterNotes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: cardColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PdfDetailsScreen(
                          pdfNote: note.toPdfNote(),
                          firebaseNote: note,
                        ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        note.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[300],
                            child: const Icon(Icons.description),
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
                            note.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note.category,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDarkMode(context)
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note.description,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode(context)
                                      ? Colors.grey[500]
                                      : Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.download_rounded,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to view',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
