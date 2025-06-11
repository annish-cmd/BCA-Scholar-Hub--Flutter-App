import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.lightBlue,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[200]!, Colors.purple[200]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.support_agent,
                            size: 40,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            localizations.translate('contact_us'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        localizations.translate('connect_with_us'),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  localizations.translate('social_links'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 10),
                Column(
                  children: <Widget>[
                    socialLink('GitHub', '@anish-cmd', cardColor, textColor),
                    socialLink(
                      'LinkedIn',
                      '@anishchauhan25',
                      cardColor,
                      textColor,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    '© 2025 BCA Scholar Hub. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withAlpha(179),
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

  Widget socialLink(
    String platform,
    String username,
    Color cardColor,
    Color textColor,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      color: cardColor,
      child: ListTile(
        title: Text(platform, style: TextStyle(color: textColor)),
        subtitle: Text(
          username,
          style: TextStyle(
            color: textColor.withAlpha(179),
          ), // 0.7 opacity is approximately 179 alpha
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: textColor),
        onTap: () {
          // Add functionality to open the respective social media link
        },
      ),
    );
  }
}
