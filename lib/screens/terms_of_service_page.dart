import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';

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
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('tos_title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              _SectionHeading(title: localizations.translate('tos_title'), textColor: textColor),
              const SizedBox(height: 16),
              _buildDateCard(context, isDarkMode, cardColor, textColor, localizations),
              const SizedBox(height: 24),
              _buildSection(
                context,
                localizations.translate('tos_agreement_title'),
                localizations.translate('tos_agreement_content'),
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                localizations.translate('tos_license_title'),
                localizations.translate('tos_license_content'),
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                localizations.translate('tos_accounts_title'),
                localizations.translate('tos_accounts_content'),
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                localizations.translate('tos_content_title'),
                localizations.translate('tos_content_content'),
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                localizations.translate('tos_limitations_title'),
                localizations.translate('tos_limitations_content'),
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                localizations.translate('tos_revisions_title'),
                localizations.translate('tos_revisions_content'),
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                localizations.translate('tos_governing_title'),
                localizations.translate('tos_governing_content'),
                isDarkMode,
                cardColor,
                textColor,
              ),
              _buildSection(
                context,
                localizations.translate('tos_contact_title'),
                localizations.translate('tos_contact_content'),
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
    AppLocalizations localizations,
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
                  localizations.translate('pp_last_updated'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
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
