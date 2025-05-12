import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import '../services/search_service.dart';
import '../models/search_result.dart';
import '../models/pdf_note.dart';
import 'pdf_viewer_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Initialize with all subjects
    _searchResults = SearchService.getAllSubjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults = SearchService.getAllSubjects();
        _isSearching = false;
      } else {
        _searchResults = SearchService.searchSubjects(query);
        _isSearching = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
    final inputColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200]!;

    // Get translations
    final localizations = AppLocalizations.of(context);
    final title = localizations.translate('search');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [const Color(0xFF121212), const Color(0xFF1A1A1A)]
                  : [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText:
                        localizations.translate('search_hint') ??
                        'Search subjects...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.blue[300] : Colors.blue,
                    ),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            )
                            : null,
                    filled: true,
                    fillColor: inputColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: _performSearch,
                ),
              ),
            ),
          ),

          // Search results
          Expanded(
            child:
                _searchResults.isEmpty
                    ? Center(
                      child:
                          _isSearching
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 60,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    localizations.translate(
                                          'no_results_found',
                                        ) ??
                                        'No results found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 60,
                                    color:
                                        isDarkMode
                                            ? Colors.blue[300]
                                            : Colors.blue,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    localizations.translate('search_hint') ??
                                        'Search subjects...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: cardColor,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  isDarkMode
                                      ? Colors.blue[900]
                                      : Colors.blue[100],
                              child: Text(
                                '${result.semester}',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.blue[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              result.subject,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              'Semester ${result.semester}',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.blue[300]
                                        : Colors.blue[700],
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                            ),
                            onTap: () {
                              // Open PDF for the selected subject
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PdfViewerScreen(
                                        pdfNote: PdfNote(
                                          title: result.subject,
                                          subject:
                                              'Semester ${result.semester}',
                                          description:
                                              'Notes for ${result.subject}',
                                          filename: 'test.pdf',
                                          thumbnailImage:
                                              'c.jpg', // Default thumbnail
                                        ),
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
