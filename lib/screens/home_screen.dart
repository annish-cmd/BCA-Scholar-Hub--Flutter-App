import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/url_launcher_utils.dart';

class HomeScreen extends StatelessWidget {
  final int currentIndex;
  final List<Widget> pages;
  final Function(int) onIndexChanged;

  const HomeScreen({
    Key? key,
    required this.currentIndex,
    required this.pages,
    required this.onIndexChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final localizations = AppLocalizations.of(context);

    // Fixed icon colors for proper visibility in both modes
    final iconColor = isDarkMode ? Colors.white : Colors.blue[700];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Anish Library',
          style: TextStyle(
            fontFamily: 'Bauhaus 93',
            color: Colors.white,
            fontSize: 24,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(128),
                offset: Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 3,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Add search functionality here
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Add notification functionality here
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, isDarkMode, textColor),
      body: Column(
        children: [
          if (currentIndex == 0 || (currentIndex >= 5 && currentIndex <= 12))
            _buildSemesterButtons(isDarkMode, localizations),
          Expanded(child: pages[currentIndex]),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        items: <Widget>[
          Icon(Icons.home, size: 30, color: iconColor),
          Icon(Icons.play_circle_fill, size: 30, color: iconColor),
          Icon(Icons.search, size: 30, color: iconColor),
          Icon(Icons.favorite, size: 30, color: iconColor),
          Icon(Icons.person, size: 30, color: iconColor),
        ],
        color: isDarkMode ? const Color(0xFF1F1F1F) : Colors.blue,
        buttonBackgroundColor: isDarkMode ? Colors.purple : Colors.white,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: onIndexChanged,
        index:
            currentIndex < 5
                ? currentIndex
                : 0, // Ensure proper tab highlighting
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDarkMode, Color textColor) {
    final textStyle = TextStyle(
      color: isDarkMode ? Colors.white : Colors.white,
    );
    final drawerColor =
        isDarkMode
            ? [const Color(0xFF1F1F1F), const Color(0xFF2D2D2D)]
            : [Colors.blue[200]!, Colors.purple[200]!];

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: drawerColor,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Custom drawer header that adapts to text scaling
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 16,
                16,
                16,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Anish Library',
                  style: TextStyle(
                    fontFamily: 'Bauhaus 93',
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text('Contact Us', style: textStyle),
              leading: Icon(Icons.contact_mail, color: Colors.white),
              onTap: () {
                // Close the drawer first
                Navigator.pop(context);
                // Launch Anish's website
                UrlLauncherUtils.launchUrlWithErrorHandling(
                  context,
                  'https://www.anishchauhan.com.np/',
                );
              },
            ),
            ListTile(
              title: Text('Our Website', style: textStyle),
              leading: Icon(Icons.language, color: Colors.white),
              onTap: () {
                // Close the drawer first
                Navigator.pop(context);
                // Launch Anish's website
                UrlLauncherUtils.launchUrlWithErrorHandling(
                  context,
                  'https://www.anishchauhan.com.np/',
                );
              },
            ),
            ListTile(
              title: Text('Facebook Page', style: textStyle),
              leading: Icon(Icons.facebook, color: Colors.white),
              onTap: () {
                // Close the drawer first
                Navigator.pop(context);
                // Launch Anish's website
                UrlLauncherUtils.launchUrlWithErrorHandling(
                  context,
                  'https://www.anishchauhan.com.np/',
                );
              },
            ),
            ListTile(
              title: Text('Instagram', style: textStyle),
              leading: Icon(Icons.photo_camera, color: Colors.white),
              onTap: () {
                // Close the drawer first
                Navigator.pop(context);
                // Launch Anish's website
                UrlLauncherUtils.launchUrlWithErrorHandling(
                  context,
                  'https://www.anishchauhan.com.np/',
                );
              },
            ),
            ListTile(
              title: Text('BCA Entrance Questions', style: textStyle),
              leading: Icon(Icons.quiz, color: Colors.white),
              onTap: () {},
            ),
            ListTile(
              title: Text('BCA Semester I', style: textStyle),
              leading: Icon(Icons.book, color: Colors.white),
              onTap: () {
                onIndexChanged(5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('BCA Semester II', style: textStyle),
              leading: Icon(Icons.book, color: Colors.white),
              onTap: () {
                onIndexChanged(6);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('BCA Semester III', style: textStyle),
              leading: Icon(Icons.book, color: Colors.white),
              onTap: () {
                onIndexChanged(7);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('BCA Semester IV', style: textStyle),
              leading: Icon(Icons.book, color: Colors.white),
              onTap: () {
                onIndexChanged(8);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('BCA Semester V', style: textStyle),
              leading: Icon(Icons.book, color: Colors.white),
              onTap: () {
                onIndexChanged(9);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('BCA Semester VI', style: textStyle),
              leading: Icon(Icons.book, color: Colors.white),
              onTap: () {
                onIndexChanged(10);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('BCA Semester VII', style: textStyle),
              leading: Icon(Icons.book, color: Colors.white),
              onTap: () {
                onIndexChanged(11);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('BCA Semester VIII', style: textStyle),
              leading: Icon(Icons.book, color: Colors.white),
              onTap: () {
                onIndexChanged(12);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterButtons(
    bool isDarkMode,
    AppLocalizations localizations,
  ) {
    final buttonColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.blue[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            8,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: textColor,
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                ),
                onPressed: () {
                  onIndexChanged(index + 5);
                },
                child: Text(
                  '${localizations.translate('semester')} ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isDarkMode
                            ? Colors.white
                            : (index + 5 == currentIndex
                                ? Colors.blue
                                : Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
