import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'category_selection_page.dart';

// --- 1. Enum for post type ---
enum PostType { Discussion, Event }
// --- 2. Enum for comment visibility ---
enum CommentVisibility { all, approvedOnly } 

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _selectedCategories = [];
  bool _isLoading = false;

  // --- 3. State Variables ---
  PostType _selectedType = PostType.Discussion;
  DateTime? _selectedEventDate;
  CommentVisibility _selectedVisibility = CommentVisibility.all;

  final _currentUser = FirebaseAuth.instance.currentUser;

  // --- Functions for date picking and error handling ---
  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context, initialDate: _selectedEventDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date == null) return;
    final TimeOfDay? time = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(_selectedEventDate ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _selectedEventDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }
  void _showError(String message) {
     if (!mounted) return;
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
     );
  }
  void _openCategorySelection() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (context) => CategorySelectionPage(currentlySelected: _selectedCategories)),
    );
    if (result != null) {
      setState(() { _selectedCategories = result; });
    }
  }

  // --- 4. Function to save post ---
  Future<void> _savePost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Validation
    if (_titleController.text.isEmpty || _selectedCategories.isEmpty) {
      _showError('Title and Categories are required!');
      return;
    }
    if (_selectedType == PostType.Event && _selectedEventDate == null) {
      _showError('For an Event, date and time must be specified.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final authorName = userDoc.data()?['displayName'] ?? 'Anonymous';

      final postDocRef = FirebaseFirestore.instance.collection('posts').doc();
      final postId = postDocRef.id;

      await postDocRef.set({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categories': _selectedCategories,
        'author_uid': user.uid,
        'author_name': authorName,
        'createdAt': FieldValue.serverTimestamp(),
        
        'postType': _selectedType.name,
        'eventDate': _selectedType == PostType.Event 
            ? Timestamp.fromDate(_selectedEventDate!)
            : null,
        'commentVisibility': _selectedVisibility.name, // The new field
        'postImageUrl': null,
      });

      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      _showError('Save Error: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('New Listing', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold))), // TRANSLATED
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              
              _buildSectionTitle(theme, '1. Publication Type'), // TRANSLATED
              
              SegmentedButton<PostType>(
                segments: const <ButtonSegment<PostType>>[
                  ButtonSegment<PostType>(
                    value: PostType.Discussion, label: Text('Discussion'), icon: Icon(Icons.forum_outlined)), // TRANSLATED
                  ButtonSegment<PostType>(
                    value: PostType.Event, label: Text('Event'), icon: Icon(Icons.calendar_today_outlined)), // TRANSLATED
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<PostType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),

              _buildSectionTitle(theme, '2. Main Information'), // TRANSLATED
              
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *', hintText: 'What is your post about?', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), // TRANSLATED
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description', hintText: 'Describe your listing in detail...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), // TRANSLATED
                maxLines: 5,
              ),

              AnimatedSize(
                duration: 300.ms,
                curve: Curves.easeInOut,
                child: _selectedType == PostType.Event
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: OutlinedButton.icon(
                          onPressed: _pickDateTime,
                          icon: Icon(Icons.calendar_month),
                          label: Text(
                            _selectedEventDate == null ? 'Click to select date and time *' : 'Date: ${DateFormat('d MMMM y, HH:mm', 'ru_RU').format(_selectedEventDate!)}', // TRANSLATED
                          ),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                        ),
                      )
                    : SizedBox.shrink(),
              ),

              _buildSectionTitle(theme, '3. Topics (Categories)'), // TRANSLATED
              
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
                      ? [Text('Click "Find" to select...')] // TRANSLATED
                      : _selectedCategories.map((category) { return Chip(label: Text(category)); }).toList(),
                ),
              ),
              SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _openCategorySelection,
                icon: Icon(Icons.add),
                label: Text('Find / Add Categories *'), // TRANSLATED
              ),
              
              // --- 5. COMMENT VISIBILITY ---
              _buildSectionTitle(theme, '4. Comment Visibility'), // TRANSLATED
              SegmentedButton<CommentVisibility>(
                segments: const <ButtonSegment<CommentVisibility>>[
                  ButtonSegment<CommentVisibility>(
                    value: CommentVisibility.all,
                    label: Text('Visible to All'), // TRANSLATED
                    icon: Icon(Icons.public),
                  ),
                  ButtonSegment<CommentVisibility>(
                    value: CommentVisibility.approvedOnly,
                    label: Text('Participants Only'), // TRANSLATED
                    icon: Icon(Icons.lock),
                  ),
                ],
                selected: {_selectedVisibility},
                onSelectionChanged: (Set<CommentVisibility> newSelection) {
                  setState(() {
                    _selectedVisibility = newSelection.first;
                  });
                },
              ),


              SizedBox(height: 32),
              FilledButton(
                onPressed: _savePost,
                child: Text('Publish'), // TRANSLATED
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              )
            ]
            .animate(interval: 50.ms).fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0),
          ),
        ),
      ),
    );
  }

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