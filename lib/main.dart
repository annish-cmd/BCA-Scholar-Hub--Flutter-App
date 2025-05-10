import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/profile_page.dart';
import 'screens/bca_semester_page.dart';
import 'screens/splash_screen.dart';
import 'utils/theme_provider.dart';
import 'utils/language_provider.dart';
import 'utils/app_localizations.dart';

// Global key to access MyApp state
final GlobalKey<_MyAppState> myAppKey = GlobalKey<_MyAppState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MyApp(key: myAppKey),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  void updateIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    // Create styled placeholder pages
    final List<Widget> pages = [
      // Home Page
      const PlaceholderPage(
        icon: Icons.home,
        titleKey: 'home',
        descriptionKey: 'welcome_message',
      ),
      // YouTube Page
      const PlaceholderPage(
        icon: Icons.play_circle_fill,
        titleKey: 'youtube',
        descriptionKey: 'youtube_description',
      ),
      // Search Page
      const PlaceholderPage(
        icon: Icons.search,
        titleKey: 'search',
        descriptionKey: 'search_description',
      ),
      // Favorites Page
      const PlaceholderPage(
        icon: Icons.favorite,
        titleKey: 'favorites',
        descriptionKey: 'favorites_description',
      ),
      const ProfilePage(), // Updated Profile Page
      const BcaSemesterPage(semester: 1, notes: 'Notes for BCA 1st Semester'),
      const BcaSemesterPage(semester: 2, notes: 'Notes for BCA 2nd Semester'),
      const BcaSemesterPage(semester: 3, notes: 'Notes for BCA 3rd Semester'),
      const BcaSemesterPage(semester: 4, notes: 'Notes for BCA 4th Semester'),
      const BcaSemesterPage(semester: 5, notes: 'Notes for BCA 5th Semester'),
      const BcaSemesterPage(semester: 6, notes: 'Notes for BCA 6th Semester'),
      const BcaSemesterPage(semester: 7, notes: 'Notes for BCA 7th Semester'),
      const BcaSemesterPage(semester: 8, notes: 'Notes for BCA 8th Semester'),
    ];

    // Determine which screen to show
    Widget homeWidget;
    if (false) {
      // Disabled direct home screen for now, always start with splash
      homeWidget = HomeScreen(
        currentIndex: _currentIndex,
        pages: pages,
        onIndexChanged: updateIndex,
      );
    } else {
      homeWidget = SplashScreen(pages: pages);
    }

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
                  child: Text(comingSoon, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
