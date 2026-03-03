// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/message_model.dart';
import 'package:path/path.dart' as path;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
    });
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String text,
    required String senderId,
  }) async {
    final message = Message(
      id: _firestore.collection('chats').doc().id,
      senderId: senderId,
      chatId: chatId,
      type: MessageType.text,
      content: text,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());

    // Обновляем последнее сообщение в чате
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': DateTime.now().toIso8601String(),
    });
  }

  Future<void> sendMediaMessage({
    required String chatId,
    required File file,
    required MessageType type,
    required String senderId,
    int? duration,
  }) async {
    // Загружаем файл в Storage
    String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    String filePath = 'chats/$chatId/$fileName';
    
    TaskSnapshot uploadTask = await _storage.ref(filePath).putFile(file);
    String downloadUrl = await uploadTask.ref.getDownloadURL();

    String? thumbnailUrl;
    if (type == MessageType.video) {
      // Здесь можно добавить генерацию миниатюры
      // Для упрощения используем тот же URL
      thumbnailUrl = downloadUrl;
    }

    final message = Message(
      id: _firestore.collection('chats').doc().id,
      senderId: senderId,
      chatId: chatId,
      type: type,
      content: downloadUrl,
      timestamp: DateTime.now(),
      duration: duration,
      thumbnailUrl: thumbnailUrl,
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());

    // Обновляем последнее сообщение
    String lastMessage = '';
    switch (type) {
      case MessageType.image:
        lastMessage = '📷 Фото';
        break;
      case MessageType.video:
        lastMessage = '🎥 Видео';
        break;
      case MessageType.voice:
        lastMessage = '🎤 Голосовое сообщение';
        break;
      case MessageType.circleVideo:
        lastMessage = '🔄 Кружочек';
        break;
      default:
        lastMessage = 'Медиа';
    }

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': lastMessage,
      'lastMessageTime': DateTime.now().toIso8601String(),
    });
  }
}