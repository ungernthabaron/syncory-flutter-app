import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'post_detail_page.dart'; // Для "мини-карточки"

class UserProfilePage extends StatefulWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // У нас только 2 вкладки: "Интересы" и "Посты"
    _tabController = TabController(length: 2, vsync: this); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User profile', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      ),
      body: Center( 
        child: ConstrainedBox( 
          constraints: BoxConstraints(maxWidth: 900),
          // Мы используем StreamBuilder, чтобы читать данные этого юзера
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId) // <-- Читаем ID из виджета
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text('Пользователь не найден.'));
              }
              
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final categories = List<String>.from(data['categories'] ?? []);
              final displayName = data['displayName'] ?? 'Без имени';
              final photoUrl = data['photoUrl'];

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
                    // --- ВКЛАДКА 1: ИНТЕРЕСЫ ---
                    _buildInterestsTab(categories),
                    
                    // --- ВКЛАДКА 2: ПОСТЫ ЭТОГО ЮЗЕРА ---
                    _buildMyPostsTab(widget.userId),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- ВИДЖЕТЫ ДЛЯ ВКЛАДОК ---

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
            ? [Text('The user has no categories.')]
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
  // ВКЛАДКА 2: ПОСТЫ
  Widget _buildMyPostsTab(String uid) {
    return FutureBuilder<QuerySnapshot>(
      // 1. Запрос .get() (один раз)
      future: FirebaseFirestore.instance
          .collection('posts')
          .where('author_uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('The user hasn’t created any posts yet.'));
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

  // ОБЩАЯ "МИНИ-КАРТОЧКА"
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

// Вспомогательный класс, чтобы "приклеить" TabBar
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