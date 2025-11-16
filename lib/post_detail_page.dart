import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'user_profile_page.dart';

// --- Enum для видимости комментариев ---
enum CommentVisibility { all, approvedOnly } 

class PostDetailPage extends StatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  
  // Переменные для данных поста
  String _postTitle = "";
  String _postAuthorUid = "";
  String _postAuthorName = "";
  
  // --- Админ-статус ---
  bool _isAdmin = false;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _currentUser?.uid ?? '';
    _checkUserRole();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- Проверка роли админа ---
  Future<void> _checkUserRole() async {
    if (_currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        if (mounted) {
          setState(() { _isAdmin = true; });
        }
      }
    } catch (e) {
      print("Error checking role: $e");
    }
  }

  // --- Функция удаления коммента (для Админа/Владельца) ---
  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this comment?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
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
      } catch (e) {
        print("Error deleting comment: $e");
      }
    }
  }

  // --- МЕТОДЫ ДЛЯ ЛАЙКОВ/ЗАКЛАДОК/КОММЕНТОВ ---
  Future<void> _toggleLike() async {
    if (_currentUser == null) return;
    final likeRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('likes').doc(_currentUser!.uid);
    final likeDoc = await likeRef.get();
    if (likeDoc.exists) { 
      await likeRef.delete(); 
    } else { 
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()}); 
    }
  }

  Future<void> _toggleBookmark() async {
    if (_currentUser == null) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
    final userDoc = await userRef.get();
    List<String> bookmarks = List<String>.from(userDoc.data()?['bookmarkedPosts'] ?? []);
    if (bookmarks.contains(widget.postId)) { 
      await userRef.update({'bookmarkedPosts': FieldValue.arrayRemove([widget.postId])}); 
    } else { 
      await userRef.update({'bookmarkedPosts': FieldValue.arrayUnion([widget.postId])}); 
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty || _currentUser == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      
      final authorName = userDoc.data()?['displayName'] ?? 'Anonymous';
            
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'text': _commentController.text, 
        'authorUid': _currentUser!.uid,
        'userName': authorName, // Поле 'userName'
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      print('Error posting comment: $e');
    }
  }
  // ---

  Future<void> _applyToPost() async {
    if (_currentUser == null || _postAuthorUid.isEmpty) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
    final applicantName = userDoc.data()?['displayName'] ?? 'Anonymous';
    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('applicants').doc(_currentUser!.uid).set({
      'applicantUid': _currentUser!.uid, 
      'applicantName': applicantName, 
      'status': 'pending', 
      'appliedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateApplicantStatus(String applicantUid, String applicantName, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('applicants')
        .doc(applicantUid)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('posts').doc(widget.postId).get(),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                      return Center(child: Text('Post not found.'));
                    }

                    final postData = postSnapshot.data!.data() as Map<String, dynamic>;
                    _postTitle = postData['title'] ?? '';
                    _postAuthorUid = postData['author_uid'] ?? '';
                    _postAuthorName = postData['author_name'] ?? 'Unknown';

                    final isAuthor = _currentUser?.uid == _postAuthorUid;
                    final categories = List<String>.from(postData['categories'] ?? []);
                    final commentPolicy = postData['commentVisibility'] ?? CommentVisibility.all.name; 

                    return ListView(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      children: [
                        _buildPostHeader(theme, postData),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(children: [
                            _buildLikeButton(), 
                            _buildBookmarkButton(),
                          ]),
                        ),

                        Text(postData['description'] ?? '', style: GoogleFonts.roboto(fontSize: 16, height: 1.5, color: theme.colorScheme.onSurfaceVariant)),
                        SizedBox(height: 20),
                        Wrap(spacing: 8.0, runSpacing: 4.0, children: categories.map((c) => Chip(label: Text(c), backgroundColor: theme.colorScheme.surfaceContainerHigh)).toList()),

                        Divider(height: 40, thickness: 0.5),

                        if (!isAuthor && _currentUser != null) _buildApplyButton(theme),
                        if (isAuthor) _buildApplicantsList(theme),

                        Divider(height: 40, thickness: 0.5),

                        _CommentsAccessGate(
                          postId: widget.postId,
                          postAuthorUid: _postAuthorUid,
                          commentPolicy: commentPolicy,
                          theme: theme,
                          isAuthor: isAuthor,
                        ),
                      ]
                      .animate(interval: 50.ms).fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0),
                    );
                  },
                ),
              ),

              FutureBuilder<DocumentSnapshot>(
                 future: FirebaseFirestore.instance.collection('posts').doc(widget.postId).get(),
                 builder: (context, postSnapshot) {
                    if (!postSnapshot.hasData) return SizedBox.shrink();
                    final postData = postSnapshot.data!.data() as Map<String, dynamic>;
                    final commentPolicy = postData['commentVisibility'] ?? CommentVisibility.all.name; 
                    final isAuthor = _currentUser?.uid == (postData['author_uid'] ?? '');
                    
                    return _buildCommentInput(theme, commentPolicy, isAuthor);
                 }
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- ГЕЙТ (ВОРОТА) ДОСТУПА К КОММЕНТАРИЯМ ---
  Widget _CommentsAccessGate({
    required String postId, 
    required String postAuthorUid, 
    required String commentPolicy, 
    required ThemeData theme, 
    required bool isAuthor
  }) {
    if (commentPolicy == CommentVisibility.all.name || isAuthor) {
      return _buildCommentsList(theme);
    }

    if (_currentUser == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
        child: Text('Comments available to participants only. Sign in to apply.'),
      );
    }

    if (commentPolicy == CommentVisibility.approvedOnly.name) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .collection('applicants')
            .doc(_currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          
          String status = 'unknown';
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            status = data?['status'] ?? 'unknown';
          }

          if (status == 'approved') {
            return _buildCommentsList(theme);
          }
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Column(
              children: [
                Icon(Icons.lock_outline, size: 40, color: theme.colorScheme.onSurfaceVariant),
                SizedBox(height: 10),
                Text('Comments are hidden', style: theme.textTheme.titleMedium),
                Text('Only visible to approved participants.', style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        },
      );
    }
    
    return SizedBox.shrink();
  }

  // --- СПИСОК КАНДИДАТОВ ---
  Widget _buildApplicantsList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Applicants', style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('applicants').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('No applicants yet.');
            }
            
            return ListView.builder(
              shrinkWrap: true, 
              physics: NeverScrollableScrollPhysics(), 
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final applicantUid = data['applicantUid'] ?? '';
                final applicantName = data['applicantName'] ?? 'Unknown';
                final status = data['status'] ?? 'unknown';

                return Card(
                  color: theme.colorScheme.surfaceContainerHigh,
                  elevation: 0,
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        applicantName.isNotEmpty ? applicantName[0].toUpperCase() : '?', 
                        style: TextStyle(color: theme.colorScheme.onPrimaryContainer)
                      ),
                    ),
                    title: Text(applicantName, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Status: $status'),
                    trailing: (status == 'pending') 
                      ? Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            // --- 🔥 ВОТ ИСПРАВЛЕНИЕ ИКОНОК ---
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.blue), // <-- ИСПРАВЛЕНО
                              tooltip: 'Approve',
                              onPressed: () => _updateApplicantStatus(applicantUid, applicantName, 'approved')
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red), // <-- ИСПРАВЛЕНО
                              tooltip: 'Reject',
                              onPressed: () => _updateApplicantStatus(applicantUid, applicantName, 'rejected')
                            ), 
                          ]
                        ) 
                      : null,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
  
  // --- КНОПКА "УЧАСТВОВАТЬ" ---
  Widget _buildApplyButton(ThemeData theme) {
    if (_currentUser == null) return SizedBox.shrink();
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('applicants')
          .doc(_currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final status = data?['status'] ?? 'unknown';
          
          if (status == 'pending') {
            return FilledButton.tonal(
              onPressed: null, 
              child: Text('Application Sent (Pending)')
            );
          }
          if (status == 'approved') {
            return FilledButton(
              onPressed: null, 
              style: FilledButton.styleFrom(backgroundColor: Colors.green[800]), 
              child: Text('You are Approved!')
            );
          }
          if (status == 'rejected') {
            return FilledButton.tonal(
              onPressed: null, 
              style: FilledButton.styleFrom(backgroundColor: Colors.red[100]), 
              child: Text('Application Rejected')
            );
          }
        }
        
        return FilledButton.icon(
          onPressed: _applyToPost, 
          icon: Icon(Icons.check), 
          label: Text('I want to participate!'), 
          style: FilledButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24))
        );
      },
    );
  }

  // --- СПИСОК КОММЕНТАРИЕВ ---
  Widget _buildCommentsList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discussion', style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .collection('comments')
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0), 
                child: Text('No comments yet.')
              );
            }
            
            return ListView.builder(
              shrinkWrap: true, 
              physics: NeverScrollableScrollPhysics(), 
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final authorName = data['userName'] ?? 'Anonymous';
                final commentId = doc.id;
                final authorUid = data['authorUid'] ?? '';
                final commentText = data['text'] ?? '';
                final Timestamp? timestamp = data['createdAt'];
                final String formattedDate = timestamp != null
                    ? DateFormat('HH:mm, MMM d, y').format(timestamp.toDate())
                    : '...';

                final bool canDelete = _isAdmin || (authorUid == _currentUserId);

                return Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainer,
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.surfaceContainerHigh, 
                      child: Text(
                        authorName.isNotEmpty ? authorName[0].toUpperCase() : '?', 
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant)
                      )
                    ),
                    title: Text(authorName, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(commentText),
                        SizedBox(height: 4),
                        Text(formattedDate, style: theme.textTheme.bodySmall),
                      ],
                    ),
                    trailing: canDelete
                      ? PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 20),
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
                                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : null,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
  
  // --- Поле Ввода Комментария (приклеено к низу) ---
  Widget _buildCommentInput(ThemeData theme, String commentPolicy, bool isAuthor) {
    bool canComment = false;
    if (commentPolicy == CommentVisibility.all.name || isAuthor) {
      canComment = true;
    }
    
    if (_currentUser == null) {
      canComment = false;
    }

    if (commentPolicy == CommentVisibility.approvedOnly.name && !isAuthor && _currentUser != null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('applicants').doc(_currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return SizedBox.shrink();
          }
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final status = data?['status'] ?? 'unknown';
          
          if (status == 'approved') {
            return _buildCommentTextField(theme);
          }
          return SizedBox.shrink();
        }
      );
    }

    return canComment ? _buildCommentTextField(theme) : SizedBox.shrink();
  }

  // (Вспомогательный виджет для _buildCommentInput)
  Widget _buildCommentTextField(ThemeData theme) {
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
                hintText: 'Add a comment...',
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
            onPressed: _postComment,
            child: Icon(Icons.send),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }

  // --- КНОПКА "ЛАЙК" ---
  Widget _buildLikeButton() {
    if (_currentUser == null) {
      return IconButton(
        iconSize: 28,
        icon: Icon(
          Icons.favorite_border,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onPressed: null,
      );
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('likes')
          .doc(_currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final isLiked = snapshot.hasData && snapshot.data!.exists;
        return IconButton(
          iconSize: 28,
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: _toggleLike,
        );
      },
    );
  }

  // --- КНОПКА "ЗАКЛАДКА" ---
  Widget _buildBookmarkButton() {
    if (_currentUser == null) {
      return IconButton(
        iconSize: 28,
        icon: Icon(
          Icons.bookmark_border,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onPressed: null,
      );
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        bool isBookmarked = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final bookmarks = List<String>.from(userData?['bookmarkedPosts'] ?? []);
          isBookmarked = bookmarks.contains(widget.postId);
        }
        return IconButton(
          iconSize: 28,
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isBookmarked ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: _toggleBookmark,
        );
      },
    );
  }

  // --- Шапка поста ---
  Widget _buildPostHeader(ThemeData theme, Map<String, dynamic> data) {
    final Timestamp? timestamp = data['createdAt'];
    final String formattedDate = timestamp != null
        ? DateFormat('MMM d, y, HH:mm', 'en_US').format(timestamp.toDate()) // <-- Исправлено на 'en_US'
        : '...';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['title'] ?? 'No Title',
          style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => UserProfilePage(userId: _postAuthorUid)),
            );
          },
          child: Text(
            'By: $_postAuthorName on $formattedDate',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline
            ),
          ),
        ),
      ],
    );
  }
}