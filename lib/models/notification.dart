import 'package:flutter/material.dart';

class Notification {
  final String id;
  final String title;
  final String message;
  final String type; // 'new_note', 'update', 'welcome', etc.
  final int uploadedAt;
  final String uploadedBy;
  final String? documentUrl;
  final String? semester;
  final String? subject;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.uploadedAt,
    required this.uploadedBy,
    this.documentUrl,
    this.semester,
    this.subject,
  });

  factory Notification.fromMap(String id, Map<dynamic, dynamic> map) {
    return Notification(
      id: id,
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      type: map['type'] ?? 'general',
      uploadedAt: map['uploadedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      uploadedBy: map['uploadedBy'] ?? 'system',
      documentUrl: map['documentUrl'],
      semester: map['semester'],
      subject: map['subject'],
    );
  }

  // Get formatted time (e.g., "2 min ago", "1 hour ago", "Yesterday", "2 days ago")
  String getFormattedTime() {
    final now = DateTime.now();
    final timestamp = DateTime.fromMillisecondsSinceEpoch(uploadedAt);
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Get icon based on notification type
  IconData getIcon() {
    switch (type) {
      case 'new_note':
        return Icons.note_add;
      case 'update':
        return Icons.update;
      case 'welcome':
        return Icons.celebration;
      default:
        return Icons.notifications;
    }
  }
} 