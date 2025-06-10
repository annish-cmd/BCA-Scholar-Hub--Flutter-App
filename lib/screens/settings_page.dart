import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/language_provider.dart';
import '../utils/app_localizations.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';
import 'profile_info_page.dart';
import 'password_security_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context);

    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : Colors.blue[50]!;
    final secondaryBackgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : Colors.purple[50]!;

    // Get the text size from provider
    final textSize = themeProvider.textSize;

    // Get current language name
    final currentLanguage = languageProvider.currentLanguageName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('settings'),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundColor, secondaryBackgroundColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          children: [
            _buildSectionHeader(
              localizations.translate('account_settings'),
              textColor,
            ),
            _buildSettingsCard([
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple[100],
                  child: Icon(Icons.person, color: Colors.purple),
                ),
                title: Text(
                  localizations.translate('profile_info'),
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  localizations.translate('profile_info'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
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
                      builder: (context) => const ProfileInfoPage(),
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.lock, color: Colors.blue),
                ),
                title: Text(
                  localizations.translate('password_security'),
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  localizations.translate('password_security'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
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
                      builder: (context) => const PasswordSecurityPage(),
                    ),
                  );
                },
              ),
            ], cardColor),

            _buildSectionHeader(
              localizations.translate('appearance'),
              textColor,
            ),
            _buildSettingsCard([
              SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor: Colors.indigo[100],
                  child: Icon(Icons.dark_mode, color: Colors.indigo),
                ),
                title: Text(
                  localizations.translate('dark_mode'),
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  localizations.translate('theme_description'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                value: isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
              Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal[100],
                  child: Icon(Icons.text_fields, color: Colors.teal),
                ),
                title: Text(
                  localizations.translate('text_size'),
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  '${textSize.toInt()} px',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    min: 12.0,
                    max: 20.0,
                    divisions: 4,
                    value: textSize,
                    onChanged: (value) {
                      themeProvider.setTextSize(value);
                    },
                  ),
                ),
              ),
            ], cardColor),

            _buildSectionHeader(
              localizations.translate('preferences'),
              textColor,
            ),
            _buildSettingsCard([
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Icon(Icons.language, color: Colors.orange),
                ),
                title: Text(
                  localizations.translate('language'),
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  currentLanguage,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                trailing: DropdownButton<String>(
                  value: currentLanguage,
                  icon: Icon(Icons.arrow_drop_down, color: textColor),
                  dropdownColor: cardColor,
                  underline: Container(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      languageProvider.setLanguage(newValue);
                    }
                  },
                  items:
                      LanguageProvider.availableLocales.keys
                          .map<DropdownMenuItem<String>>((String languageName) {
                            return DropdownMenuItem<String>(
                              value: languageName,
                              child: Text(
                                languageName,
                                style: TextStyle(color: textColor),
                              ),
                            );
                          })
                          .toList(),
                ),
              ),
              Divider(),
              SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor: Colors.red[100],
                  child: Icon(Icons.notifications, color: Colors.red),
                ),
                title: Text(
                  localizations.translate('notifications'),
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  localizations.translate('notification_description'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ], cardColor),

            _buildSectionHeader(localizations.translate('about'), textColor),
            _buildSettingsCard([
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber[100],
                  child: Icon(Icons.info, color: Colors.amber),
                ),
                title: Text(
                  localizations.translate('app_version'),
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
              Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple[100],
                  child: Icon(Icons.policy, color: Colors.deepPurple),
                ),
                title: Text(
                  localizations.translate('privacy_policy'),
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
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo[100],
                  child: Icon(Icons.description, color: Colors.indigo),
                ),
                title: Text(
                  localizations.translate('terms_of_service'),
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
                      builder: (context) => const TermsOfServicePage(),
                    ),
                  );
                },
              ),
            ], cardColor),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // Show confirmation dialog before resetting
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(localizations.translate('reset_title')),
                          content: Text(
                            localizations.translate('confirm_reset'),
                          ),
                          backgroundColor: cardColor,
                          titleTextStyle: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          contentTextStyle: TextStyle(
                            color: textColor,
                            fontSize: 16,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(localizations.translate('cancel')),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                // Reset all settings
                                setState(() {
                                  _notificationsEnabled = true;
                                });

                                // Reset theme settings
                                themeProvider.resetSettings();

                                // Reset language settings
                                languageProvider.resetLanguage();

                                Navigator.of(context).pop();

                                // Show confirmation
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations.translate('reset_success'),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: Text(localizations.translate('reset')),
                            ),
                          ],
                        ),
                  );
                },
                child: Text(
                  localizations.translate('reset_settings'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color:
              textColor == Colors.white
                  ? Colors.purple[200]
                  : Colors.purple[800],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, Color cardColor) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: children),
      ),
    );
  }
}
