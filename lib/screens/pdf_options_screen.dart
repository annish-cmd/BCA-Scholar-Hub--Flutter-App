import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/favorites_provider.dart';
import '../models/pdf_note.dart';
import '../models/firebase_note.dart';
import '../services/database_service.dart';
import '../utils/algo/collaborative_filtering_algorithm.dart';
import 'pdf_viewer_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import '../widgets/thumbnail_image.dart';
import 'package:http/http.dart' as http;

// Add a logger instance at the top of the file
final Logger logger = Logger();

class PdfOptionsScreen extends StatefulWidget {
  final PdfNote pdfNote;
  final FirebaseNote? firebaseNote; // Optional for direct FirebaseNote access

  const PdfOptionsScreen({
    super.key, 
    required this.pdfNote,
    this.firebaseNote,
  });

  @override
  State<PdfOptionsScreen> createState() => _PdfOptionsScreenState();
}

class _PdfOptionsScreenState extends State<PdfOptionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<FirebaseNote> _semesterNotes = []; // Rule-based recommendations
  final List<FirebaseNote> _categoryNotes = []; // Content-based recommendations
  final DatabaseService _databaseService = DatabaseService();
  final CollaborativeFilteringAlgorithm _recommendationAlgorithm = CollaborativeFilteringAlgorithm();
  bool _loadingRelated = false;
  
  // Cache for faster subsequent loads
  static List<FirebaseNote>? _cachedAllNotes;
  static DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    
    // Load related notes once when the screen is created
    String? currentSemester = widget.firebaseNote?.semester;
    String currentSubject = widget.pdfNote.subject;
    
    // Debug current note details
    logger.i('🔍 Current note details (Favorites):');
    logger.i('   Title: "${widget.pdfNote.title}"');
    logger.i('   Subject: "$currentSubject"');
    logger.i('   Semester (raw): "$currentSemester"');
    logger.i('   Firebase Note ID: "${widget.firebaseNote?.id}"');
    
    _loadRelatedNotes(currentSemester, currentSubject);
  }

  Future<void> _loadRelatedNotes(String? currentSemester, String currentSubject) async {
    if (_loadingRelated) return;
    
    setState(() {
      _loadingRelated = true;
    });
    
    try {
      logger.i('🚀 Fast loading recommendations for favorites: ${widget.pdfNote.title}');
      logger.i('📚 Original semester: "$currentSemester", Subject: "$currentSubject"');
      final stopwatch = Stopwatch()..start();
      
      // Check if this is a hardcoded PDF - if so, show other hardcoded PDFs as recommendations
      if (_isHardcodedPdf(widget.pdfNote.title)) {
        logger.i('📋 Detected hardcoded PDF: ${widget.pdfNote.title}');
        _loadHardcodedRecommendations();
        return;
      }
      
      // Check cache first for super fast loading
      List<FirebaseNote> allNotes = [];
      if (_cachedAllNotes != null && 
          _cacheTime != null && 
          DateTime.now().difference(_cacheTime!) < _cacheExpiry) {
        allNotes = _cachedAllNotes!;
        logger.i('⚡ Using cached notes (${allNotes.length} notes) - ${stopwatch.elapsedMilliseconds}ms');
      } else {
        // Fast parallel fetching - only fetch what we need
        logger.i('📡 Fetching fresh data for favorites...');
        
        // Priority 1: Current semester + adjacent semesters (for speed)
        final prioritySemesters = _getPrioritySemesters(currentSemester ?? '1st');
        
        // Priority 2: Extra courses
        final futures = <Future<List<FirebaseNote>>>[];
        
        // Fetch priority semesters in parallel
        logger.i('🔄 Fetching semesters: $prioritySemesters');
        for (String semester in prioritySemesters) {
          futures.add(_databaseService.getSemesterNotes(semester));
        }
        
        // Fetch extra courses in parallel
        futures.add(_databaseService.getExtraCourseNotes());
        
        // Execute all fetches in parallel
        final results = await Future.wait(futures, eagerError: false);
        
        // Combine results with detailed logging
        for (int i = 0; i < results.length; i++) {
          final result = results[i];
          if (i < prioritySemesters.length) {
            logger.i('📚 ${prioritySemesters[i]} semester: ${result.length} notes');
          } else {
            logger.i('🎓 Extra courses: ${result.length} notes');
          }
          allNotes.addAll(result);
        }
        
        // Cache for next time
        _cachedAllNotes = allNotes;
        _cacheTime = DateTime.now();
        
        logger.i('⚡ Fetched ${allNotes.length} notes in ${stopwatch.elapsedMilliseconds}ms');
      }
      
      // Fast hybrid processing
      if (allNotes.isNotEmpty && widget.firebaseNote != null) {
        // Normalize the current semester - if empty/null, treat as extra course
        String normalizedCurrentSemester = currentSemester ?? '';
        if (normalizedCurrentSemester.isEmpty || 
            normalizedCurrentSemester.toLowerCase().contains('extra') ||
            normalizedCurrentSemester == 'null') {
          normalizedCurrentSemester = 'extra';
        }
        
        logger.i('🔧 Normalized semester: "$normalizedCurrentSemester" (from "$currentSemester")');
        
        final recommendations = _recommendationAlgorithm.getHybridRecommendations(
          allNotes: allNotes,
          currentUserSemester: normalizedCurrentSemester,
          currentlyViewingNote: widget.firebaseNote,
          maxSuggestions: 20, // Increased for more recommendations
        );
        
        final semesterRecommendations = recommendations['semester_notes'] ?? [];
        final contentBasedRecommendations = recommendations['you_might_like'] ?? [];
        
        if (mounted) {
          setState(() {
            _semesterNotes.clear();
            _categoryNotes.clear();
            
            // Rule-based: Semester notes (up to 5) - exclude current note
            final filteredSemesterNotes = semesterRecommendations.where((note) {
              return note.id != widget.firebaseNote?.id && note.title != widget.pdfNote.title;
            }).take(5);
            _semesterNotes.addAll(filteredSemesterNotes);
            
            // Content-based: Show ALL available notes in same category - exclude current note
            final filteredCategoryNotes = contentBasedRecommendations.where((note) {
              return note.id != widget.firebaseNote?.id && note.title != widget.pdfNote.title;
            });
            _categoryNotes.addAll(filteredCategoryNotes); // No limit - show all
            
            _loadingRelated = false;
          });
          
          stopwatch.stop();
          logger.i('✅ Total loading time: ${stopwatch.elapsedMilliseconds}ms');
          logger.i('📊 Loaded ${_semesterNotes.length} semester + ${_categoryNotes.length} category notes');
        }
      } else {
        // Fast fallback
        final quickRecommendations = _getQuickRecommendations(allNotes, currentSemester, currentSubject);
        
        if (mounted) {
          setState(() {
            _semesterNotes.clear();
            _categoryNotes.clear();
            
            // Filter out current note from quick recommendations
            final filteredQuickRecs = quickRecommendations.where((note) {
              return note.id != widget.firebaseNote?.id && note.title != widget.pdfNote.title;
            }).toList();
            
            _semesterNotes.addAll(filteredQuickRecs.take(5));
            _categoryNotes.addAll(filteredQuickRecs.skip(5)); // Show all remaining
            _loadingRelated = false;
          });
          
          stopwatch.stop();
          logger.i('⚡ Fast fallback completed in ${stopwatch.elapsedMilliseconds}ms');
        }
      }
      
    } catch (e) {
      logger.e('❌ Fast loading failed: $e');
      
      // Ultra-fast emergency fallback
      if (mounted) {
        setState(() {
          _loadingRelated = false;
        });
      }
    }
  }

  // Get priority semesters for faster loading
  List<String> _getPrioritySemesters(String currentSemester) {
    final allSemesters = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'];
    final priorityList = <String>[];
    
    logger.i('🎯 Building priority list for semester: "$currentSemester"');
    
    // Add current semester first
    priorityList.add(currentSemester);
    
    // Add adjacent semesters
    final currentIndex = allSemesters.indexOf(currentSemester);
    logger.i('📍 Current semester index: $currentIndex for "$currentSemester"');
    
    if (currentIndex > 0) {
      priorityList.add(allSemesters[currentIndex - 1]);
      logger.i('➕ Added previous semester: ${allSemesters[currentIndex - 1]}');
    }
    if (currentIndex < allSemesters.length - 1) {
      priorityList.add(allSemesters[currentIndex + 1]);
      logger.i('➕ Added next semester: ${allSemesters[currentIndex + 1]}');
    }
    
    // Add remaining semesters
    for (String semester in allSemesters) {
      if (!priorityList.contains(semester)) {
        priorityList.add(semester);
      }
    }
    
    final finalList = priorityList.take(8).toList(); // Fetch all semesters for debugging
    logger.i('🎯 Final priority list: $finalList');
    return finalList;
  }

  // Check if the PDF is one of the 4 hardcoded PDFs
  bool _isHardcodedPdf(String title) {
    final hardcodedTitles = [
      'C Programming Notes',
      'Java Basics', 
      'Flutter Tutorial',
      'Python for Beginners'
    ];
    return hardcodedTitles.any((hardcodedTitle) => 
        title.toLowerCase().contains(hardcodedTitle.toLowerCase()) ||
        hardcodedTitle.toLowerCase().contains(title.toLowerCase()));
  }

  // Load recommendations for hardcoded PDFs
  void _loadHardcodedRecommendations() {
    // Define the 4 hardcoded PDFs with their details
    final List<Map<String, String>> hardcodedPdfs = [
      {
        'title': 'C Programming Notes',
        'subject': 'Programming',
        'description': 'Complete C programming guide with examples and exercises.',
        'filename': 'c_programming.pdf',
        'image': 'c.jpg'
      },
      {
        'title': 'Java Basics',
        'subject': 'Programming', 
        'description': 'Introduction to Java programming fundamentals.',
        'filename': 'java_basics.pdf',
        'image': 'java.jpg'
      },
      {
        'title': 'Flutter Tutorial',
        'subject': 'Mobile Development',
        'description': 'Learn Flutter mobile app development from scratch.',
        'filename': 'flutter_tutorial.pdf', 
        'image': 'flutter.png'
      },
      {
        'title': 'Python for Beginners',
        'subject': 'Programming',
        'description': 'Python programming basics for beginners.',
        'filename': 'python_beginners.pdf',
        'image': 'Python.jpg'
      }
    ];

    // Create PdfNote objects and filter out the current one
    final List<PdfNote> otherHardcodedPdfs = hardcodedPdfs
        .where((pdf) => pdf['title'] != widget.pdfNote.title)
        .map((pdf) => PdfNote(
          id: pdf['title']!.replaceAll(' ', '_').toLowerCase(),
          title: pdf['title']!,
          subject: pdf['subject']!,
          description: pdf['description']!,
          filename: pdf['filename']!,
          thumbnailImage: pdf['image']!,
        ))
        .toList();

    if (mounted) {
      setState(() {
        _semesterNotes.clear();
        _categoryNotes.clear();
        
        // For hardcoded PDFs, put all other hardcoded PDFs in "You Might Also Like"  
        _categoryNotes.addAll(otherHardcodedPdfs.map((pdfNote) => FirebaseNote(
          id: pdfNote.id,
          title: pdfNote.title,
          description: pdfNote.description,
          category: pdfNote.subject,
          semester: 'Hardcoded',
          imageUrl: pdfNote.thumbnailImage,
          documentUrl: pdfNote.filename,
          type: 'pdf',
          fileName: pdfNote.filename,
          fileExtension: 'pdf',
          fileSize: 1024000, // 1MB default
          storagePath: 'assets/pdfs/${pdfNote.filename}',
          storageProvider: 'local',
          uploadedAt: DateTime.now().millisecondsSinceEpoch,
          uploadedBy: 'System',
        )));
        
        _loadingRelated = false;
      });
      
      logger.i('✅ Loaded ${_categoryNotes.length} hardcoded recommendations');
    }
  }

  // Quick recommendations for fallback
  List<FirebaseNote> _getQuickRecommendations(List<FirebaseNote> allNotes, String? currentSemester, String currentSubject) {
    return allNotes.where((note) {
      return note.id != widget.firebaseNote?.id && 
             note.title != widget.pdfNote.title &&
             (note.semester == currentSemester ||
              note.category.toLowerCase().contains(currentSubject.toLowerCase()) ||
              currentSubject.toLowerCase().contains(note.category.toLowerCase()));
    }).toList(); // No limit - return all matching notes
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final Size screenSize = MediaQuery.of(context).size;

    // Get favorite status from provider
    final bool isFavorite = favoritesProvider.isFavorite(widget.pdfNote.id);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDarkMode
                    ? [const Color(0xFF1A1A1A), const Color(0xFF121212)]
                    : [Colors.blue[50]!, Colors.purple[50]!],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App bar with back button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: textColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.pdfNote.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Content area
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Document preview
                    Center(
                      child: Hero(
                        tag: 'pdf_${widget.pdfNote.filename}',
                        child: Container(
                          width: screenSize.width * 0.5,
                          height: screenSize.width * 0.5,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[850] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(51),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ThumbnailImage(
                                    imageUrl: widget.pdfNote.thumbnailImage,
                                    fit: BoxFit.cover,
                                    isDarkMode: isDarkMode,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withAlpha(179),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.pdfNote.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        widget.pdfNote.subject,
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(204),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(153),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'PDF',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? Colors.grey[850]!.withAlpha(128)
                                : Colors.white.withAlpha(179),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.pdfNote.description,
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Options section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? Colors.black.withAlpha(77)
                                : Colors.white.withAlpha(128),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isDarkMode
                                  ? Colors.grey.withAlpha(51)
                                  : Colors.white.withAlpha(204),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Options',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildActionButton(
                                icon: Icons.visibility,
                                label: 'View',
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PdfViewerScreen(
                                            pdfNote: widget.pdfNote,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.share,
                                label: 'Share',
                                color: Colors.green,
                                onTap: () {
                                  _sharePdf();
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.download,
                                label: 'Download',
                                color: Colors.orange,
                                onTap: () {
                                  _downloadPdf();
                                },
                              ),
                              _buildActionButton(
                                icon:
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                label: 'Favorite',
                                color: Colors.red,
                                onTap: () {
                                  // Use the provider to toggle favorite
                                  favoritesProvider.toggleFavorite(
                                    widget.pdfNote.id,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        favoritesProvider.isFavorite(
                                              widget.pdfNote.id,
                                            )
                                            ? 'Added to favorites'
                                            : 'Removed from favorites',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Rule-Based Section - Semester Recommendations
                    _buildRecommendationSection(
                      title: '📚 Same Semester Notes',
                      notes: _semesterNotes,
                      isDarkMode: isDarkMode,
                      textColor: textColor,
                      emptyMessage: 'No semester notes found.',
                    ),

                    const SizedBox(height: 16),

                    // Content-Based Section - Category Recommendations
                    _buildRecommendationSection(
                      title: '🎯 You Might Also Like',
                      notes: _categoryNotes,
                      isDarkMode: isDarkMode,
                      textColor: textColor,
                      emptyMessage: 'No similar notes found.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(77), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Build recommendation section widget
  Widget _buildRecommendationSection({
    required String title,
    required List<FirebaseNote> notes,
    required bool isDarkMode,
    required Color textColor,
    required String emptyMessage,
  }) {
    return SizedBox(
      height: 190,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.black.withAlpha(77)
              : Colors.white.withAlpha(128),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.grey.withAlpha(51)
                : Colors.white.withAlpha(204),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loadingRelated && notes.isEmpty
                  ? Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.blue[300]! : Colors.blue,
                          ),
                        ),
                      ),
                    )
                  : notes.isEmpty
                      ? Center(
                          child: Text(
                            emptyMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: _buildRelatedSubjectCards(notes, isDarkMode),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRelatedSubjectCards(List<FirebaseNote> notes, bool isDarkMode) {
    if (notes.isEmpty) {
      return [];
    }
    return notes.map((note) {
      return Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: GestureDetector(
          onTap: () {
            // Check if this is a hardcoded PDF recommendation
            if (note.semester == 'Hardcoded') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfOptionsScreen(
                    pdfNote: note.toPdfNote(),
                    firebaseNote: null, // No Firebase data for hardcoded PDFs
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfOptionsScreen(
                    pdfNote: note.toPdfNote(),
                    firebaseNote: note,
                  ),
                ),
              );
            }
          },
          child: Container(
            width: 110,
            height: 150,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isDarkMode ? Colors.grey.withAlpha(51) : Colors.grey.withAlpha(77),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Image section (smaller fixed height)
                SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: ThumbnailImage(
                      imageUrl: note.imageUrl,
                      fit: BoxFit.cover,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ),
                // Title section only (no description)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black.withAlpha(51) : Colors.grey.withAlpha(26),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        note.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // Share PDF function
  Future<void> _sharePdf() async {
    try {
      // Get the asset path for the PDF
      final String assetPath = 'assets/pdfs/${widget.pdfNote.filename}';
      final ByteData bytes = await rootBundle.load(assetPath);

      // Create share message with BCA Scholar Hub source
      final String shareMessage =
          'Notes from BCA Scholar Hub\n\n'
          'Title: ${widget.pdfNote.title}\n'
          'Subject: ${widget.pdfNote.subject}\n'
          'Description: ${widget.pdfNote.description}';

      try {
        // Primary method - use path_provider to get external storage directory
        final Directory? downloadDir = await getExternalStorageDirectory();
        if (downloadDir != null) {
          final String filePath =
              '${downloadDir.path}/${widget.pdfNote.filename}';
          final File file = File(filePath);
          await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

          // Share the file with Share.shareXFiles - shows all apps
          await Share.shareXFiles(
            [XFile(filePath)],
            text: shareMessage,
            subject: 'BCA Scholar Hub - ${widget.pdfNote.title}',
          );
          return;
        }
      } catch (e) {
        logger.d('External storage error: $e');
      }

      try {
        // Secondary method - use application documents directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String appDocPath =
            '${appDocDir.path}/${widget.pdfNote.filename}';
        final File appDocFile = File(appDocPath);
        await appDocFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

        // Share from application documents directory
        await Share.shareXFiles(
          [XFile(appDocPath)],
          text: shareMessage,
          subject: 'BCA Scholar Hub - ${widget.pdfNote.title}',
        );
        return;
      } catch (e) {
        logger.d('Application documents directory error: $e');
      }

      try {
        // Tertiary method - use temporary directory
        final Directory tempDir = await getTemporaryDirectory();
        final String tempPath = '${tempDir.path}/${widget.pdfNote.filename}';
        final File tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

        // Share from temporary directory
        await Share.shareXFiles(
          [XFile(tempPath)],
          text: shareMessage,
          subject: 'BCA Scholar Hub - ${widget.pdfNote.title}',
        );
        return;
      } catch (e) {
        logger.d('Temporary directory error: $e');
      }

      // Final fallback - share just text if all file methods fail
      await Share.share(
        shareMessage,
        subject: 'BCA Scholar Hub - ${widget.pdfNote.title}',
      );
    } catch (e) {
      // Show error message with more details for debugging
      logger.d('Sharing error details: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Download button functionality
  Future<void> _downloadPdf() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final accentColor = isDarkMode ? Colors.blue[400]! : Colors.blue;

    // Show confirmation dialog
    bool? shouldDownload = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 6,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title with icon
                Row(
                  children: [
                    Icon(Icons.download_rounded, color: accentColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Download PDF',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Confirmation message
                Text(
                  'This will download the PDF to your device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor.withAlpha(179),
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color:
                                  isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Download',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDownload != true) {
      return; // User canceled the download
    }

    // Actual download implementation
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Download started...')));
  }
}
