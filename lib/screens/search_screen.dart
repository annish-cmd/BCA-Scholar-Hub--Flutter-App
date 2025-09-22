import 'package:flutter/material.dart';
import 'dart:async';
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
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _isLoading = true;
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();

  // Optimization: Debouncing and caching
  Timer? _debounceTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  final Map<String, List<SearchResult>> _searchCache = {};
  final Map<String, List<String>> _suggestionCache = {};

  @override
  void initState() {
    super.initState();
    // Initialize with all subjects from Firebase
    _loadAllSubjects();

    // Listen to focus changes to show/hide suggestions
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _searchController.text.isNotEmpty) {
        _loadSuggestions(_searchController.text);
      }
    });

    // Pre-warm cache with common single character searches
    _preWarmCache();
  }

  Future<void> _preWarmCache() async {
    // Pre-load common single character searches in background
    final commonSearches = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];

    // Delay to avoid blocking initial UI
    await Future.delayed(const Duration(milliseconds: 500));

    for (String search in commonSearches) {
      try {
        // Only pre-warm if not already cached
        if (!_searchCache.containsKey(search)) {
          final results = await SearchService.searchSubjects(search);
          _searchCache[search] = results;
        }

        // Small delay between requests to avoid overwhelming
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        // Ignore errors during pre-warming
      }
    }
  }

  Future<void> _loadAllSubjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allSubjects = await SearchService.getAllSubjects();
      setState(() {
        _searchResults = allSubjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final cacheKey = query.toLowerCase().trim();

    // Check cache first for immediate response
    if (_suggestionCache.containsKey(cacheKey)) {
      setState(() {
        _suggestions = _suggestionCache[cacheKey]!;
        _showSuggestions = _suggestions.isNotEmpty && _focusNode.hasFocus;
      });
      return;
    }

    try {
      final suggestions = await SearchService.getSearchSuggestions(query);

      // Cache the suggestions
      _suggestionCache[cacheKey] = suggestions;

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty && _focusNode.hasFocus;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
    }
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      _showSuggestions = false;
    });
    _performSearch(suggestion);
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    // Cancel previous timer if exists
    _debounceTimer?.cancel();

    // For empty queries, show all subjects immediately
    if (query.isEmpty) {
      _performSearchImmediate(query);
      return;
    }

    // Check cache first for immediate response
    final cacheKey = query.toLowerCase().trim();
    if (_searchCache.containsKey(cacheKey)) {
      setState(() {
        _searchResults = _searchCache[cacheKey]!;
        _isLoading = false;
        _isSearching = query.isNotEmpty;
        _showSuggestions = false;
      });
      return;
    }

    // Show loading immediately for new searches
    setState(() {
      _isSearching = query.isNotEmpty;
      _isLoading = true;
      _showSuggestions = false;
    });

    // Debounce the actual search
    _debounceTimer = Timer(_debounceDelay, () {
      _performSearchImmediate(query);
    });
  }

  void _performSearchImmediate(String query) async {
    final cacheKey = query.toLowerCase().trim();

    try {
      List<SearchResult> results;
      if (query.isEmpty) {
        results = await SearchService.getAllSubjects();
      } else {
        // Check cache again (in case it was populated while waiting)
        if (_searchCache.containsKey(cacheKey)) {
          setState(() {
            _searchResults = _searchCache[cacheKey]!;
            _isLoading = false;
          });
          return;
        }

        results = await SearchService.searchSubjects(query);

        // Cache the results for faster future access
        _searchCache[cacheKey] = results;

        // Also load suggestions for next time (non-blocking)
        if (query.length >= 1) {
          _loadSuggestions(query);
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    }
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
          // Search bar with suggestions
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Column(
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: localizations.translate('search_hint'),
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                                    setState(() {
                                      _showSuggestions = false;
                                    });
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
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        _performSearch(value);
                        if (value.isNotEmpty) {
                          _loadSuggestions(value);
                        } else {
                          setState(() {
                            _showSuggestions = false;
                          });
                        }
                      },
                      onTap: () {
                        if (_searchController.text.isNotEmpty &&
                            _suggestions.isNotEmpty) {
                          setState(() {
                            _showSuggestions = true;
                          });
                        }
                      },
                      autofocus: true,
                    ),
                  ),
                ),

                // Suggestions dropdown
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children:
                          _suggestions.take(5).map((suggestion) {
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.search,
                                size: 18,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                              title: RichText(
                                text: TextSpan(
                                  children: _highlightText(
                                    suggestion,
                                    _searchController.text,
                                    textColor,
                                    isDarkMode
                                        ? Colors.blue[300]!
                                        : Colors.blue,
                                  ),
                                ),
                              ),
                              onTap: () => _onSuggestionTap(suggestion),
                            );
                          }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Search results
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode ? Colors.blue[300]! : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isSearching ? 'Searching...' : 'Loading notes...',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : _searchResults.isEmpty
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
                                    localizations.translate('no_results_found'),
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
                                    localizations.translate('search_hint'),
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Semester ${result.semester}',
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.blue[300]
                                            : Colors.blue[700],
                                    fontSize: 12,
                                  ),
                                ),
                                if (result.firebaseNote != null &&
                                    result.firebaseNote!.category.isNotEmpty)
                                  Text(
                                    'Subject: ${result.firebaseNote!.category}',
                                    style: TextStyle(
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                            ),
                            onTap: () {
                              // Hide suggestions when navigating
                              setState(() {
                                _showSuggestions = false;
                              });

                              // Open PDF for the selected subject using Firebase note data
                              if (result.firebaseNote != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PdfViewerScreen(
                                          pdfNote:
                                              result.firebaseNote!.toPdfNote(),
                                        ),
                                  ),
                                );
                              } else {
                                // Fallback for notes without Firebase data
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PdfViewerScreen(
                                          pdfNote: PdfNote.fromLegacy(
                                            title: result.subject,
                                            subject:
                                                'Semester ${result.semester}',
                                            description:
                                                result.description ??
                                                'Notes for ${result.subject}',
                                            filename: 'test.pdf',
                                            thumbnailImage: 'c.jpg',
                                          ),
                                        ),
                                  ),
                                );
                              }
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

  // Helper method to highlight matching text in suggestions
  List<TextSpan> _highlightText(
    String text,
    String query,
    Color normalColor,
    Color highlightColor,
  ) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: TextStyle(color: normalColor))];
    }

    List<TextSpan> spans = [];
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: TextStyle(color: normalColor),
          ),
        );
      }

      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(color: highlightColor, fontWeight: FontWeight.bold),
        ),
      );

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(color: normalColor),
        ),
      );
    }

    return spans;
  }
}
