import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class UrlLauncherUtils {
  // Launch a URL and handle any errors
  static Future<void> launchUrlWithErrorHandling(
    BuildContext context,
    String urlString,
  ) async {
    try {
      // Parse the URL string
      final Uri uri = Uri.parse(urlString);

      // Launch the URL using external application mode, which works most reliably
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showErrorSnackbar(
          context,
          'Could not launch website. Please try again.',
        );
      }
    } catch (e) {
      // Show a user-friendly error message
      _showErrorSnackbar(
        context,
        'Could not open website. Please try again later.',
      );
    }
  }

  // Show an error snackbar
  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
