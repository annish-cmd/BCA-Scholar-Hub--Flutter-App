import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/database_service.dart';
import '../models/notification.dart' as app_notification;

class NotificationProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<app_notification.Notification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  StreamSubscription<List<app_notification.Notification>>?
  _notificationSubscription;
  String? _currentUserId;

  // Getters
  List<app_notification.Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // Constructor
  NotificationProvider() {
    _initializeNotifications();
    _listenToAuthChanges();
  }

  // Listen to auth state changes
  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((User? user) {
      if (user?.uid != _currentUserId) {
        _currentUserId = user?.uid;
        _resetNotifications();
        if (user != null) {
          _startNotificationStream();
        }
      }
    });
  }

  // Reset notifications when user changes
  void _resetNotifications() {
    _notifications = [];
    _unreadCount = 0;
    _isLoading = true;
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    notifyListeners();
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _startNotificationStream();
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start real-time notification stream
  void _startNotificationStream() {
    _isLoading = true;
    notifyListeners();

    _notificationSubscription = _databaseService
        .getNotificationsStream()
        .listen(
          (notifications) async {
            _notifications = notifications;
            _isLoading = false;
            await _loadUnreadCount();
            notifyListeners();
          },
          onError: (error) {
            print('Error in notification stream: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Load unread count from shared preferences (user-specific)
  Future<void> _loadUnreadCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _unreadCount = 0;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final key = 'last_notification_read_time_${user.uid}';
      final lastReadTimestamp = prefs.getInt(key) ?? 0;

      // Count notifications that came after the last read time
      _unreadCount =
          _notifications
              .where(
                (n) => n.uploadedAt > lastReadTimestamp && n.type != 'welcome',
              )
              .length;

      notifyListeners();
    } catch (e) {
      // Default to 0 if there's an error
      _unreadCount = 0;
      notifyListeners();
    }
  }

  // Mark all notifications as read (user-specific)
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final key = 'last_notification_read_time_${user.uid}';
      final now = DateTime.now().millisecondsSinceEpoch;

      await prefs.setInt(key, now);
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  // Refresh notifications (manual refresh)
  Future<void> refreshNotifications() async {
    // The stream will automatically update, but we can restart it if needed
    if (_currentUserId != null) {
      _notificationSubscription?.cancel();
      _startNotificationStream();
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
