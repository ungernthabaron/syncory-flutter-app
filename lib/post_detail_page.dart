import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  late Stream<DocumentSnapshot> _postStream;

  // --- 1. АДМИН-СТАТУС ---
  bool _isAdmin = false;
  late String _currentUserId;
  // -----------------------

  @override
  void initState() {
    super.initState();
    _currentUserId = currentUser?.uid ?? '';
    _postStream = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .snapshots();
    _checkUserRole();
  }

  // --- 1. ПРОВЕРКА РОЛИ АДМИНА ---
  Future<void> _checkUserRole() async {
    if (currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        if (mounted) {
          setState(() {
            _isAdmin = true;
          });
        }
      }
    } catch (e) {
      print("Error checking role: $e");
    }
  }
  // --------------------------------

  // --- 2. ФУНКЦИЯ УДАЛЕНИЯ КОММЕНТАРИЯ (Admin/Owner) ---
  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'), // TRANSLATED
          content: Text('Are you sure you want to delete this comment?'), // TRANSLATED
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'), // TRANSLATED
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)), // TRANSLATED
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comment successfully deleted.')), // TRANSLATED
        );
      } catch (e) {
        print("Error deleting comment: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment.')), // TRANSLATED
        );
      }
    }
  }
  // ----------------------------------------------------

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    _commentController.clear();
    FocusScope.of(context).unfocus();

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final userData = userDoc.data();
    final displayName = userData?['displayName'] ?? 'Anonymous'; // TRANSLATED

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': text,
      'userId': currentUser!.uid,
      'userName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- ОСНОВНОЙ BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)), // TRANSLATED
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: StreamBuilder<DocumentSnapshot>(
            stream: _postStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text('Post not found.')); // TRANSLATED
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final theme = Theme.of(context);

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(24.0),
                      children: [
                        // --- Post Content (Title, Author, Description) ---
                        _buildPostHeader(theme, data),
                        Divider(height: 30),
                        
                        // --- Comments Title ---
                        Text(
                          'Comments', // TRANSLATED
                          style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),

                        // --- Comments List ---
                        _buildCommentList(theme),
                      ],
                    ),
                  ),

                  // --- Input Field ---
                  _buildCommentInput(theme),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  
  // --- WIDGETS ---

  Widget _buildPostHeader(ThemeData theme, Map<String, dynamic> data) {
    final Timestamp? timestamp = data['createdAt'];
    final String formattedDate = timestamp != null
        ? DateFormat('MMM d, y, HH:mm').format(timestamp.toDate())
        : '...';
    final categories = List<String>.from(data['categories'] ?? []);
    final String authorName = data['author_name'] ?? 'Anonymous'; // TRANSLATED
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['title'] ?? 'No Title', // TRANSLATED
          style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'By $authorName on $formattedDate', // TRANSLATED
          style: theme.textTheme.bodySmall,
        ),
        SizedBox(height: 16),
        Text(
          data['description'] ?? 'No description.', // TRANSLATED
          style: theme.textTheme.bodyLarge,
        ),
        SizedBox(height: 16),
        if (categories.isNotEmpty)
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: categories.map((category) {
              return Chip(
                label: Text(category),
                backgroundColor: theme.colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCommentList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error loading comments: ${snapshot.error}'); // TRANSLATED
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('No comments yet.')); // TRANSLATED
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildCommentTile(theme, doc.id, data);
          },
        );
      },
    );
  }
  
  // --- 3. WIDGET КОММЕНТАРИЯ С КНОПКОЙ УДАЛЕНИЯ ---
  Widget _buildCommentTile(ThemeData theme, String commentId, Map<String, dynamic> data) {
    final String userName = data['userName'] ?? 'Anonymous'; // TRANSLATED
    final String userId = data['userId'] ?? '';
    final Timestamp? timestamp = data['createdAt'];
    final String formattedDate = timestamp != null
        ? DateFormat('HH:mm, MMM d, y').format(timestamp.toDate())
        : '...';
    
    // Определяем, кто может удалять: Админ ИЛИ владелец комментария
    final bool canDelete = _isAdmin || userId == _currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainer,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          title: Text(
            userName,
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['text'] ?? 'No text', style: theme.textTheme.bodyMedium), // TRANSLATED
              SizedBox(height: 4),
              Text(formattedDate, style: theme.textTheme.bodySmall),
            ],
          ),
          trailing: canDelete
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteComment(commentId);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Comment', style: TextStyle(color: Colors.red)), // TRANSLATED
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(Icons.more_vert),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCommentInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...', // TRANSLATED
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: _submitComment,
            child: Icon(Icons.send),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}