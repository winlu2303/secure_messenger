// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';
import 'profile_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чаты'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                child: Text('Профиль'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => ProfileScreen()),
                  );
                },
              ),
              PopupMenuItem(
                child: Text('Создать группу'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => CreateGroupScreen()),
                  );
                },
              ),
              PopupMenuItem(
                child: Text('Выйти'),
                onTap: () async {
                  await _authService.signOut();
                },
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(_authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет чатов',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Нажмите + чтобы начать общение',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (ctx, index) {
              final chatData = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;

              return FutureBuilder<String>(
                future: _getChatTitle(chatData),
                builder: (ctx, titleSnapshot) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (titleSnapshot.data?[0] ?? '?').toUpperCase(),
                      ),
                    ),
                    title: Text(
                      titleSnapshot.data ?? 'Загрузка...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      chatData['lastMessage'] ?? 'Нет сообщений',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatTime(chatData['lastMessageTime']),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => ChatScreen(
                            chatId: chatId,
                            chatData: chatData,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  Future<String> _getChatTitle(Map<String, dynamic> chatData) async {
    if (chatData['isGroup'] == true) {
      return chatData['groupName'] ?? 'Групповой чат';
    } else {
      // Для личного чата получаем имя собеседника
      final participants = List<String>.from(chatData['participants']);
      final otherUserId = participants.firstWhere(
        (id) => id != _authService.currentUser!.uid,
      );
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();
      
      return userDoc.data()?['username'] ?? 'Пользователь';
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime time;
    if (timestamp is Timestamp) {
      time = timestamp.toDate();
    } else if (timestamp is String) {
      time = DateTime.parse(timestamp);
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}д';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'только что';
    }
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Новый чат'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Личный чат'),
              onTap: () {
                Navigator.pop(ctx);
                _startPrivateChat();
              },
            ),
            ListTile(
              leading: Icon(Icons.group),
              title: Text('Создать группу'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => CreateGroupScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startPrivateChat() {
    showSearch(
      context: context,
      delegate: UserSearchDelegate(_authService.currentUser!.uid),
    );
  }

  void _showSearchDialog() {
    showSearch(
      context: context,
      delegate: ChatSearchDelegate(),
    );
  }
}

// Делегат для поиска пользователей
class UserSearchDelegate extends SearchDelegate {
  final String currentUserId;
  final AuthService _authService = AuthService();

  UserSearchDelegate(this.currentUserId);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Text('Введите имя пользователя для поиска'),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _authService.searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!;

        if (users.isEmpty) {
          return Center(child: Text('Пользователи не найдены'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (ctx, index) {
            final user = users[index];
            if (user['uid'] == currentUserId) return SizedBox.shrink();

            return ListTile(
              leading: CircleAvatar(
                child: Text(user['username'][0].toUpperCase()),
              ),
              title: Text(user['username']),
              subtitle: Text(user['email']),
              onTap: () async {
                close(context, null);
                await _createPrivateChat(user['uid']);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _createPrivateChat(String otherUserId) async {
    final chatService = ChatService();
    final chatId = await chatService.createPrivateChat(
      currentUserId,
      otherUserId,
    );

    // Переходим в созданный чат
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ChatScreen(
          chatId: chatId,
          chatData: {'isGroup': false},
        ),
      ),
    );
  }
}

// Делегат для поиска по чатам
class ChatSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(); // Заглушка
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(
      child: Text('Поиск по чатам будет реализован позже'),
    );
  }
}