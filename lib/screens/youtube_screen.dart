import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> {
  // List of videos to display
  final List<YouTubeVideoModel> _videos = [
    YouTubeVideoModel(
      id: 'g4Ffdh41vRQ', // Extract ID from URL
      title: 'Python Course for BCA, BIT, CSIT, BscCSIT, BIM Students',
      subtitle: 'Python Programming',
      timeAgo: '1 years ago',
      tags: 'Python',
    ),
    YouTubeVideoModel(
      id: 'W6NZfCO5SIk', // JavaScript tutorial
      title:
          'JavaScript Course for Beginners – Your First Step to Web Development',
      subtitle: 'JavaScript Programming',
      timeAgo: '5 years ago',
      tags: 'Web Dev',
    ),
    YouTubeVideoModel(
      id: '1xipg02Wu8s', // Flutter tips
      title: 'Basic Flutter Tips and Tricks',
      subtitle: 'Flutter Development',
      timeAgo: '2 years ago',
      tags: 'Mobile Dev',
    ),
    YouTubeVideoModel(
      id: 'xTtL8E4LzTQ', // Java beginners guide
      title: 'Java Beginners Guide',
      subtitle: 'Java Programming',
      timeAgo: '3 years ago',
      tags: 'Java',
    ),
  ];

  // Helper method to extract YouTube video ID from URL
  static String? extractVideoIdFromUrl(String url) {
    RegExp regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    return (match != null && match.group(7)!.length == 11)
        ? match.group(7)
        : null;
  }

  // Example of how to add a video using URL:
  // void addVideo(String url, String title, String subtitle, String timeAgo, String tags) {
  //   final videoId = extractVideoIdFromUrl(url);
  //   if (videoId != null) {
  //     setState(() {
  //       _videos.add(YouTubeVideoModel(
  //         id: videoId,
  //         title: title,
  //         subtitle: subtitle,
  //         timeAgo: timeAgo,
  //         tags: tags,
  //       ));
  //       _controllers.add(YoutubePlayerController(
  //         initialVideoId: videoId,
  //         flags: const YoutubePlayerFlags(
  //           autoPlay: true,
  //           mute: false,
  //           disableDragSeek: false,
  //           loop: false,
  //           isLive: false,
  //           forceHD: true,
  //           enableCaption: true,
  //         ),
  //       ));
  //     });
  //   }
  // }

  // Pre-initialize controllers for faster loading
  late List<YoutubePlayerController> _controllers;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each video
    _controllers =
        _videos
            .map(
              (video) => YoutubePlayerController(
                initialVideoId: video.id,
                flags: const YoutubePlayerFlags(
                  autoPlay: true,
                  mute: false,
                  disableDragSeek: false,
                  loop: false,
                  isLive: false,
                  forceHD: true,
                  enableCaption: true,
                ),
              ),
            )
            .toList();

    // Simulate loading time
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
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
              isDarkMode ? Colors.black12 : Colors.blue.withOpacity(0.2),
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
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildYoutubeVideoCard(
                        context,
                        isDarkMode,
                        textColor,
                        _videos[index],
                        index,
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildYoutubeVideoCard(
    BuildContext context,
    bool isDarkMode,
    Color textColor,
    YouTubeVideoModel video,
    int index,
  ) {
    return Card(
      elevation: 8,
      shadowColor:
          isDarkMode
              ? Colors.purple.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
      color: isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                            videoId: video.id,
                            title: video.title,
                            controller: _controllers[index],
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
                  tag: 'video_${video.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: Image.network(
                      'https://img.youtube.com/vi/${video.id}/maxresdefault.jpg',
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
                        color: Colors.black.withOpacity(0.2),
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
                if (video.tags.isNotEmpty)
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
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        video.tags,
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
                  video.subtitle,
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

  const YoutubePlayerPage({
    super.key,
    required this.videoId,
    required this.title,
    required this.controller,
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

    // Get screen size to handle orientation properly
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          widget.controller.toggleFullScreenMode();
          return false;
        }
        return true;
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

// Model class for YouTube videos
class YouTubeVideoModel {
  final String id;
  final String title;
  final String subtitle;
  final String timeAgo;
  final String tags;

  YouTubeVideoModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.tags = '',
  });
}
