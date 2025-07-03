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
  
  // Encryption fields
  final String? cipherText; // Encrypted message text
  final String? iv; // Initialization vector for AES
  final Map<String, dynamic>? encryptedKeys; // User ID -> Encrypted AES key
  final bool isEncrypted; // Flag to indicate if the message is encrypted
  
  // Admin field
  final bool isAdmin; // Flag to indicate if the message is from an admin

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
    this.cipherText,
    this.iv,
    this.encryptedKeys,
    this.isEncrypted = false,
    this.isAdmin = false,
  });

  // Create from Firebase data
  factory ChatMessage.fromMap(String id, Map<dynamic, dynamic> data) {
    // Handle encrypted messages
    final bool isEncrypted = data['isEncrypted'] ?? false;
    final bool isAdmin = data['isAdmin'] ?? false;
    
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
      cipherText: data['cipherText'],
      iv: data['iv'],
      encryptedKeys: data['encryptedKeys'] != null 
          ? Map<String, dynamic>.from(data['encryptedKeys'])
          : null,
      isEncrypted: isEncrypted,
      isAdmin: isAdmin,
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
    
    // Add admin flag
    if (isAdmin) {
      map['isAdmin'] = true;
    }
    
    // Add encryption data if this is an encrypted message
    if (isEncrypted) {
      map['isEncrypted'] = true;
      
      if (cipherText != null) {
        map['cipherText'] = cipherText!;
      }
      
      if (iv != null) {
        map['iv'] = iv!;
      }
      
      if (encryptedKeys != null) {
        map['encryptedKeys'] = encryptedKeys!;
      }
    }

    return map;
  }
}
