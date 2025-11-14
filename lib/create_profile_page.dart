import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_selection_page.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  
  List<String> _selectedCategories = [];
  bool _isLoading = false;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _currentUser?.displayName ?? '');
    _bioController = TextEditingController();
  }

  Future<void> saveProfile() async {
    if (_currentUser == null) return;
    
    if (_nameController.text.isEmpty || _selectedCategories.isEmpty) {
      _showError('Name and at least one category are required!');
      return;
    }

    setState(() { _isLoading = true; });
    final usersCollection = FirebaseFirestore.instance.collection('users');

    try {
      await usersCollection.doc(_currentUser!.uid).set({
        'uid': _currentUser!.uid,
        'email': _currentUser!.email,
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'categories': _selectedCategories,
        'role': 'user',
        'photoUrl': _currentUser!.photoURL, 
      });
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  
  void _showError(String message) {
     if (!mounted) return;
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
     );
  }

  void _openCategorySelection() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (context) => CategorySelectionPage(
          currentlySelected: _selectedCategories,
        ),
      ),
    );
    if (result != null) {
      setState(() { _selectedCategories = result; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Done')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              shrinkWrap: true,
              children: [
                if (_currentUser?.photoURL != null)
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(_currentUser!.photoURL!),
                    ),
                  ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    'Welcome',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 30),
                
                Text('Select your categories:', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 10),
                
                Container(
                  padding: EdgeInsets.all(12),
                  constraints: BoxConstraints(minHeight: 100),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _selectedCategories.isEmpty
                        ? [Text('Click ‘Add’ to choose…')]
                        : _selectedCategories.map((category) {
                            return Chip(
                              label: Text(category),
                              onDeleted: () {
                                setState(() {
                                  _selectedCategories.remove(category);
                                });
                              },
                            );
                          }).toList(),
                  ),
                ),
                SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _openCategorySelection,
                  icon: Icon(Icons.add),
                  label: Text('Add / Find categories'),
                ),
                SizedBox(height: 30),
                FilledButton(
                  onPressed: saveProfile,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Save'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}