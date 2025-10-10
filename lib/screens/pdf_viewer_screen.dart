import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/pdf_note.dart';

class PdfViewerScreen extends StatelessWidget {
  final PdfNote pdfNote;

  const PdfViewerScreen({super.key, required this.pdfNote});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pdfNote.title), 
        elevation: 0,
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
  
}
