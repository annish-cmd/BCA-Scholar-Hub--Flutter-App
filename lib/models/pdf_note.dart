class PdfNote {
  final String id;
  final String title;
  final String subject;
  final String description;
  final String filename;
  final String thumbnailImage;

  PdfNote({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.filename,
    required this.thumbnailImage,
  });

  // For backward compatibility, create id from filename if not provided
  factory PdfNote.fromLegacy({
    required String title,
    required String subject,
    required String description,
    required String filename,
    required String thumbnailImage,
  }) {
    // Generate a unique ID based on the title and subject
    String id =
        '${title.toLowerCase().replaceAll(' ', '_')}_${subject.toLowerCase().replaceAll(' ', '_')}';

    return PdfNote(
      id: id,
      title: title,
      subject: subject,
      description: description,
      filename: filename,
      thumbnailImage: thumbnailImage,
    );
  }

  // JSON serialization for caching
  factory PdfNote.fromJson(Map<String, dynamic> json) {
    return PdfNote(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      filename: json['filename'] ?? '',
      thumbnailImage: json['thumbnailImage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'description': description,
      'filename': filename,
      'thumbnailImage': thumbnailImage,
    };
  }
}
