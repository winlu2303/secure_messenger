// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Поток для отслеживания состояния аутентификации
  Stream<User?> get userStream => _auth.authStateChanges();
  
  User? get currentUser => _auth.currentUser;

  // Регистрация нового пользователя
  Future<Map<String, dynamic>> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
  }) async {
    try {
      // Создаем пользователя в Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Создаем профиль пользователя в Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': username,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
          'avatarUrl': '',
          'status': 'Hey there! I am using Secure Messenger',
        });

        return {'success': true, 'user': user};
      }
      return {'success': false, 'error': 'Failed to create user'};
    } on FirebaseAuthException catch (e) {
      String message = '';
      switch (e.code) {
        case 'weak-password':
          message = 'Пароль слишком слабый';
          break;
        case 'email-already-in-use':
          message = 'Этот email уже используется';
          break;
        case 'invalid-email':
          message = 'Неверный формат email';
          break;
        default:
          message = 'Ошибка регистрации: ${e.message}';
      }
      return {'success': false, 'error': message};
    }
  }

  // Вход пользователя
  Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Обновляем статус онлайн
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });

        return {'success': true, 'user': user};
      }
      return {'success': false, 'error': 'Failed to sign in'};
    } on FirebaseAuthException catch (e) {
      String message = '';
      switch (e.code) {
        case 'user-not-found':
          message = 'Пользователь не найден';
          break;
        case 'wrong-password':
          message = 'Неверный пароль';
          break;
        case 'invalid-email':
          message = 'Неверный формат email';
          break;
        default:
          message = 'Ошибка входа: ${e.message}';
      }
      return {'success': false, 'error': message};
    }
  }

  // Выход из системы
  Future<void> signOut() async {
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut();
  }

  // Поиск пользователей по имени/email
  Stream<List<Map<String, dynamic>>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {...doc.data(), 'id': doc.id};
          }).toList();
        });
  }
}