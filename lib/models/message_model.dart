// lib/models/message_model.dart
enum MessageType { text, image, video, voice, circleVideo }

class Message {
  final String id;
  final String senderId;
  final String chatId;
  final MessageType type;
  final String content; // Текст или URL медиа
  final DateTime timestamp;
  final bool isRead;
  final int? duration; // Длительность для видео/голосовых
  final String? thumbnailUrl; // Миниатюра для видео

  Message({
    required this.id,
    required this.senderId,
    required this.chatId,
    required this.type,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.duration,
    this.thumbnailUrl,
  });

  // Проверка, не истек ли срок сообщения (7 дней)
  bool get isExpired {
    final expiryDate = timestamp.add(Duration(days: 7));
    return DateTime.now().isAfter(expiryDate);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'chatId': chatId,
      'type': type.index,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['senderId'],
      chatId: map['chatId'],
      type: MessageType.values[map['type']],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
      duration: map['duration'],
      thumbnailUrl: map['thumbnailUrl'],
    );
  }
}