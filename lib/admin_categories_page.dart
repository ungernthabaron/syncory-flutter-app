import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  final _nameController = TextEditingController();
  final _categoriesCollection = FirebaseFirestore.instance.collection('all_categories');
  bool _isLoading = false;

  // --- 1. Функция Добавления ---
  Future<void> _addCategory() async {
    final name = _nameController.text.trim().toLowerCase();
    if (name.isEmpty) return;

    setState(() { _isLoading = true; });

    try {
      // Проверяем, существует ли уже такая категория
      final existing = await _categoriesCollection
          .where('name_lowercase', isEqualTo: name)
          .get();

      if (existing.docs.isNotEmpty) {
        _showError('Такая категория уже существует.');
      } else {
        // Добавляем новую
        await _categoriesCollection.add({
          'name_lowercase': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _nameController.clear(); // Очищаем поле
      }
    } catch (e) {
      _showError('Ошибка: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- 🔥 2. ФУНКЦИЯ УДАЛЕНИЯ (которую ты просил) ---
  Future<void> _deleteCategory(String docId, String categoryName) async {
    // Показываем диалог подтверждения
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить категорию?'),
        content: Text('Вы уверены, что хотите удалить "$categoryName"?\n\nЭто действие нельзя отменить. Посты с этой категорией останутся, но сама категория исчезнет из выбора.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Если админ подтвердил
    if (confirm == true) {
      try {
        await _categoriesCollection.doc(docId).delete();
      } catch (e) {
        _showError('Ошибка удаления: $e');
      }
    }
  }
  
  void _showError(String message) {
     if (!mounted) return;
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
     );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Управление категориями', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // --- UI ДЛЯ ДОБАВЛЕНИЯ ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Новая категория (в нижнем регистре)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    _isLoading
                        ? CircularProgressIndicator()
                        : FilledButton.icon(
                            onPressed: _addCategory,
                            icon: Icon(Icons.add),
                            label: Text('Добавить'),
                          ),
                  ],
                ),
              ),
              Divider(),

              // --- UI ДЛЯ ОТОБРАЖЕНИЯ (СПИСОК) ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _categoriesCollection.orderBy('name_lowercase').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('Категорий нет.'));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final categoryName = data['name_lowercase'];

                        return ListTile(
                          title: Text(categoryName),
                          // --- 🔥 3. КНОПКА УДАЛЕНИЯ ---
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Удалить категорию',
                            onPressed: () => _deleteCategory(doc.id, categoryName),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}