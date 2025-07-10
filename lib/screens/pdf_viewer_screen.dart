import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/pdf_note.dart';
import 'dart:io';

class PdfViewerScreen extends StatelessWidget {
  final PdfNote pdfNote;

  const PdfViewerScreen({super.key, required this.pdfNote});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pdfNote.title), 
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePdf(context),
          ),
        ],
      ),
      body: _buildPdfViewer(),
    );
  }
  
  Widget _buildPdfViewer() {
    // Check if the filename is a URL (starts with http or https)
    final bool isUrl = pdfNote.filename.startsWith('http://') || 
                      pdfNote.filename.startsWith('https://');
    
    if (isUrl) {
      // Load from network
      return SfPdfViewer.network(
        pdfNote.filename,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
      );
    } else {
      // Load from assets
      return SfPdfViewer.asset(
        'assets/pdfs/${pdfNote.filename}',
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
      );
    }
  }
  
  Future<void> _downloadPdf(BuildContext context) async {
    // Check if the filename is a URL
    final bool isUrl = pdfNote.filename.startsWith('http://') || 
                      pdfNote.filename.startsWith('https://');
    
    if (!isUrl) {
      // Show snackbar for local files
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This PDF is already available offline')),
      );
      return;
    }
    
    // Request storage permission
    var status = await Permission.storage.request();
    if (status.isGranted) {
      // Get the downloads directory
      final externalDir = await getExternalStorageDirectory();
      
      if (externalDir != null) {
        // Start download
        await FlutterDownloader.enqueue(
          url: pdfNote.filename,
          savedDir: externalDir.path,
          fileName: '${pdfNote.title}${pdfNote.filename.substring(pdfNote.filename.lastIndexOf('.'))}',
          showNotification: true,
          openFileFromNotification: true,
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started')),
        );
      }
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied')),
      );
    }
  }
  
  Future<void> _sharePdf(BuildContext context) async {
    // Check if the filename is a URL
    final bool isUrl = pdfNote.filename.startsWith('http://') || 
                      pdfNote.filename.startsWith('https://');
    
    if (isUrl) {
      // Share the URL
      await Share.share(
        'Check out this PDF: ${pdfNote.filename}',
        subject: pdfNote.title,
      );
    } else {
      // For local files, we'd need to extract the asset first
      // This is simplified for now
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing local PDFs is not supported yet')),
      );
    }
  }
}
