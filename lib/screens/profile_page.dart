import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/auth_provider.dart';
import '../utils/user_profile_cache.dart'; // Add this import
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
  bool _isUsingCache = false; // Track if we're using cached data
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
        // First, try to get data from cache
        final cachedData = await UserProfileCache.getUserProfile();
        if (cachedData != null) {
          if (mounted) {
            setState(() {
              _userData = cachedData;
              _isLoading = false;
              _isUsingCache = true;
            });
          }
          
          // Load fresh data in background for cache update
          _loadFreshUserData(authProvider);
        } else {
          // No cache available, load fresh data
          await _loadFreshUserData(authProvider);
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

  // Load fresh user data from database and update cache
  Future<void> _loadFreshUserData(AuthProvider authProvider) async {
    try {
      final userData = await _databaseService.getUserData(
        authProvider.currentUser!.uid,
      );

      if (userData != null) {
        // Save to cache for future use
        await UserProfileCache.saveUserProfile(userData);
      }

      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
          _isUsingCache = false;
        });
      }

      // If we successfully loaded user data, don't show connection error
      // If we couldn't load fresh data but had cache, keep using cache
    } catch (e) {
      _logger.e('Error loading fresh user data: $e');
      // If we have cached data, continue using it
      // If we don't have cached data, show error
      if (_userData == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to refresh profile data. Showing cached information.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
    bool forgetCredentials = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations.translate('logout_confirmation')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localizations.translate('logout_message')),
                  const SizedBox(height: 16),
                  FutureBuilder<bool>(
                    future: Provider.of<AuthProvider>(context, listen: false).getRememberMePreference(),
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return Row(
                          children: [
                            Checkbox(
                              value: forgetCredentials,
                              onChanged: (value) {
                                setState(() {
                                  forgetCredentials = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'Also forget saved login credentials',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
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
                    await authProvider.logout(clearRememberMe: forgetCredentials);

                    // Clear user profile cache on logout
                    await UserProfileCache.clearCache();

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
      },
    );
  }
}