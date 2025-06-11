import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_provider.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.grey[800]!.withOpacity(0.5)
                      : Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: isDarkMode ? Colors.white : Colors.black87,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [const Color(0xFF121212), const Color(0xFF1F1F1F)]
                    : [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 30),
                    child: Text(
                      "Terms and Conditions",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),

                _buildSectionContent(
                  'Welcome to BCA Scholar Hub, your comprehensive educational resource for BCA students. By using our app, you agree to these terms.',
                  textColor,
                ),

                _buildSectionTitle('1. Educational Use', textColor),
                _buildSectionContent(
                  'BCA Scholar Hub provides academic resources for educational purposes only. All study materials, notes, and resources are designed to supplement your BCA curriculum and enhance your learning experience.',
                  textColor,
                ),

                _buildSectionTitle('2. User Accounts', textColor),
                _buildSectionContent(
                  'Your account gives you access to our comprehensive collection of BCA study materials across all semesters. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.',
                  textColor,
                ),

                _buildSectionTitle('3. Content Usage', textColor),
                _buildSectionContent(
                  'The educational content in this app is for personal, non-commercial use only. You may not distribute, modify, or create derivative works from our materials without permission. All content is protected by copyright laws.',
                  textColor,
                ),

                _buildSectionTitle('4. Academic Integrity', textColor),
                _buildSectionContent(
                  'BCA Scholar Hub is designed to support your learning journey. We encourage using our resources to enhance your understanding, but you must adhere to your institution\'s academic integrity policies when using our materials for assignments.',
                  textColor,
                ),

                _buildSectionTitle('5. User Conduct', textColor),
                _buildSectionContent(
                  'When using interactive features of our app, you agree to engage respectfully with other users. Prohibited behaviors include sharing inappropriate content, harassment, or any activity that disrupts the educational purpose of the platform.',
                  textColor,
                ),

                _buildSectionTitle('6. Updates and Modifications', textColor),
                _buildSectionContent(
                  'We regularly update our content to ensure accuracy and relevance to the current BCA curriculum. We reserve the right to modify or discontinue any aspect of the service to improve your learning experience.',
                  textColor,
                ),

                _buildSectionTitle('7. Limitation of Liability', textColor),
                _buildSectionContent(
                  'While we strive for accuracy in all educational materials, BCA Scholar Hub is not responsible for any academic outcomes resulting from the use of our content. Users should verify information through official course materials.',
                  textColor,
                ),

                _buildSectionTitle('8. Contact Information', textColor),
                _buildSectionContent(
                  'For questions about these terms or suggestions to improve our educational resources, please contact us at bcascholar@example.com',
                  textColor,
                ),

                const SizedBox(height: 30),

                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'I Accept',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 15,
          color: textColor.withOpacity(0.9),
          height: 1.5,
        ),
      ),
    );
  }
}
