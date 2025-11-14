import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_selection_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Контроллеры для полей
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  // Состояния
  List<String> _selectedCategories = [];
  bool _isLoading = true; // Сначала грузим данные
  bool _isSaving = false; // Для кнопки "Сохранить"
  String? _photoUrl; // Для аватарки Google

  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  // --- 1. ЗАГРУЖАЕМ ТЕКУЩИЕ ДАННЫЕ В ПОЛЯ ---
  Future<void> _loadCurrentUserData() async {
    if (_currentUser == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        
        // Заполняем контроллеры
        _nameController.text = data['displayName'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _selectedCategories = List<String>.from(data['categories'] ?? []);
        _photoUrl = data['photoUrl']; // (Аватарка из Google)
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  
  // --- 2. ЛОГИКА СОХРАНЕНИЯ ---
  Future<void> _saveProfile() async {
    if (_currentUser == null) return;
    
    if (_nameController.text.isEmpty) {
      _showError('The name cannot be empty.');
      return;
    }

    setState(() { _isSaving = true; });

    try {
      // ИСПОЛЬЗУЕМ .update() (а не .set())
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
            'displayName': _nameController.text.trim(),
            'bio': _bioController.text.trim(),
            'categories': _selectedCategories,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Закрываем страницу
      }

    } catch (e) {
      _showError('Ошибка сохранения: $e');
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  // Функция открытия выбора категорий
  void _openCategorySelection() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (context) => CategorySelectionPage(
          currentlySelected: _selectedCategories,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedCategories = result;
      });
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
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    // --- ШАПКА С АВАТАРКОЙ ---
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: _photoUrl == null 
                          ? Text(
                              _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                              style: GoogleFonts.montserrat(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Google Avatar',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),

                    _buildSectionTitle(theme, 'Info'),
                    
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _bioController,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 4,
                    ),

                    _buildSectionTitle(theme, 'My categories'),
                    
                    Container(
                      padding: EdgeInsets.all(12),
                      constraints: BoxConstraints(minHeight: 100),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _selectedCategories.isEmpty
                            ? [Text('Click ‘Edit’ to choose…')]
                            : _selectedCategories.map((category) {
                                return Chip(label: Text(category));
                              }).toList(),
                      ),
                    ),
                    SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _openCategorySelection,
                      icon: Icon(Icons.edit_outlined),
                      label: Text('Edit categories'),
                    ),
                    
                    SizedBox(height: 32),
                    // --- КНОПКА СОХРАНЕНИЯ ---
                    FilledButton(
                      onPressed: _isSaving ? null : _saveProfile, // Отключаем при сохранении
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: _isSaving 
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Save',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    )
                  ]
                  .animate(interval: 50.ms)
                  .fadeIn(duration: 200.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.1, end: 0),
                ),
              ),
            ),
    );
  }

  // --- Виджет-разделитель (Заголовок секции) ---
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}