import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/profile_page.dart';
import 'screens/bca_semester_page.dart';
import 'screens/splash_screen.dart';
import 'screens/home_content_screen.dart';
import 'screens/youtube_screen.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/extra_courses_screen.dart';
import 'utils/theme_provider.dart';
import 'utils/language_provider.dart';
import 'utils/app_localizations.dart';
import 'utils/favorites_provider.dart';

// Add services import
import 'package:flutter/services.dart';

// Global key for app state access
final GlobalKey<MyAppState> myAppKey = GlobalKey<MyAppState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow both portrait and landscape orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ],
        child: MyApp(key: myAppKey),
      ),
    );
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  // Public method to allow updating navigation index if needed
  void updateIndex(int index) {
    // This method is kept for compatibility with other parts of the app
    // that might use it through the global key
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    // Create styled placeholder pages
    final List<Widget> pages = [
      // Home Page
      const HomeContentScreen(),
      // YouTube Page
      const YouTubeScreen(),
      // Search Page
      const SearchScreen(),
      // Favorites Page
      const FavoritesScreen(),
      const ProfilePage(), // Updated Profile Page
      const BcaSemesterPage(semester: 1, notes: 'Notes for BCA 1st Semester'),
      const BcaSemesterPage(semester: 2, notes: 'Notes for BCA 2nd Semester'),
      const BcaSemesterPage(semester: 3, notes: 'Notes for BCA 3rd Semester'),
      const BcaSemesterPage(semester: 4, notes: 'Notes for BCA 4th Semester'),
      const BcaSemesterPage(semester: 5, notes: 'Notes for BCA 5th Semester'),
      const BcaSemesterPage(semester: 6, notes: 'Notes for BCA 6th Semester'),
      const BcaSemesterPage(semester: 7, notes: 'Notes for BCA 7th Semester'),
      const BcaSemesterPage(semester: 8, notes: 'Notes for BCA 8th Semester'),
      const ExtraCoursesScreen(),
    ];

    // Create the home widget (always use splash screen)
    Widget homeWidget = SplashScreen(pages: pages);

    return MaterialApp(
      title: 'BCA Library',
      debugShowCheckedModeBanner: false,

      // Localization setup
      locale: languageProvider.currentLocale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('ne', 'NP'), // Nepali
        Locale('hi', 'IN'), // Hindi
      ],

      // Theme setup
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Apply global text scaling
      builder: (context, child) {
        return MediaQuery(
          // Override text scaling using the new textScaler instead of deprecated textScaleFactor
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(themeProvider.textScaleFactor),
          ),
          child: child!,
        );
      },
      home: homeWidget,
    );
  }
}

// A styled placeholder page for sections under development
class PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;

  const PlaceholderPage({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    // Get translations
    final localizations = AppLocalizations.of(context);
    final title = localizations.translate(titleKey);
    final description = localizations.translate(descriptionKey);
    final comingSoon = localizations.translate('coming_soon');

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
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
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
                    Icon(icon, size: 80, color: Colors.blue),
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
                      description,
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
                      onPressed: () {},
                      child: Text(
                        comingSoon,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
