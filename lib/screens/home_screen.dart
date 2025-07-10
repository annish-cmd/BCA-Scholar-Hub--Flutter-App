import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/url_launcher_utils.dart';
import '../utils/notification_provider.dart';
import '../widgets/search_app_bar.dart';
import 'global_chat_screen.dart';
import 'notification_page.dart';

class HomeScreen extends StatefulWidget {
  final int currentIndex;
  final List<Widget> pages;
  final Function(int) onIndexChanged;

  const HomeScreen({
    super.key,
    required this.currentIndex,
    required this.pages,
    required this.onIndexChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  void _handleIndexChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.onIndexChanged(index);
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      setState(() {
        _currentIndex = widget.currentIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final localizations = AppLocalizations.of(context);

    // Fixed icon colors for proper visibility in both modes
    final iconColor = isDarkMode ? Colors.white : Colors.blue[700];

    return Scaffold(
      appBar:
          _isSearching
              ? SearchAppBar(onClose: _toggleSearch, isDarkMode: isDarkMode)
              : AppBar(
                title: Text(
                  'BCA Scholar Hub',
                  style: TextStyle(
                    fontFamily: 'Bauhaus 93',
                    color: Colors.white,
                    fontSize: 22,
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
                    tooltip: 'Search',
                    onPressed: () {
                      // Navigate directly to search screen (index 2)
                      _handleIndexChanged(2);
                    },
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      final unreadCount = notificationProvider.unreadCount;
                      
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationPage(),
                                ),
                              );
                            },
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
      drawer: _buildDrawer(context, isDarkMode, textColor),
      body: Column(
        children: [
          if (_currentIndex == 0 ||
              (_currentIndex >= 5 &&
                  _currentIndex <= 13 &&
                  _currentIndex != 14))
            _buildSemesterButtons(isDarkMode, localizations),
          Expanded(child: widget.pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar:
          _currentIndex == 14
              ? null
              : CurvedNavigationBar(
                items: <Widget>[
                  Icon(Icons.home, size: 30, color: iconColor),
                  Icon(Icons.play_circle_fill, size: 30, color: iconColor),
                  Icon(Icons.search, size: 30, color: iconColor),
                  Icon(Icons.favorite, size: 30, color: iconColor),
                  Icon(Icons.person, size: 30, color: iconColor),
                ],
                color: isDarkMode ? const Color(0xFF1F1F1F) : Colors.blue,
                buttonBackgroundColor:
                    isDarkMode ? Colors.purple : Colors.white,
                backgroundColor: Colors.transparent,
                animationCurve: Curves.easeInOut,
                animationDuration: const Duration(milliseconds: 300),
                onTap: (index) {
                  // If user taps on the search icon in bottom nav
                  if (index == 2) {
                    // Always navigate to search page
                    _handleIndexChanged(index);
                    // Don't toggle search UI when already on search page
                  } else {
                    // For other icons, just navigate normally
                    _handleIndexChanged(index);
                    // Close search if active
                    if (_isSearching) {
                      setState(() {
                        _isSearching = false;
                      });
                    }
                  }
                },
                index:
                    _currentIndex < 5
                        ? _currentIndex
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
                  'BCA Scholar Hub',
                  style: TextStyle(
                    fontFamily: 'Bauhaus 93',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text('Our Website', style: textStyle),
              leading: Icon(Icons.language, color: Colors.white),
              onTap: () {
                // Close the drawer first
                Navigator.pop(context);
                // Open website inside the app
                UrlLauncherUtils.launchInAppWebView(
                  context,
                  'https://www.anishchauhan.com.np/',
                  'Our Website',
                );
              },
            ),
            ListTile(
              title: Text('Facebook Page', style: textStyle),
              leading: Icon(Icons.facebook, color: Colors.white),
              onTap: () {
                // Close the drawer first
                Navigator.pop(context);
                // Open Facebook page inside the app
                UrlLauncherUtils.launchInAppWebView(
                  context,
                  'https://www.facebook.com/ItsMeAnnesh/',
                  'Facebook Page',
                );
              },
            ),
            ListTile(
              title: Text('Extra Courses', style: textStyle),
              leading: Icon(Icons.star, color: Colors.white),
              onTap: () {
                _handleIndexChanged(13);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Global Chat', style: textStyle),
              leading: Icon(Icons.chat, color: Colors.white),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalChatScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: Text('AI', style: textStyle),
              leading: Icon(Icons.smart_toy, color: Colors.white),
              onTap: () {
                Navigator.pop(context);
                _handleIndexChanged(14);
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
    final extraCourseColor =
        isDarkMode ? Colors.purple[800] : Colors.purple[100];

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
          children: [
            ...List.generate(
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
                    _handleIndexChanged(index + 5);
                  },
                  child: Text(
                    '${localizations.translate('semester')} ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode
                              ? Colors.white
                              : (index + 5 == _currentIndex
                                  ? Colors.blue
                                  : Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
            // Extra Courses button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.star,
                  size: 18,
                  color: isDarkMode ? Colors.white : Colors.purple[800],
                ),
                label: Text(
                  'Extra Courses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isDarkMode
                            ? Colors.white
                            : (_currentIndex == 13
                                ? Colors.purple
                                : Colors.black87),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: textColor,
                  backgroundColor: extraCourseColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                ),
                onPressed: () {
                  _handleIndexChanged(13);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
