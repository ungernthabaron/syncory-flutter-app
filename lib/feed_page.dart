import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String? _selectedCategory;
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      body: Row(
        children: [
          
          // --- ЛЕВАЯ КОЛОНКА (КАТЕГОРИИ) ---
          if (MediaQuery.of(context).size.width > 900)
            Container(
              width: 250,
              color: theme.colorScheme.surfaceContainerLowest, 
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 24.0),
                    child: Text(
                      'Synq',
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'Category',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildCategoryList(),
                  ),
                ],
              ),
            ),
          
          // --- ЦЕНТРАЛЬНАЯ КОЛОНКА (ЛЕНТА) ---
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Padding(
                      padding: const EdgeInsets.only(left: 24.0, top: 24.0, bottom: 16.0),
                      child: Text(
                        _selectedCategory ?? 'Feed', // Заголовок меняется
                        style: GoogleFonts.montserrat(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Find',
                          hintText: 'Text...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _buildPostsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Ошибка: ${snapshot.error}'));
                          }
                          
                          final List<QueryDocumentSnapshot> allDocs = snapshot.data?.docs ?? [];
                          
                          final List<QueryDocumentSnapshot> filteredDocs;
                          if (_searchQuery.isEmpty) {
                            filteredDocs = allDocs;
                          } else {
                            final query = _searchQuery.toLowerCase();
                            filteredDocs = allDocs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final title = (data['title'] ?? '').toLowerCase();
                              final description = (data['description'] ?? '').toLowerCase();
                              return title.contains(query) || description.contains(query);
                            }).toList();
                          }
                          
                          if (filteredDocs.isEmpty) {
                            return _buildEmptyState(theme, isSearchActive: _searchQuery.isNotEmpty);
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              return _buildPostCard(theme, doc);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CreatePostPage()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  // --- Виджет Карточки (без изменений) ---
  Widget _buildPostCard(ThemeData theme, QueryDocumentSnapshot doc) {
    // ... (код этого виджета остается без изменений)
    final data = doc.data() as Map<String, dynamic>;
    final String authorName = data['author_name'] ?? 'Аноним';
    String initials = '?';
    if (authorName.isNotEmpty) {
      initials = authorName[0].toUpperCase();
    }
    
    final Timestamp? timestamp = data['createdAt'];
    final String formattedDate = timestamp != null
        ? DateFormat('d MMMM y, HH:mm', 'ru_RU').format(timestamp.toDate())
        : '...';

    final categories = List<String>.from(data['categories'] ?? []);
    final postId = doc.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailPage(postId: postId),
            ),
          );
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent, 
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHigh,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    authorName,
                    style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(formattedDate),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Без заголовка',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      data['description'] ?? '...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
      .animate()
      .fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOut)
      .slideY(begin: 0.2, end: 0)
    );
  }

  // --- Виджет "Пусто" (без Lottie) ---
  Widget _buildEmptyState(ThemeData theme, {bool isSearchActive = false}) {
    // ... (код этого виджета остается без изменений)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearchActive ? Icons.search_off : Icons.inbox_outlined,
            size: 100,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(height: 20),
          Text(
            isSearchActive ? 'Nothing' : 'Empty',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isSearchActive
                ? 'Try a different search query.'
                : 'Be the first to create a suggestion!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  // --- 🔥 ВОТ ИЗМЕНЕНИЕ ---
  // --- Виджет списка категорий ---
  Widget _buildCategoryList() {
    final theme = Theme.of(context);
    // 1. Проверяем, выбрано ли "Все" (когда _selectedCategory = null)
    final bool isAllSelected = _selectedCategory == null;

    // 2. Оборачиваем в Column
    return Column(
      children: [
        // --- 3. Наша "статичная" кнопка "Все категории" ---
        ListTile(
          title: Text(
            'all',
            style: GoogleFonts.roboto(
              fontWeight: isAllSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isAllSelected,
          selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onTap: () {
            // 4. При нажатии, "очищаем" фильтр
            setState(() {
              _selectedCategory = null;
            });
          },
        ),
        Divider(height: 1, indent: 8, endIndent: 8),

        // --- 5. Наш "динамичный" список ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('all_categories')
                .orderBy('name_lowercase')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('Empty'));
              }
              
              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final categoryName = (doc.data() as Map<String, dynamic>)['name_lowercase'];
                  final isSelected = categoryName == _selectedCategory;

                  return ListTile(
                    title: Text(
                      categoryName,
                      style: GoogleFonts.roboto(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCategory = categoryName;
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}