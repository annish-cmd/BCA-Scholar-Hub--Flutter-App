import 'package:flutter/foundation.dart';

class YouTubeVideo {
  final String id;  // Database key or custom ID
  final String title;
  final String? description;
  final String? category;
  final bool isActive;
  final int? uploadedAt;
  final String? uploadedBy;
  final String videoType;
  final String youtubeUrl;
  late final String youtubeVideoId;
  
  YouTubeVideo({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.isActive,
    this.uploadedAt,
    this.uploadedBy,
    required this.videoType,
    required this.youtubeUrl,
  }) {
    // Extract the YouTube video ID from the URL
    youtubeVideoId = _extractYouTubeId(youtubeUrl);
  }
  
  // Factory constructor to create a YouTubeVideo from a Firebase map
  factory YouTubeVideo.fromMap(String id, Map<dynamic, dynamic> map) {
    final video = YouTubeVideo(
      id: id,
      title: map['title'] ?? 'Untitled Video',
      description: map['description'],
      category: map['category'],
      isActive: map['isActive'] ?? false,
      uploadedAt: map['uploadedAt'],
      uploadedBy: map['uploadedBy'],
      videoType: map['videoType'] ?? 'youtube',
      youtubeUrl: map['youtubeUrl'] ?? '',
    );
    
    return video;
  }
  
  // Get formatted time ago string based on uploadedAt timestamp
  String get timeAgo {
    if (uploadedAt == null) return 'Recently';
    
    try {
      final DateTime date = DateTime.fromMillisecondsSinceEpoch(uploadedAt!);
      final Duration difference = DateTime.now().difference(date);
      
      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} years ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inMinutes} minutes ago';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error formatting time ago: $e');
      }
      return 'Recently';
    }
  }
  
  // Helper method to extract YouTube video ID from various URL formats
  String _extractYouTubeId(String url) {
    if (url.isEmpty) return '';
    
    // Handle youtu.be format
    if (url.contains('youtu.be')) {
      final uri = Uri.parse(url);
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    }
    
    // Handle youtube.com/watch?v= format and other variations
    final regExp = RegExp(
      r'.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    return match != null && match.groupCount >= 1 ? match.group(1)! : '';
  }
} 