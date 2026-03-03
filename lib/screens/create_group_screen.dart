// lib/screens/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final _groupNameController = TextEditingController();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _selectedUsers = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(20)
        .get()
        .then((snapshot) {
          setState(() {
            _searchResults = snapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .where((user) => 
                    user['id'] != _authService.currentUser!.uid &&
                    !_selectedUsers.any((selected) => selected['id'] == user['id']))
                .toList();
          });
        });
  }

  void _addUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUsers.add(user);
      _searchResults.remove(user);
    });
  }

  void _removeUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUsers.remove(user);
    });
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите название группы')),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Добавьте хотя бы одного участника')),
      );
      return;
    }

    final participants = [
      _authService.currentUser!.uid,
      ..._selectedUsers.map((u) => u['id']),
    ];

    if (participants.length > 25) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Максимум 25 участников')),
      );
      return;
    }

    final chatId = await _chatService.createGroupChat(
      groupName: _groupNameController.text.trim(),
      participants: participants,
      createdBy: _authService.currentUser!.uid,
    );

    Navigator.pop(context);
    
    // Переходим в созданную группу
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ChatScreen(
          chatId: chatId,
          chatData: {
            'isGroup': true,
            'groupName': _groupNameController.text.trim(),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создать группу'),
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: Text(
              'Создать',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Название группы
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Название группы',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
          ),

          // Выбранные пользователи
          if (_selectedUsers.isNotEmpty)
            Container(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsers.length,
                itemBuilder: (ctx, index) {
                  final user = _selectedUsers[index];
                  return Container(
                    margin: EdgeInsets.all(8),
                    child: Chip(
                      avatar: CircleAvatar(
                        child: Text(user['username'][0].toUpperCase()),
                      ),
                      label: Text(user['username']),
                      onDeleted: () => _removeUser(user),
                    ),
                  );
                },
              ),
            ),

          // Поиск пользователей
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск пользователей',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                  },
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Результаты поиска
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (ctx, index) {
                final user = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user['username'][0].toUpperCase()),
                  ),
                  title: Text(user['username']),
                  subtitle: Text(user['email']),
                  trailing: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => _addUser(user),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}