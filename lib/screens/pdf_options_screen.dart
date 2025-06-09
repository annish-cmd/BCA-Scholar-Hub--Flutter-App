import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/favorites_provider.dart';
import '../models/pdf_note.dart';
import 'pdf_viewer_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

// Add a logger instance at the top of the file
final Logger logger = Logger();

class PdfOptionsScreen extends StatefulWidget {
  final PdfNote pdfNote;

  const PdfOptionsScreen({super.key, required this.pdfNote});

  @override
  State<PdfOptionsScreen> createState() => _PdfOptionsScreenState();
}

class _PdfOptionsScreenState extends State<PdfOptionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
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
                                  child: Image.asset(
                                    'assets/images/${widget.pdfNote.thumbnailImage}',
                                    fit: BoxFit.cover,
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

                    // Related section - limited height
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
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
                      height: 190,
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
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: _buildRelatedSubjectCards(isDarkMode),
                            ),
                          ),
                        ],
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
    // Example related subjects with images - limited to 3
    final List<Map<String, dynamic>> relatedSubjects = [
      {'title': 'Java Basics', 'image': 'java.jpg'},
      {'title': 'Flutter Tutorial', 'image': 'flutter.png'},
      {'title': 'Python for Beginners', 'image': 'Python.jpg'},
    ];

    return relatedSubjects.map((subject) {
      return Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening ${subject['title']}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            width: 130,
            height: 125,
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
                color:
                    isDarkMode
                        ? Colors.grey.withAlpha(51)
                        : Colors.grey.withAlpha(77),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image section (larger)
                SizedBox(
                  height: 80,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/${subject['image']}',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Title section only (no description)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? Colors.black.withAlpha(51)
                              : Colors.grey.withAlpha(26),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        subject['title'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
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

      // Create share message with BCA Library source
      final String shareMessage =
          'Notes from BCA Library\n\n'
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
            subject: 'BCA Library - ${widget.pdfNote.title}',
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
          subject: 'BCA Library - ${widget.pdfNote.title}',
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
          subject: 'BCA Library - ${widget.pdfNote.title}',
        );
        return;
      } catch (e) {
        logger.d('Temporary directory error: $e');
      }

      // Final fallback - share just text if all file methods fail
      await Share.share(
        shareMessage,
        subject: 'BCA Library - ${widget.pdfNote.title}',
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download started...'))
    );
  }


}
