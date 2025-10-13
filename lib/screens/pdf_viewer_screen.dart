import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/pdf_note.dart';
import '../utils/algo/LRU_Caching.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class PdfViewerScreen extends StatefulWidget {
  final PdfNote pdfNote;

  const PdfViewerScreen({super.key, required this.pdfNote});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final LRUCaching _cache = LRUCaching();
  bool _isLoading = false;
  String? _errorMessage;
  String? _cachedFilePath;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfNote.title), 
        elevation: 0,
        actions: [
          // Show cache status indicator
          if (_cachedFilePath != null)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(
                Icons.offline_pin,
                color: Colors.green,
                size: 20,
              ),
            ),
        ],
      ),
      body: _buildPdfViewer(),
    );
  }
  
  /// Loads PDF using LRU caching system
  Future<void> _loadPdf() async {
    // Check if the filename is a URL (starts with http or https)
    final bool isUrl = widget.pdfNote.filename.startsWith('http://') || 
                      widget.pdfNote.filename.startsWith('https://');
    
    if (isUrl) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Generate a safe filename from the URL
        final String safeFilename = _generateSafeFilename(widget.pdfNote.filename);
        
        // Get cached file path (downloads if not cached)
        final String cachedPath = await _cache.getFile(
          widget.pdfNote.filename,
          safeFilename,
        );
        
        setState(() {
          _cachedFilePath = cachedPath;
          _isLoading = false;
        });
        
        print('📁 PDF loaded from cache: $cachedPath');
      } catch (e) {
        setState(() {
          _errorMessage = _getUserFriendlyErrorMessage(e);
          _isLoading = false;
        });
        print('❌ Error loading PDF: $e');
      }
    } else {
      // For asset files, no caching needed
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Generates a safe filename from URL
  String _generateSafeFilename(String url) {
    // Extract filename from URL
    String filename = url.split('/').last;
    
    // Remove query parameters
    if (filename.contains('?')) {
      filename = filename.split('?').first;
    }
    
    // Ensure it has .pdf extension
    if (!filename.toLowerCase().endsWith('.pdf')) {
      filename = '${widget.pdfNote.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';
    }
    
    // Clean filename for filesystem
    filename = filename.replaceAll(RegExp(r'[^\w\s.-]'), '_');
    
    return filename;
  }

  /// Converts technical errors to user-friendly messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection and try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network settings.';
        case DioExceptionType.badResponse:
          return 'Server error. The PDF file might be temporarily unavailable.';
        case DioExceptionType.cancel:
          return 'Download was cancelled. Please try again.';
        case DioExceptionType.unknown:
          return 'Network error. Please check your internet connection.';
        default:
          return 'Unable to download PDF. Please check your internet connection.';
      }
    } else if (error.toString().toLowerCase().contains('connection')) {
      return 'No internet connection. Please check your network settings.';
    } else if (error.toString().toLowerCase().contains('timeout')) {
      return 'Connection timeout. Please try again.';
    } else {
      return 'Unable to load PDF. Please check your internet connection and try again.';
    }
  }

  Widget _buildPdfViewer() {
    // Show loading indicator
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Downloading for offline access',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show error message with beautiful UI
    if (_errorMessage != null) {
      return _buildErrorUI();
    }

    // Check if the filename is a URL (starts with http or https)
    final bool isUrl = widget.pdfNote.filename.startsWith('http://') || 
                      widget.pdfNote.filename.startsWith('https://');
    
    if (isUrl) {
      // Load from cached file
      if (_cachedFilePath != null) {
        return SfPdfViewer.file(
          File(_cachedFilePath!),
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
        );
      } else {
        // Fallback to network if cache failed
        return SfPdfViewer.network(
          widget.pdfNote.filename,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
        );
      }
    } else {
      // Load from assets
      return SfPdfViewer.asset(
        'assets/pdfs/${widget.pdfNote.filename}',
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
      );
    }
  }

  /// Builds a beautiful and professional error UI
  Widget _buildErrorUI() {
    final bool isConnectionError = _errorMessage!.toLowerCase().contains('internet') || 
                                  _errorMessage!.toLowerCase().contains('connection') ||
                                  _errorMessage!.toLowerCase().contains('network');
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.grey[100]!,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated error icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isConnectionError ? Colors.orange[50] : Colors.red[50],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isConnectionError ? Colors.orange[200]! : Colors.red[200]!,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isConnectionError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                  size: 80,
                  color: isConnectionError ? Colors.orange[600] : Colors.red[600],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Error title
              Text(
                isConnectionError ? 'No Internet Connection' : 'Unable to Load PDF',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Error message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Retry button
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                      _loadPdf();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Go back button
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Helpful tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isConnectionError 
                          ? 'Tip: Check your WiFi or mobile data connection'
                          : 'Tip: The PDF will be available offline once downloaded',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}
