import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_users_page.dart';
import 'admin_posts_page.dart';
import 'edit_profile_page.dart';
import 'post_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isAdmin = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); 
    _checkUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    if (currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        if (mounted) {
          setState(() { _isAdmin = true; });
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Me',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EditProfilePage()),
              );
            },
          ),
          if (_isAdmin)
            IconButton(
              icon: Icon(Icons.article_outlined),
              tooltip: 'Управление Постами',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AdminPostsPage()),
                );
              },
            ),
          if (_isAdmin)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              tooltip: 'Управление Пользователями',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AdminUsersPage()),
                );
              },
            ),
        ],
      ),
      
      body: Center( 
        child: ConstrainedBox( 
          constraints: BoxConstraints(maxWidth: 900),
          // Используем StreamBuilder ТОЛЬКО для данных профиля (шапки)
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                FirebaseAuth.instance.signOut();
                return Center(child: Text('Ошибка загрузки профиля.'));
              }
              
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final categories = List<String>.from(data['categories'] ?? []);
              final displayName = data['displayName'] ?? 'Без имени';
              final photoUrl = data['photoUrl'];
              final List<String> bookmarkIds = List<String>.from(data['bookmarkedPosts'] ?? []);

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    // --- "ШАПКА" ПРОФИЛЯ ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: photoUrl == null 
                                ? Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: GoogleFonts.montserrat(fontSize: 40, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer),
                                  )
                                : null,
                            ),
                            SizedBox(height: 16),
                            Text(
                              displayName,
                              style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              data['bio'] ?? 'Empty',
                              style: GoogleFonts.roboto(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: Icon(Icons.logout),
                              label: Text('Sign-Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                FirebaseAuth.instance.signOut();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // --- ПЕРЕКЛЮЧАТЕЛЬ ВКЛАДОK (TabBar) ---
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(icon: Icon(Icons.lightbulb_outline), text: "Categories"),
                            Tab(icon: Icon(Icons.article_outlined), text: "Posts"),
                            Tab(icon: Icon(Icons.bookmark_border), text: "Bookmarks"),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                // --- КОНТЕНТ ВКЛАДОК (TabBarView) ---
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInterestsTab(categories),
                    _buildMyPostsTab(currentUser!.uid),
                    _buildBookmarksTab(bookmarkIds),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- ВИДЖЕТЫ ДЛЯ КАЖДОЙ ВКЛАДКИ ---

  // ВКЛАДКА 1: ИНТЕРЕСЫ
  Widget _buildInterestsTab(List<String> categories) {
    // ... (Этот код без изменений)
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        alignment: WrapAlignment.center,
        children: categories.isEmpty
            ? [Text('You don’t have any categories yet.')]
            : categories.map((category) {
                return Chip(
                  label: Text(category),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                );
              }).toList(),
      ),
    );
  }

  // --- 🔥 ИЗМЕНЕНИЕ: StreamBuilder -> FutureBuilder ---
  // ВКЛАДКА 2: МОИ ПОСТЫ
  Widget _buildMyPostsTab(String uid) {
    return FutureBuilder<QuerySnapshot>(
      // 1. Запрос .get() (один раз)
      future: FirebaseFirestore.instance
          .collection('posts')
          .where('author_uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get(),
      builder: (context, snapshot) {
        // 2. Убираем проверку 'ConnectionState.waiting'
        // (FutureBuilder делает это сам)
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('You haven’t created any posts yet.'));
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildMiniPostCard(doc.id, data['title'], data['description']);
          },
        );
      },
    );
  }

  // --- 🔥 ИЗМЕНЕНИЕ: StreamBuilder -> FutureBuilder ---
  // ВКЛАДКА 3: ЗАКЛАДКИ
  Widget _buildBookmarksTab(List<String> bookmarkIds) {
    if (bookmarkIds.isEmpty) {
      return Center(child: Text('You have no saved posts.'));
    }
    
    return FutureBuilder<QuerySnapshot>(
      // 1. Запрос .get() (один раз)
      future: FirebaseFirestore.instance
          .collection('posts')
          .where(FieldPath.documentId, whereIn: bookmarkIds)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Saved posts not found (they may have been deleted).'));
        }
        
        // 2. 🔥 ВАЖНО: Фильтруем вручную, так как .get() не гарантирует порядок
        final allBookmarkedPosts = snapshot.data!.docs;
        // Сортируем так, чтобы последние добавленные были вверху
        allBookmarkedPosts.sort((a, b) {
          int indexA = bookmarkIds.indexOf(a.id);
          int indexB = bookmarkIds.indexOf(b.id);
          return indexB.compareTo(indexA); // Сортировка по убыванию индекса
        });

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: allBookmarkedPosts.length,
          itemBuilder: (context, index) {
            final doc = allBookmarkedPosts[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildMiniPostCard(doc.id, data['title'], data['description']);
          },
        );
      },
    );
  }

  // --- ОБЩАЯ "МИНИ-КАРТОЧКА" (без изменений) ---
  Widget _buildMiniPostCard(String postId, String title, String description) {
    // ... (Этот код без изменений)
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        subtitle: Text(description, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => PostDetailPage(postId: postId)),
          );
        },
      ),
    );
  }
}

// --- Вспомогательный класс (без изменений) ---
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}