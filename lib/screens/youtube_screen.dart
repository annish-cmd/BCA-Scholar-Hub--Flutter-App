import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/database_service.dart';
import '../models/youtube_video.dart';

class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> {
  // List of hardcoded videos to display
  final List<YouTubeVideo> _hardcodedVideos = [
    YouTubeVideo(
      id: 'g4Ffdh41vRQ',
      title: 'Python Course for BCA, BIT, CSIT, BscCSIT, BIM Students',
      description: 'Learn Python programming for BCA and other students',
      category: 'Python Programming',
      isActive: true,
      uploadedAt: DateTime.now().millisecondsSinceEpoch - const Duration(days: 180).inMilliseconds,
      videoType: 'youtube',
      youtubeUrl: 'https://youtu.be/g4Ffdh41vRQ',
    ),
    YouTubeVideo(
      id: 'W6NZfCO5SIk',
      title: 'JavaScript Course for Beginners – Your First Step to Web Development',
      description: 'Learn JavaScript fundamentals for web development',
      category: 'Web Dev',
      isActive: true,
      uploadedAt: DateTime.now().millisecondsSinceEpoch - const Duration(days: 240).inMilliseconds,
      videoType: 'youtube',
      youtubeUrl: 'https://youtu.be/W6NZfCO5SIk',
    ),
    YouTubeVideo(
      id: '1xipg02Wu8s',
      title: 'Basic Flutter Tips and Tricks',
      description: 'Flutter development tips for beginners',
      category: 'Mobile Dev',
      isActive: true,
      uploadedAt: DateTime.now().millisecondsSinceEpoch - const Duration(days: 270).inMilliseconds,
      videoType: 'youtube',
      youtubeUrl: 'https://youtu.be/1xipg02Wu8s',
    ),
    YouTubeVideo(
      id: 'xTtL8E4LzTQ',
      title: 'Java Beginners Guide',
      description: 'Java programming basics for beginners',
      category: 'Java',
      isActive: true,
      uploadedAt: DateTime.now().millisecondsSinceEpoch - const Duration(days: 270).inMilliseconds,
      videoType: 'youtube',
      youtubeUrl: 'https://youtu.be/xTtL8E4LzTQ',
    ),
  ];

  // Combined list of videos (hardcoded + from database)
  List<YouTubeVideo> _allVideos = [];
  List<YoutubePlayerController> _controllers = [];
  bool _isLoading = true;
  final DatabaseService _databaseService = DatabaseService();
  bool _showingOnlyHardcoded = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Start with hardcoded videos
      List<YouTubeVideo> combinedVideos = List.from(_hardcodedVideos);
      
      // Fetch videos from Firebase
      final dbVideos = await _databaseService.getYoutubeVideos();
      
      if (dbVideos.isNotEmpty) {
        // Add database videos to our list
        combinedVideos.addAll(dbVideos);
        _showingOnlyHardcoded = false;
      } else {
        _showingOnlyHardcoded = true;
      }
      
      // Sort videos by uploadedAt timestamp (newest first)
      combinedVideos.sort((a, b) {
        // If uploadedAt is null, use current time for sorting
        final aTime = a.uploadedAt ?? DateTime.now().millisecondsSinceEpoch;
        final bTime = b.uploadedAt ?? DateTime.now().millisecondsSinceEpoch;
        // Reverse order (newest first - LIFO)
        return bTime.compareTo(aTime);
      });
      
