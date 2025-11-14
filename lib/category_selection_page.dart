import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- Импорт шрифтов

class CategorySelectionPage extends StatefulWidget {
  // Принимаем список уже выбранных категорий
  final List<String> currentlySelected;
  
  const CategorySelectionPage({super.key, required this.currentlySelected});

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  String _searchQuery = "";
  late Set<String> _selectedCategories; 

  // Переменные для проверки админа
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isAdmin = false;
  bool _isLoadingRole = true; // Показываем загрузку, пока проверяем

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(widget.currentlySelected);
    // Запускаем проверку роли при загрузке
    _checkUserRole(); 
  }

  // Функция для проверки роли
  Future<void> _checkUserRole() async {
    if (_currentUser == null) {
      setState(() { _isLoadingRole = false; });
      return;
    }
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        setState(() {
          _isAdmin = true;
        });
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRole = false;
        });
      }
    }
  }

  // Функция создания новой категории
  Future<void> _createNewCategory(String categoryName) async {
    final name = categoryName.trim().toLowerCase();
    if (name.isEmpty) return;

    final categoriesCollection =
        FirebaseFirestore.instance.collection('all_categories');
    
    final existing = await categoriesCollection
        .where('name_lowercase', isEqualTo: name)
        .get();

    if (existing.docs.isEmpty) {
      await categoriesCollection.add({
        'name_lowercase': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Выбираем ее
    setState(() {
      _selectedCategories.add(name);
      _searchQuery = ""; // Очищаем поиск
      // (Закрываем клавиатуру)
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select your interests categories', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        // При нажатии "Назад" (или этой кнопки)
        // мы возвращаем обновленный список на прошлый экран
        leading: IconButton(
          icon: Icon(Icons.check),
          onPressed: () {
            Navigator.of(context).pop(_selectedCategories.toList());
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Find...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Список всех категорий
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('all_categories')
                  .where('name_lowercase', isGreaterThanOrEqualTo: _searchQuery)
                  .where('name_lowercase', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
                  .snapshots(),
              builder: (context, snapshot) {
                // Если мы еще не узнали, админ ли юзер, ждем
                if (_isLoadingRole) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Если ничего не нашли
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  
                  // ЕСЛИ ПОЛЬЗОВАТЕЛЬ - АДМИН
                  if (_isAdmin && _searchQuery.isNotEmpty) {
                    return Center(
                      child: FilledButton.icon(
                        onPressed: () => _createNewCategory(_searchQuery),
                        icon: Icon(Icons.add),
                        label: Text('Create category "$_searchQuery"'),
                      ),
                    );
                  } 
                  // ЕСЛИ ПОЛЬЗОВАТЕЛЬ - ОБЫЧНЫЙ
                  else {
                    return Center(
                      child: Text('Category not found.'),
                    );
                  }
                }

                // Показываем список найденных
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final categoryName = data['name_lowercase'] as String;
                    final isSelected = _selectedCategories.contains(categoryName);

                    return ListTile(
                      title: Text(categoryName, style: GoogleFonts.roboto()),
                      // Иконка "галочки", если выбрано
                      trailing: isSelected
                          ? Icon(Icons.check_box, color: theme.colorScheme.primary)
                          : Icon(Icons.check_box_outline_blank),
                      onTap: () {
                        // Добавляем или убираем из сета
                        setState(() {
                          if (isSelected) {
                            _selectedCategories.remove(categoryName);
                          } else {
                            _selectedCategories.add(categoryName);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}