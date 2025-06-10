import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/favorites_provider.dart';
import '../utils/auth_provider.dart';
import '../models/pdf_note.dart';
import 'pdf_options_screen.dart';
import 'home_content_screen.dart';
import '../main.dart'; // Import for myAppKey
import 'auth/login_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    // Get translations
    final localizations = AppLocalizations.of(context);
    final title = localizations.translate('favorites');
    final String noFavoritesMessage = localizations.translate('no_favorites');

    // Check if user is logged in
    if (!authProvider.isLoggedIn) {
      return _buildLoginRequired(context, isDarkMode, textColor);
    }

    // Get favorite PDFs
    // Use the static PDFs list from HomeContentScreen
    final List<PdfNote> allPdfs = HomeContentScreen.pdfNotes;
    final List<PdfNote> favoritePdfs = favoritesProvider.getFavoritePdfs(
      allPdfs,
    );

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

        // Favorites list
        Expanded(
          child: ListView.builder(
            itemCount: favoritePdfs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final pdf = favoritePdfs[index];
              return _buildPdfCard(context, pdf, isDarkMode, textColor);
            },
          ),
        ),
      ],
    );
  }

  // Widget to display an individual PDF card
  Widget _buildPdfCard(
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfOptionsScreen(pdfNote: pdf),
            ),
          );
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
              child: Image.asset(
                'assets/images/${pdf.thumbnailImage}',
                height: 100,
                width: 100,
                fit: BoxFit.cover,
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
