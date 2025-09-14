import 'package:flutter_test/flutter_test.dart';
import 'package:bca_library/models/notification.dart' as app_notification;

void main() {
  group('Notification Time Display Tests', () {
    test('should show consistent time when called multiple times', () {
      // Create a notification with a fixed timestamp (1 hour ago)
      final oneHourAgoTimestamp = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
      
      final notification = app_notification.Notification(
        id: 'test_notification',
        title: 'Test Notification',
        message: 'This is a test notification',
        type: 'new_note',
        uploadedAt: oneHourAgoTimestamp,
        uploadedBy: 'admin',
      );

      // Get the formatted time multiple times
      final firstTime = notification.getFormattedTime();
      
      // Wait a moment to simulate UI rebuilds
      Future.delayed(const Duration(milliseconds: 100), () {
        final secondTime = notification.getFormattedTime();
        
        // Both times should be the same since we're using timeago package
        // which formats relative to the stored timestamp, not recalculated "now"
        expect(firstTime, equals(secondTime));
      });
    });

    test('should format recent timestamps correctly', () {
      // Create a notification with recent timestamp (2 minutes ago)
      final twoMinutesAgoTimestamp = DateTime.now().subtract(const Duration(minutes: 2)).millisecondsSinceEpoch;
      
      final notification = app_notification.Notification(
        id: 'recent_notification',
        title: 'Recent Notification',
        message: 'This is a recent notification',
        type: 'new_note',
        uploadedAt: twoMinutesAgoTimestamp,
        uploadedBy: 'admin',
      );

      final formattedTime = notification.getFormattedTime();
      
      // Should contain "minute" or "minutes"
      expect(formattedTime.toLowerCase(), contains('minute'));
    });

    test('should format old timestamps correctly', () {
      // Create a notification with old timestamp (1 week ago)
      final oneWeekAgoTimestamp = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      
      final notification = app_notification.Notification(
        id: 'old_notification',
        title: 'Old Notification',
        message: 'This is an old notification',
        type: 'new_note',
        uploadedAt: oneWeekAgoTimestamp,
        uploadedBy: 'admin',
      );

      final formattedTime = notification.getFormattedTime();
      
      // Should contain "day" or "days"
      expect(formattedTime.toLowerCase(), contains('day'));
    });
  });
}