      // Update state with all videos
      if (mounted) {
        setState(() {
          _allVideos = combinedVideos;
          
          // Initialize controllers for each video
          _controllers = _allVideos.map((video) {
            return YoutubePlayerController(
              initialVideoId: video.youtubeVideoId,
              flags: const YoutubePlayerFlags(
                autoPlay: true,
                mute: false,
                disableDragSeek: false,
                loop: false,
                isLive: false,
                forceHD: true,
                enableCaption: true,
              ),
            );
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading videos: $e');
      // If there's an error, at least show hardcoded videos
      if (mounted) {
        setState(() {
          _allVideos = List.from(_hardcodedVideos);
          _controllers = _allVideos.map((video) {
            return YoutubePlayerController(
              initialVideoId: video.youtubeVideoId,
              flags: const YoutubePlayerFlags(
                autoPlay: true,
                mute: false,
                disableDragSeek: false,
                loop: false,
                isLive: false,
                forceHD: true,
                enableCaption: true,
              ),
            );
          }).toList();
          _isLoading = false;
          _showingOnlyHardcoded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;

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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor:
              isDarkMode
                  ? Colors.black12
                  : Colors.blue.withAlpha(51), // 0.2 opacity = alpha 51
          elevation: 0,
          title: Text(
            'Educational Videos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Bauhaus 93',
            ),
          ),
        ),
        body:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode ? Colors.purpleAccent : Colors.blue,
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _loadVideos,
                  child: Column(
                    children: [
                      if (_showingOnlyHardcoded)
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Showing default videos. Admin-added videos will appear here when available.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _allVideos.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildYoutubeVideoCard(
                                context,
                                isDarkMode,
                                textColor,
                                _allVideos[index],
                                index,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildYoutubeVideoCard(
    BuildContext context,
    bool isDarkMode,
    Color textColor,
    YouTubeVideo video,
    int index,
  ) {
    return Card(
      color:
          isDarkMode
              ? Colors.purple.withAlpha(77) // 0.3 opacity = alpha 77
              : Colors.blue.withAlpha(77), // 0.3 opacity = alpha 77
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          YoutubePlayerPage(
                            videoId: video.youtubeVideoId,
                            title: video.title,
                            controller: _controllers[index],
                            description: video.description,
                          ),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    const begin = Offset(0.0, 0.1);
                    const end = Offset.zero;
                    const curve = Curves.easeOutQuint;

                    var tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Hero(
                  tag: 'video_${video.youtubeVideoId}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: Image.network(
                      'https://img.youtube.com/vi/${video.youtubeVideoId}/maxresdefault.jpg',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(
                              Icons.error,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(
                          51,
                        ), // 0.2 opacity = alpha 51
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                if (video.category != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(200),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(
                              51,
                            ), // 0.2 opacity = alpha 51
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        video.category!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.category ?? 'Educational Video',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  video.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      video.timeAgo,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// YouTube Player Page
class YoutubePlayerPage extends StatefulWidget {
  final String videoId;
  final String title;
  final YoutubePlayerController controller;
  final String? description; // Add description field

  const YoutubePlayerPage({
    super.key,
    required this.videoId,
    required this.title,
    required this.controller,
    this.description, // Make description optional
  });

  @override
  State<YoutubePlayerPage> createState() => _YoutubePlayerPageState();
}

class _YoutubePlayerPageState extends State<YoutubePlayerPage>
    with WidgetsBindingObserver {
  late bool _isPlayerReady;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _isPlayerReady = false;
    WidgetsBinding.instance.addObserver(this);

    // Configure controller to handle fullscreen changes
    widget.controller.addListener(_controllerListener);
  }

  void _controllerListener() {
    if (_isPlayerReady && mounted) {
      setState(() {
        _isFullScreen = widget.controller.value.isFullScreen;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause video when app goes to background
    if (state == AppLifecycleState.paused) {
      widget.controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_controllerListener);
    super.dispose();
  }

  @override
  void deactivate() {
    widget.controller.pause();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          // This means the pop was intercepted due to canPop being false
          if (_isFullScreen) {
            widget.controller.toggleFullScreenMode();
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        appBar:
            _isFullScreen
                ? null
                : AppBar(
                  backgroundColor:
                      isDarkMode ? const Color(0xFF1F1F1F) : Colors.blue,
                  title: Text(
                    'Educational Video',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Bauhaus 93',
                    ),
                  ),
                  iconTheme: const IconThemeData(color: Colors.white),
                  elevation: 0,
                ),
        body: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape && _isFullScreen) {
                // Full landscape mode for the player
                return Center(
                  child: YoutubePlayer(
                    controller: widget.controller,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.red,
                    progressColors: const ProgressBarColors(
                      playedColor: Colors.red,
                      handleColor: Colors.redAccent,
                    ),
                    onReady: () {
                      setState(() {
                        _isPlayerReady = true;
                      });
                      widget.controller.play();
                    },
                  ),
                );
              }

              // Regular view with scrolling content
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'video_${widget.videoId}',
                      child: YoutubePlayer(
                        controller: widget.controller,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Colors.red,
                        progressColors: const ProgressBarColors(
                          playedColor: Colors.red,
                          handleColor: Colors.redAccent,
                        ),
                        onReady: () {
                          setState(() {
                            _isPlayerReady = true;
                          });
                          widget.controller.play();
                        },
                        bottomActions: [
                          const SizedBox(width: 14.0),
                          CurrentPosition(),
                          const SizedBox(width: 8.0),
                          ProgressBar(
                            isExpanded: true,
                            colors: const ProgressBarColors(
                              playedColor: Colors.red,
                              handleColor: Colors.redAccent,
                            ),
                          ),
                          RemainingDuration(),
                          const PlaybackSpeedButton(),
                          IconButton(
                            icon: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              widget.controller.toggleFullScreenMode();
                            },
                          ),
                        ],
                      ),
                    ),
                    if (!_isFullScreen)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            if (widget.description != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                widget.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode 
                                      ? Colors.grey[300] 
                                      : Colors.grey[800],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Additional video information
                            Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  size: 20,
                                  color:
                                      isDarkMode
                                          ? Colors.blue[300]
                                          : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Educational Content',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
