import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/notification.dart' as app_notification;

class NotificationProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<app_notification.Notification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;

  // Getters
  List<app_notification.Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // Constructor
  NotificationProvider() {
    _initializeNotifications();
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    await _loadNotifications();
    await _loadUnreadCount();
  }

  // Load notifications from database
  Future<void> _loadNotifications() async {
    try {
      _isLoading = true;
      notifyListeners();

      final notifications = await _databaseService.getNotifications();
      _notifications = notifications;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load unread count from shared preferences
  Future<void> _loadUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReadTimestamp = prefs.getInt('last_notification_read_time') ?? 0;
      
      // Count notifications that came after the last read time
      _unreadCount = _notifications
          .where((n) => n.uploadedAt > lastReadTimestamp)
          .length;
      
      notifyListeners();
    } catch (e) {
      // Default to 0 if there's an error
      _unreadCount = 0;
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setInt('last_notification_read_time', now);
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    await _loadNotifications();
    await _loadUnreadCount();
  }
} 