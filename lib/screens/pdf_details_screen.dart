import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/favorites_provider.dart';
import '../models/pdf_note.dart';
import '../models/firebase_note.dart';
import '../services/database_service.dart';
import 'pdf_viewer_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

// Add a logger instance at the top of the file
final Logger logger = Logger();

class PdfDetailsScreen extends StatefulWidget {
  final PdfNote pdfNote;
  final FirebaseNote? firebaseNote; // Optional for direct FirebaseNote access

  const PdfDetailsScreen({
    super.key, 
    required this.pdfNote,
    this.firebaseNote,
  });

  @override
  State<PdfDetailsScreen> createState() => _PdfDetailsScreenState();
}

class _PdfDetailsScreenState extends State<PdfDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<FirebaseNote> _relatedNotes = [];
  final DatabaseService _databaseService = DatabaseService();
  bool _loadingRelated = false;

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
    _loadRelatedNotes(currentSemester, currentSubject);
  }
  
  Future<void> _loadRelatedNotes(String? currentSemester, String currentSubject) async {
    if (_loadingRelated) return;
    
    setState(() {
      _loadingRelated = true;
    });
    
    try {
      List<FirebaseNote> notes = [];
      
      // If we have a semester, prioritize notes from the same semester
      if (currentSemester != null) {
        notes = await _databaseService.getSemesterNotes(currentSemester);
        
        // Filter out the current note
        notes = notes.where((note) => 
          note.id != widget.firebaseNote?.id && 
          note.title != widget.pdfNote.title
        ).toList();
      }
      
      // If we have fewer than 3 notes, add extra courses
      final extraNotes = await _databaseService.getExtraCourseNotes();
      for (var note in extraNotes) {
        if (notes.length < 3 && 
            !notes.any((n) => n.id == note.id) && 
            note.id != widget.firebaseNote?.id &&
            note.title != widget.pdfNote.title) {
          notes.add(note);
        }
      }
      
      // Update the state if still mounted
      if (mounted) {
        setState(() {
          _relatedNotes.clear();
          _relatedNotes.addAll(notes.take(3));
          _loadingRelated = false;
        });
      }
    } catch (e) {
      logger.d('Error loading related notes: $e');
      if (mounted) {
        setState(() {
          _loadingRelated = false;
        });
      }
    }
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
                        tag: 'pdf_${widget.pdfNote.id}',
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
                                  child: _buildImage(widget.pdfNote.thumbnailImage),
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

                    // Related section - fixed height, horizontal scroll
                    SizedBox(
                      height: 190,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
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
                              'Related Subjects',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _loadingRelated && _relatedNotes.isEmpty
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
                                  : _relatedNotes.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No related notes found.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                            ),
                                          ),
                                        )
                                      : ListView(
                                          scrollDirection: Axis.horizontal,
                                          physics: const BouncingScrollPhysics(),
                                          children: _buildRelatedSubjectCards(isDarkMode),
                                        ),
                            ),
                          ],
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
  }

  // Helper method to build image from URL or asset
  Widget _buildImage(String imageSource) {
    // Check if the image source is a URL
    final bool isUrl = imageSource.startsWith('http://') || 
                      imageSource.startsWith('https://');
    
    if (isUrl) {
      return Image.network(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50),
          );
        },
      );
    } else {
      // If not a URL, try to load from assets
      return Image.asset(
        'assets/images/$imageSource',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, size: 50),
          );
        },
      );
    }
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

  List<Widget> _buildRelatedSubjectCards(bool isDarkMode) {
    // Remove call to _loadRelatedNotes from here
    if (_relatedNotes.isEmpty) {
      return [];
    }
    return _relatedNotes.map((note) {
      return Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfDetailsScreen(
                  pdfNote: note.toPdfNote(),
                  firebaseNote: note,
                ),
              ),
            );
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
                    child: _buildImage(note.imageUrl),
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
      String? pdfUrl;
      
      // Check if we have a Firebase note with a direct document URL
      if (widget.firebaseNote != null && widget.firebaseNote!.documentUrl.isNotEmpty) {
        pdfUrl = widget.firebaseNote!.documentUrl;
      } else if (widget.pdfNote.filename.startsWith('http')) {
        // Otherwise use the filename if it's a URL
        pdfUrl = widget.pdfNote.filename;
      }
      
      // Create share message
      final String shareMessage =
          'Notes from BCA Scholar Hub\n\n'
          'Title: ${widget.pdfNote.title}\n'
          'Subject: ${widget.pdfNote.subject}\n'
          'Description: ${widget.pdfNote.description}';
      
      if (pdfUrl != null) {
        try {
          // Download the file from URL
          final response = await http.get(Uri.parse(pdfUrl));
          
          if (response.statusCode == 200) {
            // Get temporary directory to store the file
            final tempDir = await getTemporaryDirectory();
            final fileName = pdfUrl.split('/').last;
            final filePath = '${tempDir.path}/$fileName';
            
            // Write file to temporary directory
            final file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);
            
            // Share the file
            await Share.shareXFiles(
              [XFile(filePath)],
              text: shareMessage,
              subject: 'BCA Scholar Hub - ${widget.pdfNote.title}',
            );
            return;
          }
        } catch (e) {
          logger.d('Error downloading file: $e');
        }
        
        // If file download or sharing failed, share the URL instead
        await Share.share(
          '$shareMessage\n\nDownload link: $pdfUrl',
          subject: 'BCA Scholar Hub - ${widget.pdfNote.title}',
        );
        return;
      }
      
      // If no URL available, try to get the asset file
      try {
        final String assetPath = 'assets/pdfs/${widget.pdfNote.filename}';
        final ByteData bytes = await rootBundle.load(assetPath);
        
        // Save asset to temporary file
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/${widget.pdfNote.filename}';
        final file = File(filePath);
        await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
        
        // Share the file
        await Share.shareXFiles(
          [XFile(filePath)],
          text: shareMessage,
          subject: 'BCA Scholar Hub - ${widget.pdfNote.title}',
        );
        return;
      } catch (e) {
        logger.d('Asset sharing error: $e');
      }
      
      // Fallback - share just text if all file methods fail
      await Share.share(
        shareMessage,
        subject: 'BCA Scholar Hub - ${widget.pdfNote.title}',
      );
    } catch (e) {
      // Show error message
      logger.d('Sharing error: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error sharing PDF. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Download PDF function
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Download',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
      return;
    }

    // After confirmation, try to download
    try {
      String? pdfUrl;
      
      // Get the URL from Firebase note or from PdfNote
      if (widget.firebaseNote != null && widget.firebaseNote!.documentUrl.isNotEmpty) {
        pdfUrl = widget.firebaseNote!.documentUrl;
      } else if (widget.pdfNote.filename.startsWith('http')) {
        pdfUrl = widget.pdfNote.filename;
      }
      
      if (pdfUrl != null) {
        // Try to download from URL to Downloads folder
        try {
          final response = await http.get(Uri.parse(pdfUrl));
          
          if (response.statusCode == 200) {
            final directory = await getExternalStorageDirectory();
            if (directory != null) {
              final fileName = pdfUrl.split('/').last;
              final filePath = '${directory.path}/$fileName';
              
              final file = File(filePath);
              await file.writeAsBytes(response.bodyBytes);
              
              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF saved to ${directory.path}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }
          }
        } catch (e) {
          logger.d('Download error: $e');
        }
      } else {
        // If no URL available, try to save the asset file
        try {
          final String assetPath = 'assets/pdfs/${widget.pdfNote.filename}';
          final ByteData bytes = await rootBundle.load(assetPath);
          
          final directory = await getExternalStorageDirectory();
          if (directory != null) {
            final filePath = '${directory.path}/${widget.pdfNote.filename}';
            final file = File(filePath);
            await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
            
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF saved to ${directory.path}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
        } catch (e) {
          logger.d('Asset download error: $e');
        }
      }
      
      // If we reach here, show error
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not download PDF. Please try again later.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      logger.d('Download function error: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error downloading PDF. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
} 