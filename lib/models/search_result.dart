class SearchResult {
  final String subject;
  final int semester;
  final String? description;

  SearchResult({
    required this.subject,
    required this.semester,
    this.description,
  });
}
