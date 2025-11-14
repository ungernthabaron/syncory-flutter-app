import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_categories_page.dart'; // <-- 1. ИМПОРТИРУЙ СТРАНИЦУ КАТЕГОРИЙ

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() { _searchQuery = _searchController.text; });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Функция "БАНА" ---
  Future<void> _toggleUserBan(String uid, bool isCurrentlyDisabled) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isCurrentlyDisabled ? 'Разбанить?' : 'Забанить пользователя?'),
          content: Text('Пользователь ${isCurrentlyDisabled ? "снова сможет" : "не сможет"} войти в приложение.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(isCurrentlyDisabled ? 'Разбанить' : 'Забанить'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
              'isDisabled': !isCurrentlyDisabled 
            });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Stream<QuerySnapshot> _buildUserStream() {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('uid', isNotEqualTo: currentUser!.uid);

    if (_searchQuery.isNotEmpty) {
      query = query.where(
        'categories',
        arrayContains: _searchQuery.trim().toLowerCase(),
      );
    }
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Панель Админа: Пользователи'),
        // --- 🔥 2. ВОТ КНОПКА, КОТОРУЮ МЫ ДОБАВИЛИ ---
        actions: [
          IconButton(
            icon: Icon(Icons.category_outlined),
            tooltip: 'Управление категориями',
            onPressed: () {
              // Переход на страницу категорий
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AdminCategoriesPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Поиск по категории...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),

          Text(
            'Все пользователи',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          StreamBuilder<QuerySnapshot>(
            stream: _buildUserStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('Никого не найдено...'));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final categories = List<String>.from(data['categories'] ?? []);
                  
                  final bool isDisabled = data['isDisabled'] ?? false;

                  return Card(
                    // Исправленный цвет
                    color: isDisabled ? theme.colorScheme.surfaceContainer : theme.colorScheme.surfaceContainerHigh,
                    elevation: 0,
                    child: ListTile(
                      title: Text(data['displayName'] ?? 'Пользователь'),
                      subtitle: Text(
                        'Интересы: ${categories.join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: Icon(Icons.person_outline),
                      
                      // Исправленная иконка
                      trailing: IconButton(
                        icon: Icon(
                          isDisabled ? Icons.lock : Icons.lock_open, // Забанен = замок
                          color: isDisabled ? theme.colorScheme.error : Colors.green, // Забанен = красный
                        ),
                        tooltip: isDisabled ? 'Пользователь ЗАБАНЕН (Нажми, чтобы разбанить)' : 'Пользователь АКТИВЕН (Нажми, чтобы забанить)',
                        onPressed: () => _toggleUserBan(data['uid'], isDisabled),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}