import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : Colors.blue[50]!;
    final secondaryBackgroundColor =
        isDarkMode ? const Color(0xFF1A1A1A) : Colors.purple[50]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(title: 'Terms of Service', textColor: textColor),
              const SizedBox(height: 16),
              _buildDateCard(context, isDarkMode, cardColor, textColor),
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Agreement to Terms',
                'By accessing or using the BCA Scholar Hub application, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing this app.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                'Use License',
                'Permission is granted to temporarily use the application for personal, non-commercial purposes only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose\n• Attempt to decompile or reverse engineer any software contained in the app\n• Remove any copyright or other proprietary notations from the materials\n• Transfer the materials to another person or "mirror" the materials on any other server',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                'User Accounts',
                'Some features of the app may require you to register for an account. You are responsible for maintaining the confidentiality of your account and password and for restricting access to your device, and you agree to accept responsibility for all activities that occur under your account.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                'Content',
                'Our app allows you to access educational materials, PDFs, and courses. All content provided on this app is for informational and educational purposes only. We make no warranties about the accuracy or reliability of such content.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                'Limitations',
                'In no event shall BCA Scholar Hub or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on the app, even if BCA Scholar Hub or an authorized representative has been notified orally or in writing of the possibility of such damage.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                'Revisions and Errata',
                'BCA Scholar Hub may revise these terms of service for its app at any time without notice. By using this app you are agreeing to be bound by the then current version of these terms of service.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                'Governing Law',
                'These terms and conditions are governed by and construed in accordance with the laws and you irrevocably submit to the exclusive jurisdiction of the courts in that location.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                'Contact Information',
                'If you have any questions about these Terms of Service, please contact us at:\n\n• Email: terms@anishlibrary.com\n• Website: www.anishlibrary.com',
                isDarkMode,
                cardColor,
                textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard(
    BuildContext context,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
  ) {
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey;

    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(isDarkMode ? 50 : 30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'May 10, 2024',
                  style: TextStyle(color: secondaryTextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDarkMode ? 40 : 10),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            content,
            style: TextStyle(fontSize: 16, height: 1.5, color: textColor),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final Color textColor;

  const _SectionHeading({required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }
}
