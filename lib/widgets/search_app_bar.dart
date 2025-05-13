import 'package:flutter/material.dart';
import '../services/search_service.dart';
import '../models/search_result.dart';
import '../models/pdf_note.dart';
import '../screens/pdf_viewer_screen.dart';
import '../utils/app_localizations.dart';

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function onClose;
  final bool isDarkMode;

  const SearchAppBar({
    super.key,
    required this.onClose,
    required this.isDarkMode,
  });

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchAppBarState extends State<SearchAppBar> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();

    // Add a listener to focus to show the overlay when focused
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hideOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = SearchService.searchSubjects(query);
      }
    });

    // Update the overlay when search results change
    _updateOverlay();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    // Only show overlay if it's not already showing
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(builder: (context) => _buildOverlay());

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  Widget _buildOverlay() {
    final screenSize = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight;
    final startPosition = statusBarHeight + appBarHeight;

    final localizations = AppLocalizations.of(context);
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;

    return Positioned(
      top: startPosition,
      left: 0,
      width: screenSize.width,
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxHeight: screenSize.height * 0.6),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF121212) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51), // 0.2 opacity = alpha 51
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child:
              _searchController.text.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 60,
                            color:
                                widget.isDarkMode
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.translate('search_hint'),
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  widget.isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : _searchResults.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color:
                                widget.isDarkMode
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.translate('no_results_found'),
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  widget.isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount:
                        _searchResults.length > 10
                            ? 10
                            : _searchResults.length, // Limit to 10 results
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              widget.isDarkMode
                                  ? Colors.blue[900]
                                  : Colors.blue[100],
                          child: Text(
                            '${result.semester}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  widget.isDarkMode
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
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Semester ${result.semester}',
                          style: TextStyle(
                            color:
                                widget.isDarkMode
                                    ? Colors.blue[300]
                                    : Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          _hideOverlay();
                          widget.onClose(); // Close the search app bar

                          // Navigate to the PDF viewer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PdfViewerScreen(
                                    pdfNote: PdfNote.fromLegacy(
                                      title: result.subject,
                                      subject: 'Semester ${result.semester}',
                                      description:
                                          'Notes for ${result.subject}',
                                      filename: 'test.pdf',
                                      thumbnailImage: 'c.jpg',
                                    ),
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: Colors.white,
        onPressed: () {
          _hideOverlay();
          widget.onClose();
        },
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).translate('search_hint'),
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
        onChanged: _performSearch,
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            color: Colors.white,
            onPressed: () {
              _searchController.clear();
              _performSearch('');
            },
          ),
      ],
    );
  }
}
