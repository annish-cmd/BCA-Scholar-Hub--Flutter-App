class TimeFormatter {
  /// Format time in social media style (2h, 3d, 1mo, 2y)
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y';
    }
  }

  /// Format detailed time (for tap to show detailed view)
  static String formatDetailedTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  /// Format date in DD/MM/YY format
  static String formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year.toString().substring(2)}';
  }

  /// Format perfect timestamp with day, time, hour, minute
  static String formatPerfectTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    // Get day names
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // Format time as HH:MM AM/PM
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeString = '$displayHour:$minute $period';
    
    if (difference.inDays == 0) {
      // Today - show "Today at 2:30 PM"
      return 'Today at $timeString';
    } else if (difference.inDays == 1) {
      // Yesterday - show "Yesterday at 2:30 PM"
      return 'Yesterday at $timeString';
    } else if (difference.inDays < 7) {
      // This week - show "Monday at 2:30 PM"
      final dayName = weekdays[dateTime.weekday - 1];
      return '$dayName at $timeString';
    } else if (dateTime.year == now.year) {
      // This year - show "15 Mar at 2:30 PM"
      final monthName = months[dateTime.month - 1];
      return '${dateTime.day} $monthName at $timeString';
    } else {
      // Different year - show "15 Mar 2023 at 2:30 PM"
      final monthName = months[dateTime.month - 1];
      return '${dateTime.day} $monthName ${dateTime.year} at $timeString';
    }
  }
}
