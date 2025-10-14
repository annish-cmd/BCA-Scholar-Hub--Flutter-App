import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/favorites_provider.dart';
import '../utils/auth_provider.dart';
import '../models/pdf_note.dart';
import '../models/firebase_note.dart';
import '../services/database_service.dart';
import 'pdf_options_screen.dart';
import '../main.dart'; 
import 'auth/login_screen.dart';
import '../widgets/thumbnail_image.dart';
import '../utils/favorites_cache_manager.dart';


class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<PdfNote> _allNotes = [];
  final FavoritesCacheManager _cacheManager = FavoritesCacheManager();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadNotesInstantly();
  }

  // INSTANT LOADING - Always shows data immediately
  void _loadNotesInstantly() {
    final stopwatch = Stopwatch()..start();
    
    // Get notes instantly (never null, always has data)
    _allNotes = _cacheManager.getNotesInstantly();
    print('🚀 INSTANT: Loaded ${_allNotes.length} notes in ${stopwatch.elapsedMilliseconds}ms');
    
    // Update cache asynchronously in background (non-blocking)
    _updateCacheInBackground();
  }

  // Update cache in background without affecting UI
  void _updateCacheInBackground() {
    _cacheManager.loadAndUpdateCache().then((updatedNotes) {
      if (mounted && updatedNotes.length != _allNotes.length) {
        setState(() {
          _allNotes = updatedNotes;
        });
        print('🔄 BACKGROUND: Updated with ${updatedNotes.length} notes');
      }
    });
  }

  // Pull-to-refresh functionality - Clear all caches
  Future<void> _refreshFavorites() async {
    await _cacheManager.clearCache();
    _loadNotesInstantly();
    print('🔄 REFRESH: Cache cleared and reloaded');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final localizations = AppLocalizations.of(context);
    final title = localizations.translate('favorites');
    final String noFavoritesMessage = localizations.translate('no_favorites');

    if (!authProvider.isLoggedIn) {
      return _buildLoginRequired(context, isDarkMode, textColor);
    }

    // No loading check - always show data instantly
    final List<PdfNote> favoritePdfs = favoritesProvider.getFavoritePdfs(_allNotes);

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
      child:
          favoritePdfs.isEmpty
              ? _buildEmptyFavorites(
                context,
                isDarkMode,
                textColor,
                title,
                noFavoritesMessage,
              )
              : _buildFavoritesList(
                context,
                isDarkMode,
                textColor,
                title,
                favoritePdfs,
              ),
    );
  }

  // Widget to show when user is not logged in
  Widget _buildLoginRequired(
    BuildContext context,
    bool isDarkMode,
    Color textColor,
  ) {
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
      child: Center(
        child: Card(
          elevation: 5,
          color: isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  'Login Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please login to view and manage your favorites.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder:
                            (context) => LoginScreen(
                              pages: myAppKey.currentState!.getPages(),
                            ),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Login Now',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget to show when no favorites are available
  Widget _buildEmptyFavorites(
    BuildContext context,
    bool isDarkMode,
    Color textColor,
    String title,
    String noFavoritesMessage,
  ) {
    return Center(
      child: Card(
        elevation: 5,
        color: isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 80, color: Colors.pink),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                noFavoritesMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // Navigate to home screen with a simpler approach
                  // Use the app's global key to update the navigation index
                  if (myAppKey.currentState != null) {
                    myAppKey.currentState!.updateIndex(0); // Go to home tab
                  }
                  // Alternatively, just navigate to root route
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Browse PDFs',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to show the list of favorite PDFs
  Widget _buildFavoritesList(
    BuildContext context,
    bool isDarkMode,
    Color textColor,
    String title,
    List<PdfNote> favoritePdfs,
  ) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.favorite, color: Colors.pink, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),

        // Favorites list with performance optimizations
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshFavorites,
            child: ListView.builder(
              itemCount: favoritePdfs.length,
              padding: const EdgeInsets.all(16),
              // Performance optimizations
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              cacheExtent: 500.0,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final pdf = favoritePdfs[index];
                return _buildOptimizedPdfCard(context, pdf, isDarkMode, textColor, index);
              },
            ),
          ),
        ),
      ],
    );
  }


  // Optimized PDF card with lazy image loading
  Widget _buildOptimizedPdfCard(
    BuildContext context,
    PdfNote pdf,
    bool isDarkMode,
    Color textColor,
    int index,
  ) {
    return RepaintBoundary(
      key: ValueKey('favorite_card_${pdf.id}_$index'),
      child: _buildPdfCardContent(context, pdf, isDarkMode, textColor),
    );
  }

  // Widget to display an individual PDF card
  Widget _buildPdfCardContent(
    BuildContext context,
    PdfNote pdf,
    bool isDarkMode,
    Color textColor,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? const Color(0xFF262626) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // Fetch the corresponding Firebase note for better recommendations
          FirebaseNote? firebaseNote;
          try {
            // Get all notes by combining semester notes and extra course notes
            List<FirebaseNote> allFirebaseNotes = [];
            
            // Get notes from all semesters (1st to 8th)
            for (int semester = 1; semester <= 8; semester++) {
              String semesterStr = '${semester}st';
              if (semester == 2) semesterStr = '2nd';
              else if (semester == 3) semesterStr = '3rd';
              else if (semester > 3) semesterStr = '${semester}th';
              
              final semesterNotes = await _databaseService.getSemesterNotes(semesterStr);
              allFirebaseNotes.addAll(semesterNotes);
            }
            
            // Also get extra course notes
            final extraNotes = await _databaseService.getExtraCourseNotes();
            allFirebaseNotes.addAll(extraNotes);
            
            // Try to find the Firebase note by matching title and category
            firebaseNote = allFirebaseNotes.firstWhere(
              (note) => note.title == pdf.title && note.category == pdf.subject,
              orElse: () => allFirebaseNotes.firstWhere(
                (note) => note.title == pdf.title,
                orElse: () => allFirebaseNotes.firstWhere(
                  (note) => note.category == pdf.subject,
                  orElse: () => allFirebaseNotes.isNotEmpty ? allFirebaseNotes.first : throw StateError('No notes found'),
                ),
              ),
            );
          } catch (e) {
            print('Could not find matching Firebase note: $e');
            firebaseNote = null;
          }
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfOptionsScreen(
                  pdfNote: pdf,
                  firebaseNote: firebaseNote,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: ThumbnailImage(
                imageUrl: pdf.thumbnailImage,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                isDarkMode: isDarkMode,
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pdf.subject,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pdf.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Favorite/unfavorite button
            Consumer<FavoritesProvider>(
              builder: (context, favoritesProvider, child) {
                return IconButton(
                  icon: Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    favoritesProvider.toggleFavorite(pdf.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed from favorites'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
