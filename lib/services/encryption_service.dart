// lib/services/encryption_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // Генерация ключей для чата
  Map<String, dynamic> generateChatKeys() {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(
        Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256))),
      ));

    // Генерация AES ключа для симметричного шифрования
    final aesKey = Uint8List(32);
    secureRandom.nextBytes(aesKey);

    return {
      'aesKey': base64.encode(aesKey),
    };
  }

  // Шифрование сообщения
  String encryptMessage(String message, String keyBase64) {
    try {
      final key = Uint8List.fromList(base64.decode(keyBase64));
      final iv = Uint8List(16); // IV для AES

      final cipher = CBCBlockCipher(AESEngine())
        ..init(true, ParametersWithIV(KeyParameter(key), iv));

      final plainText = utf8.encode(message);
      final paddedText = _pad(plainText, 16);
      
      final encrypted = Uint8List(paddedText.length);
      var offset = 0;
      
      while (offset < paddedText.length) {
        offset += cipher.processBlock(
          paddedText.sublist(offset, offset + 16),
          0,
          encrypted,
          offset,
        );
      }

      // Объединяем IV и зашифрованные данные
      final result = Uint8List(iv.length + encrypted.length)
        ..setAll(0, iv)
        ..setAll(iv.length, encrypted);

      return base64.encode(result);
    } catch (e) {
      print('Ошибка шифрования: $e');
      return message; // В случае ошибки возвращаем исходное сообщение
    }
  }

  // Дешифрование сообщения
  String decryptMessage(String encryptedMessage, String keyBase64) {
    try {
      final data = base64.decode(encryptedMessage);
      
      // Извлекаем IV и зашифрованные данные
      final iv = data.sublist(0, 16);
      final encrypted = data.sublist(16);

      final key = Uint8List.fromList(base64.decode(keyBase64));
      
      final cipher = CBCBlockCipher(AESEngine())
        ..init(false, ParametersWithIV(KeyParameter(key), iv));

      final decrypted = Uint8List(encrypted.length);
      var offset = 0;

      while (offset < encrypted.length) {
        offset += cipher.processBlock(
          encrypted.sublist(offset, offset + 16),
          0,
          decrypted,
          offset,
        );
      }

      // Удаляем padding
      final unpadded = _unpad(decrypted);
      
      return utf8.decode(unpadded);
    } catch (e) {
      print('Ошибка дешифрования: $e');
      return encryptedMessage; // В случае ошибки возвращаем зашифрованное сообщение
    }
  }

  // Добавление padding для AES
  Uint8List _pad(Uint8List data, int blockSize) {
    final padLength = blockSize - (data.length % blockSize);
    final padded = Uint8List(data.length + padLength)
      ..setAll(0, data)
      ..setAll(data.length, List.filled(padLength, padLength));
    return padded;
  }

  // Удаление padding
  Uint8List _unpad(Uint8List data) {
    if (data.isEmpty) return data;
    
    final lastByte = data.last;
    if (lastByte < 1 || lastByte > 16) return data;

    return data.sublist(0, data.length - lastByte);
  }

  // Генерация ключа для группового чата
  String generateGroupKey() {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(
        Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256))),
      ));

    final key = Uint8List(32);
    secureRandom.nextBytes(key);
    return base64.encode(key);
  }
}