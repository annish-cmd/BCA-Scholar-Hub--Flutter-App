import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/auth_provider.dart';
import '../main.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'help_support_page.dart';
import 'auth/login_screen.dart';
import '../services/database_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _databaseService = DatabaseService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Only show connection error if we can't get user data
    bool showConnectionError = false;

    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      try {
        final userData = await _databaseService.getUserData(
          authProvider.currentUser!.uid,
        );

        if (mounted) {
          setState(() {
            _userData = userData;
            _isLoading = false;
          });
        }

        // If we successfully loaded user data, don't show connection error
        if (userData != null) {
          showConnectionError = false;
        } else {
          showConnectionError = true;
        }
      } catch (e) {
        _logger.e('Error loading user data: $e');
        showConnectionError = true;

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Show error message if needed
    if (showConnectionError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to connect to database. Please check your internet connection.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : Colors.blue[200]!;
    final secondaryBackgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : Colors.purple[200]!;

    // Get localizations
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundColor, secondaryBackgroundColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child:
                            authProvider.isLoggedIn
                                ? Text(
                                  _userData?['displayName']?.isNotEmpty == true
                                      ? _userData!['displayName'][0]
                                          .toUpperCase()
                                      : authProvider.userEmail?.isNotEmpty ==
                                          true
                                      ? authProvider.userEmail![0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                )
                                : const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.blue,
                                ),
                      ),
                    ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    authProvider.isLoggedIn
                        ? (_userData?['displayName'] ??
                            authProvider.userEmail?.split('@').first ??
                            'User')
                        : 'Guest User',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    authProvider.isLoggedIn
                        ? (_userData?['email'] ?? authProvider.userEmail ?? '')
                        : 'Not logged in',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
                if (authProvider.isLoggedIn && _userData != null)
                  Center(
                    child: Text(
                      'Last Login: ${_formatTimestamp(_userData?['lastLogin'])}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                Card(
                  elevation: 4,
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: Icon(
                            Icons.info,
                            color: isDarkMode ? Colors.blue[300] : Colors.blue,
                          ),
                          title: Text(
                            localizations.translate('about'),
                            style: TextStyle(color: textColor),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AboutPage(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.settings,
                            color: isDarkMode ? Colors.blue[300] : Colors.blue,
                          ),
                          title: Text(
                            localizations.translate('settings'),
                            style: TextStyle(color: textColor),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: textColor,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsPage(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.support_agent,
                            color: isDarkMode ? Colors.blue[300] : Colors.blue,
                          ),
                          title: Text(
                            localizations.translate('contact_us'),
                            style: TextStyle(color: textColor),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: textColor,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HelpSupportPage(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        ),
                        if (authProvider.isLoggedIn)
                          // Logout option for logged in users
                          ListTile(
                            leading: Icon(Icons.logout, color: Colors.red),
                            title: Text(
                              localizations.translate('logout'),
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              _showLogoutConfirmationDialog(context);
                            },
                          )
                        else
                          // Login option for guests
                          ListTile(
                            leading: Icon(Icons.login, color: Colors.green),
                            title: Text(
                              'Login',
                              style: TextStyle(color: Colors.green),
                            ),
                            onTap: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder:
                                      (context) => LoginScreen(
                                        pages:
                                            myAppKey.currentState!.getPages(),
                                      ),
                                ),
                                (route) => false,
                              );
                            },
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
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      // Firebase Realtime Database stores timestamps as milliseconds since epoch
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      // Format in 12-hour format with AM/PM
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final hourString = hour == 0 ? '12' : hour.toString();
      final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
      final minutes = dateTime.minute.toString().padLeft(2, '0');

      return '${dateTime.day}/${dateTime.month}/${dateTime.year} $hourString:$minutes $amPm';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.translate('logout_confirmation')),
          content: Text(localizations.translate('logout_message')),
          actions: <Widget>[
            TextButton(
              child: Text(localizations.translate('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                localizations.translate('logout'),
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                // Get the auth provider and logout
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();

                // Navigate back to login screen
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close dialog

                  // Use the same pages list from main app
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder:
                          (context) => LoginScreen(
                            pages: myAppKey.currentState!.getPages(),
                          ),
                    ),
                    (route) => false, // Remove all previous routes
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
