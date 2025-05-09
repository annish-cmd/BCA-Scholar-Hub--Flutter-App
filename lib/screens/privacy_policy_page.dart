import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          'Privacy Policy',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: 'Download as PDF',
            onPressed: () {
              _showDownloadDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share',
            onPressed: () {
              _showShareDialog(context);
            },
          ),
        ],
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
              _SectionHeading(title: 'Privacy Policy', textColor: textColor),
              const SizedBox(height: 16),
              _buildDateCard(context, isDarkMode, cardColor, textColor),
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Introduction',
                'This Privacy Policy explains how Anish Library collects, uses, and discloses your information when you use our application. By using our services, you agree to the collection and use of information in accordance with this policy.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                'Information Collection and Use',
                'We collect several different types of information for various purposes to provide and improve our service to you. While using our app, we may ask you to provide us with certain personally identifiable information that can be used to contact or identify you.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSubSection(
                context,
                'Personal Data',
                'We may collect personal information that you provide to us such as name, email address, and other contact details.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSubSection(
                context,
                'Usage Data',
                'We may also collect information on how the app is accessed and used. This data may include information such as your device\'s IP address, browser type, pages visited, time spent on those pages, and other diagnostic data.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                'Data Security',
                'The security of your data is important to us, but remember that no method of transmission over the Internet, or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your personal data, we cannot guarantee its absolute security.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                'Changes to This Privacy Policy',
                'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "effective date" at the top of this Privacy Policy.',
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                'Contact Us',
                'If you have any questions about this Privacy Policy, please contact us at:\n\n• Email: contact@anishlibrary.com\n• Website: www.anishlibrary.com',
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

  void _showDownloadDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
          title: Text(
            'Download Privacy Policy',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: Text(
            'Would you like to download the Privacy Policy as a PDF file?',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy Policy downloaded successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Download'),
            ),
          ],
        );
      },
    );
  }

  void _showShareDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
          title: Text(
            'Share Privacy Policy',
            style: TextStyle(color: textColor),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose how you would like to share:',
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildShareOption(
                      context,
                      Icons.email,
                      'Email',
                      isDarkMode,
                      textColor,
                    ),
                    _buildShareOption(
                      context,
                      Icons.messenger_outline,
                      'Messenger',
                      isDarkMode,
                      textColor,
                    ),
                    _buildShareOption(
                      context,
                      Icons.copy,
                      'Copy Link',
                      isDarkMode,
                      textColor,
                    ),
                    _buildShareOption(
                      context,
                      Icons.phone_android,
                      'SMS',
                      isDarkMode,
                      textColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        );
      },
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    IconData icon,
    String label,
    bool isDarkMode,
    Color textColor,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared via $label'),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor:
                isDarkMode
                    ? Colors.blue.withAlpha(50)
                    : Colors.blue.withAlpha(30),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: textColor)),
        ],
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
                  'Effective Date',
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

  Widget _buildSubSection(
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
          margin: const EdgeInsets.only(bottom: 10, left: 16),
          child: Row(
            children: [
              Container(
                height: 18,
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(left: 16),
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
            style: TextStyle(fontSize: 15, height: 1.5, color: textColor),
          ),
        ),
        const SizedBox(height: 20),
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
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }
}
