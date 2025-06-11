import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../screens/webview_screen.dart';

class UrlLauncherUtils {
  // Launch a URL in external browser and handle any errors
  static Future<void> launchUrlWithErrorHandling(
    BuildContext context,
    String urlString,
  ) async {
    // Store context mounting state before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Parse the URL string
      final Uri uri = Uri.parse(urlString);

      // Launch the URL using external application mode, which works most reliably
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      // Check if context is still mounted before showing error
      if (!launched) {
        _showErrorSnackbar(
          scaffoldMessenger,
          'Could not launch website. Please try again.',
        );
      }
    } catch (e) {
      // Show a user-friendly error message
      _showErrorSnackbar(
        scaffoldMessenger,
        'Could not open website. Please try again later.',
      );
    }
  }

  // Launch a URL in the in-app WebView
  static void launchInAppWebView(
    BuildContext context,
    String urlString,
    String title,
  ) {
    // Pre-create the WebViewController for smoother loading
    final controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFFFAFAFA))
          ..enableZoom(true)
          ..setUserAgent(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
          );

    // Start loading before opening the WebView
    controller.loadRequest(Uri.parse(urlString));

    // Slight delay to allow the controller to initialize
    Future.delayed(const Duration(milliseconds: 50), () {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => WebViewScreen(
                  url: urlString,
                  title: title,
                  controller: controller,
                ),
          ),
        );
      }
    });
  }

  // Show an error snackbar
  static void _showErrorSnackbar(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
