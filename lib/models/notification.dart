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
    // Debug: Print the uploadedAt value to see what's in Firebase
    print(
      'DEBUG: Notification $id uploadedAt from Firebase: ${map['uploadedAt']}',
    );

    return Notification(
      id: id,
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      type: map['type'] ?? 'general',
      uploadedAt: map['uploadedAt'] ?? 0, // Use 0 instead of current time
      uploadedBy: map['uploadedBy'] ?? 'system',
      documentUrl: map['documentUrl'],
      semester: map['semester'],
      subject: map['subject'],
    );
  }

  // Get formatted time with short format (just now, 1 minute, 1 hour, 1 day, etc.)
  String getFormattedTime() {
    if (uploadedAt == 0) {
      return 'Unknown time';
    }

    final timestamp = DateTime.fromMillisecondsSinceEpoch(uploadedAt);
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute' : '$minutes minute';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour' : '$hours hour';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return days == 1 ? '1 day' : '$days day';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).round();
      return months == 1 ? '1 month' : '$months month';
    } else {
      final years = (difference.inDays / 365).round();
      return years == 1 ? '1 year' : '$years year';
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
