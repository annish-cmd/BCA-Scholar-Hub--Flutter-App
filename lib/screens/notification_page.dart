import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/notification_provider.dart';
import '../models/notification.dart' as app_notification;
import 'pdf_viewer_screen.dart';
import '../models/pdf_note.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    // Mark notifications as read when this page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.blue,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.white),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false).refreshNotifications();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          final _notifications = notificationProvider.notifications;
          final _isLoading = notificationProvider.isLoading;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [const Color(0xFF121212), const Color(0xFF1A1A1A)]
                    : [Colors.blue[50]!, Colors.purple[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 80,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => 
                            notificationProvider.refreshNotifications(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          separatorBuilder: (context, index) {
                            // If the current notification is welcome or the next one is welcome,
                            // use a more prominent divider
                            if (index < _notifications.length - 1 && 
                                (_notifications[index].type == 'welcome' || 
                                 _notifications[index + 1].type == 'welcome')) {
                              return Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Divider(
                                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                    thickness: 1,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            }
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: isDarkMode ? const Color(0xFF232323) : Colors.white,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDarkMode ? Colors.blue[900] : Colors.blue[100],
                                  child: Icon(
                                    notif.getIcon(),
                                    color: isDarkMode ? Colors.white : Colors.blue,
                                  ),
                                ),
                                title: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  notif.message,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                                trailing: notif.type == 'welcome' 
                                  ? null  // Don't show date for welcome notification
                                  : Text(
                                    notif.getFormattedTime(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                onTap: () {
                                  _handleNotificationTap(notif);
                                },
                              ),
                            );
                          },
                        ),
                      ),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(app_notification.Notification notification) {
    // Handle different notification types
    switch (notification.type) {
      case 'new_note':
        if (notification.documentUrl != null) {
          // Create a temporary PdfNote from the notification data
          final pdfNote = PdfNote(
            id: notification.id,
            title: notification.title,
            subject: notification.subject ?? 'Note',
            description: notification.message,
            filename: notification.documentUrl!,
            thumbnailImage: '',  // No thumbnail for notifications
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(pdfNote: pdfNote),
            ),
          );
        }
        break;
      case 'welcome':
        // Just show a toast for welcome notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to BCA Scholar Hub!')),
        );
        break;
      default:
        // For other notification types
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification.message)),
        );
    }
  }
} 