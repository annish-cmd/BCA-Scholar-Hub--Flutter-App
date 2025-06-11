class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final int timestamp;
  final String? userPhotoUrl;
  final String? replyToId;
  final String? replyToUserName;
  final String? replyToText;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
    this.userPhotoUrl,
    this.replyToId,
    this.replyToUserName,
    this.replyToText,
  });

  // Create from Firebase data
  factory ChatMessage.fromMap(String id, Map<dynamic, dynamic> data) {
    return ChatMessage(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? 0,
      userPhotoUrl: data['userPhotoUrl'],
      replyToId: data['replyToId'],
      replyToUserName: data['replyToUserName'],
      replyToText: data['replyToText'],
    );
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'userId': userId,
      'userName': userName,
      'text': text,
      'timestamp': timestamp,
    };

    if (userPhotoUrl != null) {
      map['userPhotoUrl'] = userPhotoUrl!;
    }

    if (replyToId != null) {
      map['replyToId'] = replyToId!;
    }

    if (replyToUserName != null) {
      map['replyToUserName'] = replyToUserName!;
    }

    if (replyToText != null) {
      map['replyToText'] = replyToText!;
    }

    return map;
  }
}
