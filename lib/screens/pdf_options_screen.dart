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
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as path;

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
      } catch (primaryError) {
        print('External storage error: $primaryError');
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
      } catch (secondaryError) {
        print('Application documents directory error: $secondaryError');
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
      } catch (tertiaryError) {
        print('Temporary directory error: $tertiaryError');
      }

      // Final fallback - share just text if all file methods fail
      await Share.share(
        shareMessage,
        subject: 'BCA Library - ${widget.pdfNote.title}',
      );
    } catch (e) {
      // Show error message with more details for debugging
      print('Sharing error details: $e');
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

                // PDF information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.grey[850]!.withAlpha(128)
                            : Colors.grey[100]!,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pdfNote.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subject: ${widget.pdfNote.subject}',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.file_present_rounded,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.pdfNote.filename,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

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

    // Show loading dialog
    _showLoadingDialog();

    try {
      // Load PDF from assets
      final ByteData bytes = await rootBundle.load(
        'assets/pdfs/${widget.pdfNote.filename}',
      );
      final Uint8List pdfBytes = bytes.buffer.asUint8List();

      // Check the Android version to determine which permissions to request
      bool hasPermission = false;

      if (Platform.isAndroid) {
        // For Android 10+ (API 29+), we need special handling
        if (await _isAndroid10OrAbove()) {
          // Try with general storage permission first
          hasPermission = await Permission.storage.isGranted;

          if (!hasPermission) {
            final storageStatus = await Permission.storage.request();
            hasPermission = storageStatus.isGranted;
          }

          // For newer Android versions, request media permission if needed
          if (!hasPermission && await _isAndroid13OrAbove()) {
            final mediaStatus = await Permission.photos.request();
            hasPermission = mediaStatus.isGranted;
          }
        } else {
          // For older Android versions, just check storage
          final status = await Permission.storage.request();
          hasPermission = status.isGranted;
        }
      } else {
        // For iOS and other platforms
        hasPermission = true;
      }

      // If we still don't have permission, show settings dialog
      if (!hasPermission) {
        Navigator.of(context, rootNavigator: true).pop();

        _showPermissionDialog();
        return;
      }

      // Get download directory - this is crucial for Xiaomi devices
      Directory? destinationDir;

      try {
        // Try external storage download directory first (works on most devices)
        if (Platform.isAndroid) {
          destinationDir = Directory('/storage/emulated/0/Download');
          if (!await destinationDir.exists()) {
            // Fall back to default downloads directory
            destinationDir = await getExternalStorageDirectory();
          }
        } else {
          // iOS and other platforms
          destinationDir = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        print('Error getting download directory: $e');
        destinationDir = await getApplicationDocumentsDirectory();
      }

      if (destinationDir == null) {
        throw Exception('Could not access download directory');
      }

      // Create a more user-friendly filename with BCA Library prefix
      final String friendlyFilename = 'BCA_Library_${widget.pdfNote.filename}';
      final String filePath = path.join(destinationDir.path, friendlyFilename);

      // Save the file
      final File file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Show success dialog with file location and options
      _showSuccessDialog(filePath);
    } catch (e) {
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      print('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString().split('\n').first}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Try Again',
            onPressed: () => _downloadPdf(),
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  // Helper method to check Android version
  Future<bool> _isAndroid10OrAbove() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 29; // Android 10 is API 29
    }
    return false;
  }

  // Helper method to check Android 13+
  Future<bool> _isAndroid13OrAbove() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 is API 33
    }
    return false;
  }

  // Show loading dialog while downloading
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              const Text('Downloading PDF...'),
            ],
          ),
        );
      },
    );
  }

  // Show permission dialog when storage access is denied
  void _showPermissionDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(
            'Storage Permission Required',
            style: TextStyle(color: textColor),
          ),
          content: Text(
            'BCA Library needs permission to save files to your device storage.',
            style: TextStyle(color: textColor.withAlpha(179)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Show success dialog after download completes
  void _showSuccessDialog(String filePath) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final accentColor = isDarkMode ? Colors.green[400]! : Colors.green;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon and title
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: accentColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Download Complete',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),

                // File location details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.grey[850]!.withAlpha(128)
                            : Colors.grey[100]!,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File saved to:',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withAlpha(179),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.folder,
                            size: 16,
                            color:
                                isDarkMode
                                    ? Colors.blueGrey[300]
                                    : Colors.blueGrey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              filePath,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withAlpha(179),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openDownloadedFile(filePath);
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Open File'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.close, color: textColor.withAlpha(179)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Open the downloaded file
  Future<void> _openDownloadedFile(String filePath) async {
    try {
      // Create file object
      final File file = File(filePath);

      if (await file.exists()) {
        // Share the file using Share.shareXFiles which properly handles FileProvider
        final result = await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Open Downloaded PDF',
          text: 'View PDF with your preferred app',
        );

        if (result.status != ShareResultStatus.success) {
          throw Exception('Failed to open file');
        }
      } else {
        throw Exception('File not found');
      }
    } catch (e) {
      print('Error opening file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open file: ${e.toString().split('\n').first}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
