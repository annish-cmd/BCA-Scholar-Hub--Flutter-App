import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '../models/pdf_note.dart';
import 'pdf_options_screen.dart';
import '../widgets/thumbnail_image.dart';
import '../utils/favorites_cache_manager.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  // Static list of PDF notes accessible throughout the app
  static final List<PdfNote> pdfNotes = [
    PdfNote(
      id: 'c_programming_notes',
      title: 'C Programming Notes',
      subject: 'Programming',
      description: 'Complete guide to C programming fundamentals',
      filename: 'test.pdf',
      thumbnailImage: 'c.jpg',
    ),
    PdfNote(
      id: 'java_basics',
      title: 'Java Basics',
      subject: 'Programming',
      description: 'Core concepts of Java programming',
      filename: 'test.pdf',
      thumbnailImage: 'java.jpg',
    ),
    PdfNote(
      id: 'flutter_tutorial',
      title: 'Flutter Tutorial',
      subject: 'Mobile Development',
      description: 'Step by step Flutter development guide',
      filename: 'test.pdf',
      thumbnailImage: 'flutter.png',
    ),
    PdfNote(
      id: 'python_for_beginners',
      title: 'Python for Beginners',
      subject: 'Programming',
      description: 'Learn Python from scratch',
      filename: 'test.pdf',
      thumbnailImage: 'Python.jpg',
    ),
  ];

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  // List of image data with captions
  final List<Map<String, String>> _imageData = [
    {
      'image': 'c.jpg',
      'title': 'C Programming',
      'description': 'The foundation of modern programming languages',
    },
    {
      'image': 'java.jpg',
      'title': 'Java',
      'description': 'Write once, run anywhere',
    },
    {
      'image': 'flutter.png',
      'title': 'Flutter',
      'description': 'Beautiful native apps in record time',
    },
    {
      'image': 'Python.jpg',
      'title': 'Python',
      'description': 'Simple, readable and powerful language',
    },
    {
      'image': 'javascript.jpg',
      'title': 'JavaScript',
      'description': 'The language of the web',
    },
    {
      'image': 'networking.jpg',
      'title': 'Networking',
      'description': 'Connect systems and enable communication',
    },
    {
      'image': 'dotnet.jpg',
      'title': '.NET',
      'description': 'Build any type of app that runs on any platform',
    },
  ];

  // Expose the PDF notes for other screens to use
  List<PdfNote> getPdfNotes() {
    return HomeContentScreen.pdfNotes;
  }

  @override
  void initState() {
    super.initState();
    // Preload favorites data in background for instant loading
    Future.delayed(Duration(milliseconds: 500), () {
      FavoritesCacheManager().preloadInBackground();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;

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
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                color:
                    isDarkMode ? Colors.black26 : Colors.white.withAlpha(179),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? Colors.black38
                              : Colors.blue.withAlpha(26),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SizedBox(
                      height: 160,
                      child: FlutterCarousel(
                        items:
                            _imageData.map((item) {
                              return Builder(
                                builder: (BuildContext context) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(51),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        'assets/images/${item['image']}',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                        options: CarouselOptions(
                          height: 160.0,
                          viewportFraction: 0.9,
                          initialPage: 0,
                          enableInfiniteScroll: true,
                          reverse: false,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 2),
                          autoPlayAnimationDuration: const Duration(
                            milliseconds: 500,
                          ),
                          autoPlayCurve: Curves.easeInOut,
                          enlargeCenterPage: true,
                          enlargeStrategy: CenterPageEnlargeStrategy.height,
                          onPageChanged: (index, reason) {
                            // No need to track current slide index
                          },
                          scrollDirection: Axis.horizontal,
                          showIndicator: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color:
                    isDarkMode ? Colors.black26 : Colors.white.withAlpha(179),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? Colors.black38
                              : Colors.blue.withAlpha(26),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      localizations.translate('Popular Notes'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: HomeContentScreen.pdfNotes.length,
                      itemBuilder: (context, index) {
                        final note = HomeContentScreen.pdfNotes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: isDarkMode ? Colors.grey[850] : Colors.white,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          PdfOptionsScreen(pdfNote: note),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    bottomLeft: Radius.circular(10),
                                  ),
                                  child: SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: ThumbnailImage(
                                      imageUrl: note.thumbnailImage,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      isDarkMode: isDarkMode,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          note.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          note.subject,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                isDarkMode
                                                    ? Colors.blue[200]
                                                    : Colors.blue[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          note.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
