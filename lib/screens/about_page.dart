import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF34495E);
    final cardColor =
        isDarkMode ? const Color(0xFF1F1F1F) : Colors.white.withAlpha(242);
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFF2C3E50);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About', style: TextStyle(fontFamily: 'Bauhaus 93')),
        elevation: 0,
        backgroundColor: const Color(0xFF2C3E50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                backgroundColor,
                isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFF3498DB),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF3498DB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.library_books,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              localizations.translate('app_name'),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontFamily: 'Bauhaus 93',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Text(
                        localizations.translate('welcome_message'),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Key Features',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 15),
                      ...[
                        'One App for all your needs',
                        'Access to notes, PDFs, and courses',
                        'Easy Navigation',
                        'Free Courses Links',
                        'Beautiful user interface',
                        'Cross-platform support',
                      ].map(
                        (feature) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: featureItem(feature, textColor),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meet the Team',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.transparent,
                              child: Text(
                                'A',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Anish Chauhan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'Bauhaus 93',
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Lead Developer',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[300]
                                          : Color(0xFF7F8C8D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25),
                Center(
                  child: Text(
                    '© 2025 Anish Library. All rights reserved.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget featureItem(String feature, Color textColor) {
    return Row(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF3498DB).withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.check_circle, color: Color(0xFF3498DB), size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            feature,
            style: TextStyle(fontSize: 16, color: textColor),
          ),
        ),
      ],
    );
  }
}
