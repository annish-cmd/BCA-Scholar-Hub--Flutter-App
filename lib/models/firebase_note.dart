import 'pdf_note.dart';

class FirebaseNote {
  final String id;
  final String title;
  final String description;
  final String documentUrl;
  final String imageUrl;
  final String category;
  final String type;
  final String fileName;
  final String fileExtension;
  final int fileSize;
  final String storagePath;
  final String storageProvider;
  final int uploadedAt;
  final String uploadedBy;

  FirebaseNote({
    required this.id,
    required this.title,
    required this.description,
    required this.documentUrl,
    required this.imageUrl,
    required this.category,
    required this.type,
    required this.fileName,
    required this.fileExtension,
    required this.fileSize,
    required this.storagePath,
    required this.storageProvider,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory FirebaseNote.fromMap(String id, Map<dynamic, dynamic> map) {
    return FirebaseNote(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      documentUrl: map['documentUrl'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      type: map['type'] ?? '',
      fileName: map['fileName'] ?? '',
      fileExtension: map['fileExtension'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      storagePath: map['storagePath'] ?? '',
      storageProvider: map['storageProvider'] ?? '',
      uploadedAt: map['uploadedAt'] ?? 0,
      uploadedBy: map['uploadedBy'] ?? '',
    );
  }

  // Convert to PdfNote for compatibility with existing viewer
  PdfNote toPdfNote() {
    return PdfNote(
      id: id,
      title: title,
      subject: category,
      description: description,
      filename: documentUrl, // Using URL instead of local filename
      thumbnailImage: imageUrl,
    );
  }
  
  // Get semester from storage path
  String? get semester {
    // Extract from storagePath format like "notes/1st/english-i"
    final parts = storagePath.split('/');
    if (parts.length >= 2) {
      return parts[1]; // Return the semester part
    }
    return null;
  }
} 