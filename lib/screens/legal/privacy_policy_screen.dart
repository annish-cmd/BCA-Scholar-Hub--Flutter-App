import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                      "Privacy Policy",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),

                _buildSectionContent(
                  'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                  textColor,
                  isBold: true,
                ),

                _buildSectionContent(
                  'BCA Scholar Hub is committed to protecting your privacy while providing you with the best educational resources for your BCA studies. This policy explains how we handle your information.',
                  textColor,
                ),

                _buildSectionTitle('1. Information We Collect', textColor),
                _buildSectionContent(
                  'We collect minimal information to provide you with personalized educational content:\n\n'
                  '• Account Information: Your name, email address, and profile details to personalize your learning experience.\n\n'
                  '• Usage Data: Information about how you interact with our educational materials, which helps us improve our content for BCA students.',
                  textColor,
                ),

                _buildSectionTitle('2. How We Use Your Information', textColor),
                _buildSectionContent(
                  'Your information helps us enhance your learning experience:\n\n'
                  '• To provide personalized study recommendations based on your semester and courses\n'
                  '• To save your progress and bookmarks across BCA study materials\n'
                  '• To notify you about new content relevant to your courses\n'
                  '• To improve our educational resources based on student feedback',
                  textColor,
                ),

                _buildSectionTitle('3. Data Security', textColor),
                _buildSectionContent(
                  'We implement industry-standard security measures to protect your academic information. Your study data and account details are secured with encryption and regular security updates to ensure your educational journey remains private.',
                  textColor,
                ),

                _buildSectionTitle('4. Educational Content Access', textColor),
                _buildSectionContent(
                  'When you access our educational materials, we may collect anonymous usage statistics to improve content quality. This helps us understand which study materials are most helpful to BCA students and which areas need enhancement.',
                  textColor,
                ),

                _buildSectionTitle('5. Student Privacy', textColor),
                _buildSectionContent(
                  'We respect your privacy as a student. Your personal study habits, notes, and academic performance data are never shared with third parties. We do not sell student information under any circumstances.',
                  textColor,
                ),

                _buildSectionTitle('6. Policy Updates', textColor),
                _buildSectionContent(
                  'We may update this policy to reflect improvements in our privacy practices or changes in regulations affecting educational technology. We will notify you of significant changes through the app.',
                  textColor,
                ),

                _buildSectionTitle('7. Contact Us', textColor),
                _buildSectionContent(
                  'If you have questions about how we protect your privacy while providing educational resources, please contact our student support team at bcascholar@example.com',
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

  Widget _buildSectionContent(
    String content,
    Color textColor, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isBold ? FontWeight.w500 : FontWeight.normal,
          color: textColor.withOpacity(0.9),
          height: 1.5,
        ),
      ),
    );
  }
}
