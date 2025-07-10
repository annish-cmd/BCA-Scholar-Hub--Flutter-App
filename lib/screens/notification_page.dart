import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final notifications = [
      {
        'title': 'New Notes Uploaded',
        'message': 'Admin posted new notes: Cloud Computing',
        'time': '2 min ago',
        'icon': Icons.note_add,
      },
      {
        'title': 'Update',
        'message': 'Check out the new Java Basics notes!',
        'time': '1 hour ago',
        'icon': Icons.update,
      },
      {
        'title': 'Welcome!',
        'message': 'Thank you for using BCA Scholar Hub.',
        'time': 'Yesterday',
        'icon': Icons.celebration,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.blue,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.white),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF121212), const Color(0xFF1A1A1A)]
                : [Colors.blue[50]!, Colors.purple[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final notif = notifications[index];
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
                    notif['icon'] as IconData,
                    color: isDarkMode ? Colors.white : Colors.blue,
                  ),
                ),
                title: Text(
                  notif['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  notif['message'] as String,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                trailing: Text(
                  notif['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                onTap: () {
                  // In a real app, open the relevant note or details
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Open: ${notif['title']}')),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
} 