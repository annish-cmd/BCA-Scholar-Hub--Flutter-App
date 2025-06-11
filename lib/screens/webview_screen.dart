import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/url_launcher_utils.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final WebViewController? controller;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.controller,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = false; // Start with loading hidden
  bool _hasError = false;
  String _errorMessage = '';
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // Use the pre-initialized controller if provided, otherwise create a new one
    if (widget.controller != null) {
      _controller = widget.controller!;
      _setupControllerListeners();
    } else {
      _initWebView();
    }

    // Only show loading indicator if page takes more than 300ms to load
    // This prevents flashing for fast-loading pages
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _loadingProgress < 0.9) {
        setState(() {
          _isLoading = true;
        });
      }
    });
  }

  // Setup listeners for an existing controller
  void _setupControllerListeners() {
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: _handleProgress,
        onPageStarted: _handlePageStarted,
        onPageFinished: _handlePageFinished,
        onWebResourceError: _handleWebResourceError,
        onNavigationRequest: (NavigationRequest request) {
          // Allow all navigation within the WebView
          return NavigationDecision.navigate;
        },
      ),
    );
  }

  // Progress handler
  void _handleProgress(int progress) {
    setState(() {
      _loadingProgress = progress / 100;
      // Hide loading when almost done
      if (progress > 85) {
        _isLoading = false;
      }
    });
  }

  // Page started handler
  void _handlePageStarted(String url) {
    // Don't show loading immediately to avoid flashing
    // The delayed loading in initState will handle slower pages
    setState(() {
      _hasError = false;
    });
  }

  // Page finished handler
  void _handlePageFinished(String url) {
    setState(() {
      _isLoading = false;
    });
  }

  // Error handler
  void _handleWebResourceError(WebResourceError error) {
    setState(() {
      _isLoading = false;
      // Only show error for main frame issues
      if (error.isForMainFrame == true) {
        _hasError = true;
        _errorMessage = 'Error: ${error.description}';
      }
    });
  }

  // Initialize a new WebView controller
  void _initWebView() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFFFAFAFA))
          // Enable zoom and set DOM storage
          ..enableZoom(true)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: _handleProgress,
              onPageStarted: _handlePageStarted,
              onPageFinished: _handlePageFinished,
              onWebResourceError: _handleWebResourceError,
              onNavigationRequest: (NavigationRequest request) {
                // Allow all navigation within the WebView
                return NavigationDecision.navigate;
              },
            ),
          )
          // Use user-agent optimization to prevent mobile redirects
          ..setUserAgent(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
          // Open in browser button
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () {
              Navigator.pop(context);
              // Use the existing URL launcher to open in external browser
              UrlLauncherUtils.launchUrlWithErrorHandling(context, widget.url);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _controller),

          // Loading indicator - only a slim progress bar at the top
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _loadingProgress < 0.99 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress : null,
                  backgroundColor: Colors.transparent,
                  color: Colors.blue,
                  minHeight: 3,
                ),
              ),
            ),

          // Error message
          if (_hasError)
            Container(
              color: isDarkMode ? Colors.black87 : Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        color: isDarkMode ? Colors.red[300] : Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        _controller.reload();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
