enum NoticePriority { high, normal, low }
enum NoticeCategory { exam, assignment, event, general, announcement, academic }

class Notice {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isImportant;
  final String? imageUrl;
  final List<String> tags;
  final NoticePriority priority;
  final NoticeCategory category;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.isImportant = false,
    this.imageUrl,
    this.tags = const [],
    this.priority = NoticePriority.normal,
    this.category = NoticeCategory.general,
  });

  factory Notice.fromMap(String id, Map<String, dynamic> map) {
    // Debug: Print the raw Firebase data
    print('🔥 Firebase Data for $id: $map');
    
    // Handle both old and new field names for backward compatibility
    final title = map['title']?.toString() ?? 'No Title';
    final content = map['message']?.toString() ?? map['content']?.toString() ?? 'No Content';
    final authorId = map['adminId']?.toString() ?? map['authorId']?.toString() ?? 'unknown';
    final authorName = map['adminName']?.toString() ?? map['authorName']?.toString() ?? 'Admin';
    
    // Debug: Print parsed values
    print('📝 Parsed - Title: $title, Content: $content, Author: $authorName');
    
    // Handle timestamp field (Firebase uses 'timestamp', our model uses 'createdAt')
    final timestamp = map['timestamp'] ?? map['createdAt'];
    final createdAt = timestamp != null 
        ? DateTime.fromMillisecondsSinceEpoch(timestamp is int 
            ? timestamp 
            : int.tryParse(timestamp.toString()) ?? DateTime.now().millisecondsSinceEpoch)
        : DateTime.now();
    
    return Notice(
      id: id,
      title: title,
      content: content,
      authorId: authorId,
      authorName: authorName,
      createdAt: createdAt,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] is int 
              ? map['updatedAt'] 
              : int.tryParse(map['updatedAt'].toString()) ?? DateTime.now().millisecondsSinceEpoch)
          : null,
      isImportant: map['isImportant'] == true || map['isImportant'] == 'true',
      imageUrl: map['imageUrl']?.toString(),
      tags: map['tags'] != null 
          ? List<String>.from(map['tags']) 
          : <String>[],
      priority: _parsePriority(map['priority']),
      category: _parseCategory(map['category']),
    );
  }
  
  static NoticePriority _parsePriority(dynamic priority) {
    if (priority == null) return NoticePriority.normal;
    
    final priorityStr = priority.toString().toLowerCase();
    switch (priorityStr) {
      case 'high':
        return NoticePriority.high;
      case 'low':
        return NoticePriority.low;
      case 'normal':
      default:
        return NoticePriority.normal;
    }
  }
  
  static NoticeCategory _parseCategory(dynamic category) {
    if (category == null) return NoticeCategory.general;
    
    final categoryStr = category.toString().toLowerCase();
    switch (categoryStr) {
      case 'exam':
        return NoticeCategory.exam;
      case 'assignment':
        return NoticeCategory.assignment;
      case 'event':
        return NoticeCategory.event;
      case 'announcement':
        return NoticeCategory.announcement;
      case 'academic':
        return NoticeCategory.academic;
      case 'general':
      default:
        return NoticeCategory.general;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': content,  // Use 'message' for Firebase
      'adminId': authorId,  // Use 'adminId' for Firebase
      'adminName': authorName,  // Use 'adminName' for Firebase
      'timestamp': createdAt.millisecondsSinceEpoch,  // Use 'timestamp' for Firebase
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isImportant': isImportant,
      'imageUrl': imageUrl,
      'tags': tags,
      'priority': priority.toString().split('.').last,
      'category': category.toString().split('.').last,
    };
  }

  Notice copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isImportant,
    String? imageUrl,
    List<String>? tags,
    NoticePriority? priority,
    NoticeCategory? category,
  }) {
    return Notice(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isImportant: isImportant ?? this.isImportant,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      category: category ?? this.category,
    );
  }
}

