import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminPostsPage extends StatefulWidget {
  const AdminPostsPage({super.key});

  @override
  State<AdminPostsPage> createState() => _AdminPostsPageState();
}

class _AdminPostsPageState extends State<AdminPostsPage> {
  String? _selectedCategory; // Для поиска/фильтра

  // --- 1. Функция УДАЛЕНИЯ Поста ---
  Future<void> _deletePost(String postId, String postTitle) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить пост?'),
        content: Text('Вы уверены, что хотите удалить пост "$postTitle"?\n\nВНИМАНИЕ: Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('УДАЛИТЬ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Просто удаляем основной документ поста.
        // (Его 'comments', 'likes' и 'applicants' останутся в базе,
        // но будут "осиротевшими" и невидимыми для юзеров.
        // Это ограничение бесплатного плана без Cloud Functions).
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Пост "$postTitle" удален.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // --- 2. Динамический запрос (как в FeedPage) ---
  Stream<QuerySnapshot> _buildPostsStream() {
    Query query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true);

    if (_selectedCategory != null) {
      query = query.where(
        'categories',
        arrayContains: _selectedCategory,
      );
    }
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Управление Постами', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      ),
      body: Row(
        children: [
          // --- 3. КОЛОНКА ФИЛЬТРА (Категории) ---
          if (MediaQuery.of(context).size.width > 900)
            Container(
              width: 250,
              color: theme.colorScheme.surfaceContainerLowest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Поиск по Категории',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Кнопка сброса
                  ListTile(
                    title: Text('Все посты', style: GoogleFonts.roboto(fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal)),
                    selected: _selectedCategory == null,
                    selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  Divider(height: 1),
                  Expanded(
                    child: _buildCategoryList(theme), // Виджет списка категорий
                  ),
                ],
              ),
            ),
          
          // --- 4. КОЛОНКА СПИСКА ПОСТОВ ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Посты не найдены.'));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final postTitle = data['title'] ?? 'Без заголовка';
                    
                    final Timestamp? timestamp = data['createdAt'];
                    final String formattedDate = timestamp != null
                        ? DateFormat('d MMM y, HH:mm', 'ru_RU').format(timestamp.toDate())
                        : '...';

                    return Card(
                      color: theme.colorScheme.surfaceContainerHigh,
                      elevation: 0,
                      child: ListTile(
                        title: Text(postTitle, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Автор: ${data['author_name']} • $formattedDate'),
                        // --- 5. КНОПКА УДАЛИТЬ ---
                        trailing: IconButton(
                          icon: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                          tooltip: 'Удалить пост',
                          onPressed: () => _deletePost(doc.id, postTitle),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Виджет списка категорий (скопирован из FeedPage) ---
  Widget _buildCategoryList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('all_categories')
          .orderBy('name_lowercase')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Категорий нет.'));
        }
        
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final categoryName = (doc.data() as Map<String, dynamic>)['name_lowercase'];
            final isSelected = categoryName == _selectedCategory;

            return ListTile(
              title: Text(categoryName, style: GoogleFonts.roboto(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
              onTap: () {
                setState(() { _selectedCategory = categoryName; });
              },
            );
          },
        );
      },
    );
  }
}