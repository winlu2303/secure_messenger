// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final _statusController = TextEditingController();
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final doc = await _chatService.getUserData(user.uid);
      setState(() {
        _userData = doc;
        _statusController.text = doc['status'] ?? '';
      });
    }
  }

  Future<void> _updateAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isLoading = true);
      await _chatService.updateUserAvatar(
        _authService.currentUser!.uid,
        File(image.path),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus() async {
    if (_statusController.text.trim().isEmpty) return;

    await _chatService.updateUserStatus(
      _authService.currentUser!.uid,
      _statusController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Статус обновлен')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Профиль')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Аватар
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _userData!['avatarUrl'] != null &&
                          _userData!['avatarUrl'].isNotEmpty
                      ? NetworkImage(_userData!['avatarUrl'])
                      : null,
                  child: _userData!['avatarUrl'] == null ||
                          _userData!['avatarUrl'].isEmpty
                      ? Text(
                          _userData!['username'][0].toUpperCase(),
                          style: TextStyle(fontSize: 40),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _updateAvatar,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Имя пользователя
            Text(
              _userData!['username'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            // Email
            Text(
              _userData!['email'],
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),

            // Телефон
            Text(
              _userData!['phoneNumber'] ?? 'Телефон не указан',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 24),

            // Статус
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статус',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _statusController,
                      decoration: InputDecoration(
                        hintText: 'Ваш статус',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _updateStatus,
                      child: Text('Сохранить статус'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}